#define _POSIX_C_SOURCE 200809L
#if defined(__APPLE__)
#define _DARWIN_C_SOURCE
#endif
#include <errno.h>
#include <fcntl.h>
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

#if defined(__APPLE__)
#include <sys/attr.h>
#endif
#endif

#define MAX_EVIDENCE 65536U
#define DIGEST_SIZE 64U

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

static int matches_file(const char *path, const unsigned char *expected, size_t expected_size) {
  struct stat st;
  unsigned char buffer[4096];
  size_t used = 0;
  int fd = open(path, O_RDONLY | O_NOFOLLOW);
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
  close(fd);
  return 0;
}

static int rename_noreplace(const char *from, const char *to) {
#if defined(__linux__)
  return syscall(SYS_renameat2, AT_FDCWD, from, AT_FDCWD, to, RENAME_NOREPLACE);
#elif defined(__APPLE__)
  return renameatx_np(AT_FDCWD, from, AT_FDCWD, to, RENAME_EXCL);
#else
  (void)from;
  (void)to;
  errno = ENOTSUP;
  return -1;
#endif
}

int main(int argc, char **argv) {
  unsigned char header[4], digest[DIGEST_SIZE];
  uint32_t size;
  unsigned char bytes[MAX_EVIDENCE];
  char artifact[4096], pending[4096], complete[4096];
  int artifact_fd, marker_fd, dir_fd;

  if (argc != 2 || read_all(STDIN_FILENO, header, sizeof(header)) != 0) return 20;
  size = ((uint32_t)header[0] << 24) | ((uint32_t)header[1] << 16) | ((uint32_t)header[2] << 8) | header[3];
  if (size > MAX_EVIDENCE || read_all(STDIN_FILENO, digest, sizeof(digest)) != 0 || read_all(STDIN_FILENO, bytes, size) != 0) return 20;
  for (size_t i = 0; i < DIGEST_SIZE; ++i) if (!((digest[i] >= '0' && digest[i] <= '9') || (digest[i] >= 'a' && digest[i] <= 'f'))) return 20;

  if (mkdir(argv[1], 0700) != 0) return (errno == EEXIST) ? 10 : 20;
  if (snprintf(artifact, sizeof(artifact), "%s/proof-lane-evidence.json", argv[1]) >= (int)sizeof(artifact) ||
      snprintf(pending, sizeof(pending), "%s/.complete.pending", argv[1]) >= (int)sizeof(pending) ||
      snprintf(complete, sizeof(complete), "%s/.complete", argv[1]) >= (int)sizeof(complete)) return 20;

  artifact_fd = open(artifact, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW, 0600);
  if (artifact_fd < 0 || write_all(artifact_fd, bytes, size) != 0 || fsync(artifact_fd) != 0 || fchmod(artifact_fd, 0400) != 0) {
    if (artifact_fd >= 0) close(artifact_fd);
    return 20;
  }
  close(artifact_fd);
  if (matches_file(artifact, bytes, size) != 0) return 20;

  marker_fd = open(pending, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW, 0600);
  if (marker_fd < 0 || write_all(marker_fd, digest, DIGEST_SIZE) != 0 || fsync(marker_fd) != 0 || fchmod(marker_fd, 0400) != 0) {
    if (marker_fd >= 0) close(marker_fd);
    return 20;
  }
  close(marker_fd);
  if (rename_noreplace(pending, complete) != 0) return (errno == EEXIST) ? 10 : 20;
  dir_fd = open(argv[1], O_RDONLY | O_DIRECTORY | O_NOFOLLOW);
  if (dir_fd < 0 || fsync(dir_fd) != 0) { if (dir_fd >= 0) close(dir_fd); return 20; }
  close(dir_fd);
  if (matches_file(artifact, bytes, size) != 0) return 20;
  return 0;
}
