#define _POSIX_C_SOURCE 200809L
#if defined(__APPLE__)
#define _DARWIN_C_SOURCE
#endif
#include <errno.h>
#include <fcntl.h>
#include <limits.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

#if defined(__linux__)
#include <sys/syscall.h>
#ifndef RENAME_NOREPLACE
#define RENAME_NOREPLACE (1 << 0)
#endif
#endif

#define MAX_EVIDENCE 65536U
#define DIGEST_SIZE 64U
#define ARTIFACT_NAME "proof-lane-evidence.json"
#define PENDING_NAME ".complete.pending"
#define COMPLETE_NAME ".complete"

static int read_all(int fd, unsigned char *buf, size_t size) {
  size_t used = 0;
  while (used < size) {
    ssize_t read_count = read(fd, buf + used, size - used);
    if (read_count <= 0) return -1;
    used += (size_t)read_count;
  }
  return 0;
}

static int write_all(int fd, const unsigned char *buf, size_t size) {
  size_t used = 0;
  while (used < size) {
    ssize_t written = write(fd, buf + used, size - used);
    if (written <= 0) return -1;
    used += (size_t)written;
  }
  return 0;
}

static int split_destination(const char *destination, char *parent, size_t parent_size,
                             char *basename, size_t basename_size) {
  const char *slash;
  size_t parent_length, basename_length;

  if (destination == NULL || destination[0] == '\0') return -1;
  slash = strrchr(destination, '/');
  if (slash == NULL) {
    parent_length = 1;
    basename_length = strlen(destination);
    if (parent_size < 2) return -1;
    memcpy(parent, ".", 2);
  } else {
    basename_length = strlen(slash + 1);
    parent_length = (slash == destination) ? 1 : (size_t)(slash - destination);
    if (parent_length + 1 > parent_size) return -1;
    if (slash == destination) {
      memcpy(parent, "/", 2);
    } else {
      memcpy(parent, destination, parent_length);
      parent[parent_length] = '\0';
    }
  }

  if (basename_length == 0 || basename_length >= basename_size ||
      (basename_length == 1 && slash != NULL && slash[1] == '.') ||
      (basename_length == 2 && slash != NULL && slash[1] == '.' && slash[2] == '.')) return -1;
  memcpy(basename, slash == NULL ? destination : slash + 1, basename_length);
  basename[basename_length] = '\0';
  return 0;
}

static int matches_file_at(int directory_fd, const char *name, const unsigned char *expected,
                           size_t expected_size) {
  struct stat st;
  unsigned char buffer[4096];
  size_t used = 0;
  int fd = openat(directory_fd, name, O_RDONLY | O_NOFOLLOW | O_CLOEXEC);
  if (fd < 0 || fstat(fd, &st) != 0 || !S_ISREG(st.st_mode) || (size_t)st.st_size != expected_size) {
    if (fd >= 0) close(fd);
    return -1;
  }
  while (used < expected_size) {
    size_t wanted = expected_size - used;
    if (wanted > sizeof(buffer)) wanted = sizeof(buffer);
    if (read_all(fd, buffer, wanted) != 0 || memcmp(buffer, expected + used, wanted) != 0) {
      close(fd);
      return -1;
    }
    used += wanted;
  }
  return close(fd) == 0 ? 0 : -1;
}

static int rename_noreplace_at(int directory_fd, const char *from, const char *to) {
#if defined(__linux__)
  return syscall(SYS_renameat2, directory_fd, from, directory_fd, to, RENAME_NOREPLACE);
#elif defined(__APPLE__)
  return renameatx_np(directory_fd, from, directory_fd, to, RENAME_EXCL);
#else
  (void)directory_fd;
  (void)from;
  (void)to;
  errno = ENOTSUP;
  return -1;
#endif
}

#ifdef CROSSWAKE_EVIDENCE_TEST_BARRIER
static int wait_for_test_release(const char *ready_path, const char *release_path) {
  int ready_fd;
  unsigned int attempts;
  const unsigned char ready[] = "ready";

  if (ready_path == NULL || release_path == NULL) return -1;
  ready_fd = open(ready_path, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC, 0600);
  if (ready_fd < 0 || write_all(ready_fd, ready, sizeof(ready) - 1) != 0 || fsync(ready_fd) != 0 || close(ready_fd) != 0) {
    if (ready_fd >= 0) close(ready_fd);
    return -1;
  }
  for (attempts = 0; attempts < 500; ++attempts) {
    if (access(release_path, F_OK) == 0) return 0;
    usleep(10000);
  }
  return -1;
}
#endif

int main(int argc, char **argv) {
  unsigned char header[4], digest[DIGEST_SIZE];
  uint32_t size;
  unsigned char bytes[MAX_EVIDENCE];
  char parent[PATH_MAX], basename[NAME_MAX + 1];
  int artifact_fd = -1, marker_fd = -1, parent_fd = -1, destination_fd = -1;
  int reserved = 0, artifact_created = 0, pending_created = 0, result = 20;

#ifdef CROSSWAKE_EVIDENCE_TEST_BARRIER
  if (argc != 4) return 20;
#else
  if (argc != 2) return 20;
#endif
  if (read_all(STDIN_FILENO, header, sizeof(header)) != 0) return 20;
  size = ((uint32_t)header[0] << 24) | ((uint32_t)header[1] << 16) | ((uint32_t)header[2] << 8) | header[3];
  if (size > MAX_EVIDENCE || read_all(STDIN_FILENO, digest, sizeof(digest)) != 0 || read_all(STDIN_FILENO, bytes, size) != 0) return 20;
  for (size_t i = 0; i < DIGEST_SIZE; ++i) if (!((digest[i] >= '0' && digest[i] <= '9') || (digest[i] >= 'a' && digest[i] <= 'f'))) return 20;
  if (split_destination(argv[1], parent, sizeof(parent), basename, sizeof(basename)) != 0) return 20;

  parent_fd = open(parent, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC);
  if (parent_fd < 0) goto cleanup;
  if (mkdirat(parent_fd, basename, 0700) != 0) {
    result = (errno == EEXIST) ? 10 : 20;
    goto cleanup;
  }
  reserved = 1;
  destination_fd = openat(parent_fd, basename, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC);
  if (destination_fd < 0) goto cleanup;

#ifdef CROSSWAKE_EVIDENCE_TEST_BARRIER
  if (wait_for_test_release(argv[2], argv[3]) != 0) goto cleanup;
#endif

  artifact_fd = openat(destination_fd, ARTIFACT_NAME, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC, 0600);
  if (artifact_fd < 0) goto cleanup;
  artifact_created = 1;
  if (write_all(artifact_fd, bytes, size) != 0 || fchmod(artifact_fd, 0400) != 0 || fsync(artifact_fd) != 0 || close(artifact_fd) != 0) goto cleanup;
  artifact_fd = -1;
  if (matches_file_at(destination_fd, ARTIFACT_NAME, bytes, size) != 0) goto cleanup;

  marker_fd = openat(destination_fd, PENDING_NAME, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC, 0600);
  if (marker_fd < 0) goto cleanup;
  pending_created = 1;
  if (write_all(marker_fd, digest, DIGEST_SIZE) != 0 || fchmod(marker_fd, 0400) != 0 || fsync(marker_fd) != 0 || close(marker_fd) != 0) goto cleanup;
  marker_fd = -1;
  if (rename_noreplace_at(destination_fd, PENDING_NAME, COMPLETE_NAME) != 0) {
    result = (errno == EEXIST) ? 10 : 20;
    goto cleanup;
  }
  pending_created = 0;
  if (matches_file_at(destination_fd, ARTIFACT_NAME, bytes, size) != 0 || fsync(destination_fd) != 0 || fsync(parent_fd) != 0) goto cleanup;
  result = 0;

cleanup:
  if (artifact_fd >= 0) close(artifact_fd);
  if (marker_fd >= 0) close(marker_fd);
  if (reserved && destination_fd >= 0 && result != 0) {
    if (pending_created) unlinkat(destination_fd, PENDING_NAME, 0);
    if (artifact_created) unlinkat(destination_fd, ARTIFACT_NAME, 0);
    fsync(destination_fd);
  }
  if (destination_fd >= 0) close(destination_fd);
  if (parent_fd >= 0) close(parent_fd);
  return result;
}
