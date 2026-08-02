#define _GNU_SOURCE
#include <errno.h>
#include <fcntl.h>
#include <limits.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>

#ifdef __APPLE__
#include <sys/clonefile.h>
#endif

enum { EXISTS = 10, MISSING = 11, UNSAFE = 12, FAILURE = 20, MAX_FRAME = 4 * 1024 * 1024 };

static int safe_relative(const char *path) {
  const char *part = path;
  if (!path || !*path || path[0] == '/') return 0;
  while (*part) {
    const char *end = strchr(part, '/');
    size_t length = end ? (size_t)(end - part) : strlen(part);
    if (!length || (length == 1 && part[0] == '.') ||
        (length == 2 && part[0] == '.' && part[1] == '.')) return 0;
    if (!end) return 1;
    part = end + 1;
  }
  return 0;
}

static int root_fd(const char *declared) {
  char canonical[PATH_MAX];
  char *part;
  int fd;
  if (!realpath(declared, canonical) || canonical[0] != '/') return -1;
  fd = open("/", O_RDONLY | O_DIRECTORY | O_NOFOLLOW);
  if (fd < 0) return -1;
  part = canonical + 1;
  while (*part) {
    char *end = strchr(part, '/');
    int next;
    if (end) *end = '\0';
    next = openat(fd, part, O_RDONLY | O_DIRECTORY | O_NOFOLLOW);
    close(fd);
    if (next < 0) return -1;
    fd = next;
    if (!end) break;
    part = end + 1;
  }
  return fd;
}

static int parent_fd(int root, const char *relative, int create) {
  char copy[PATH_MAX];
  char *part, *end;
  int fd = dup(root);
  if (fd < 0 || strlen(relative) >= sizeof(copy)) return -1;
  strcpy(copy, relative);
  part = copy;
  while ((end = strchr(part, '/'))) {
    int next;
    *end = '\0';
    next = openat(fd, part, O_RDONLY | O_DIRECTORY | O_NOFOLLOW);
    if (next < 0 && create && errno == ENOENT) {
      if (mkdirat(fd, part, 0700) != 0 && errno != EEXIST) { close(fd); return -1; }
      next = openat(fd, part, O_RDONLY | O_DIRECTORY | O_NOFOLLOW);
    }
    close(fd);
    if (next < 0) return -1;
    fd = next;
    part = end + 1;
  }
  return fd;
}

static const char *leaf(const char *relative) {
  const char *last = strrchr(relative, '/');
  return last ? last + 1 : relative;
}

static int same_directory(int first, int second) {
  struct stat a, b;
  return fstat(first, &a) == 0 && fstat(second, &b) == 0 && a.st_dev == b.st_dev && a.st_ino == b.st_ino;
}

static int read_exact(int fd, void *buffer, size_t length) {
  size_t offset = 0;
  while (offset < length) {
    ssize_t count = read(fd, (char *)buffer + offset, length - offset);
    if (count <= 0) return -1;
    offset += (size_t)count;
  }
  return 0;
}

static int write_exact(int fd, const void *buffer, size_t length) {
  size_t offset = 0;
  while (offset < length) {
    ssize_t count = write(fd, (const char *)buffer + offset, length - offset);
    if (count <= 0) return -1;
    offset += (size_t)count;
  }
  return 0;
}

static int read_frame(unsigned char **bytes, size_t *length) {
  unsigned char header[8];
  uint64_t size = 0;
  int index;
  if (read_exact(STDIN_FILENO, header, sizeof(header)) != 0) return -1;
  for (index = 0; index < 8; index++) size = (size << 8) | header[index];
  if (size > MAX_FRAME) return -1;
  *bytes = malloc(size ? (size_t)size : 1);
  if (!*bytes || read_exact(STDIN_FILENO, *bytes, (size_t)size) != 0) { free(*bytes); return -1; }
  *length = (size_t)size;
  return 0;
}

static int barrier(const char *mode, const char *point) {
  char token[7];
  int enabled = (strcmp(mode, "both") == 0) || (strcmp(mode, point) == 0);
  if (!enabled) return 0;
  if (dprintf(STDOUT_FILENO, "%s_publish\n", point) < 0) return -1;
  if (read_exact(STDIN_FILENO, token, sizeof(token)) != 0) return -1;
  return memcmp(token, "resume\n", sizeof(token)) == 0 ? 0 : -1;
}

#ifdef __linux__
static int verify_proc_ref(int fd, char *reference, size_t size) {
  struct stat held, opened;
  int reference_fd;
  if (snprintf(reference, size, "/proc/self/fd/%d", fd) >= (int)size) return -1;
  reference_fd = open(reference, O_RDONLY | O_CLOEXEC);
  if (reference_fd < 0) return -1;
  if (fstat(fd, &held) != 0 || fstat(reference_fd, &opened) != 0 ||
      held.st_dev != opened.st_dev || held.st_ino != opened.st_ino) {
    close(reference_fd);
    return -1;
  }
  close(reference_fd);
  return 0;
}
#endif

static int write_file(const char *root_path, const char *relative, const char *mode) {
  unsigned char *bytes = NULL;
  unsigned char *readback = NULL;
  size_t length = 0;
  int root = -1, parent = -1, fresh = -1, file = -1, result = FAILURE;
#ifdef __APPLE__
  char private_leaf[64];
#endif
  if (!safe_relative(relative) || read_frame(&bytes, &length) != 0) goto cleanup;
  root = root_fd(root_path);
  if (root < 0) { result = UNSAFE; goto cleanup; }
  parent = parent_fd(root, relative, 1);
  if (parent < 0) { result = errno == ENOENT ? MISSING : UNSAFE; goto cleanup; }
  fresh = parent_fd(root, relative, 0);
  if (fresh < 0 || !same_directory(parent, fresh)) { result = UNSAFE; goto cleanup; }
  close(fresh); fresh = -1;
#ifdef __linux__
  file = openat(parent, ".", O_TMPFILE | O_RDWR | O_CLOEXEC, 0600);
  if (file < 0) goto cleanup;
#elif defined(__APPLE__)
  /* Darwin's private source leaf is unlinked before caller bytes or barriers. */
  if (snprintf(private_leaf, sizeof(private_leaf), ".crosswake-proof-lane-private-%ld", (long)getpid()) >= (int)sizeof(private_leaf)) goto cleanup;
  file = openat(parent, private_leaf, O_RDWR | O_CREAT | O_EXCL | O_NOFOLLOW, 0600);
  if (file < 0) goto cleanup;
  if (unlinkat(parent, private_leaf, 0) != 0) goto cleanup;
#else
  goto cleanup;
#endif
  if (write_exact(file, bytes, length) != 0 || fsync(file) != 0) goto cleanup;
  readback = malloc(length ? length : 1);
  if (!readback || lseek(file, 0, SEEK_SET) < 0 || read_exact(file, readback, length) != 0 || memcmp(bytes, readback, length) != 0) goto cleanup;
  if (barrier(mode, "before") != 0) goto cleanup;
  fresh = parent_fd(root, relative, 0);
  if (fresh < 0 || !same_directory(parent, fresh)) { result = UNSAFE; goto cleanup; }
  close(fresh); fresh = -1;
#ifdef __linux__
  char reference[64];
  if (verify_proc_ref(file, reference, sizeof(reference)) != 0) goto cleanup;
  if (linkat(AT_FDCWD, reference, parent, leaf(relative), AT_SYMLINK_FOLLOW) != 0) {
    result = errno == EEXIST ? EXISTS : FAILURE;
    goto cleanup;
  }
#elif defined(__APPLE__)
  if (fclonefileat(file, parent, leaf(relative), 0) != 0) {
    result = errno == EEXIST ? EXISTS : FAILURE;
    goto cleanup;
  }
#endif
  if (barrier(mode, "after") != 0) goto cleanup;
  result = 0;
cleanup:
  if (fresh >= 0) close(fresh);
  if (file >= 0) close(file);
  if (parent >= 0) close(parent);
  if (root >= 0) close(root);
  free(readback);
  free(bytes);
  return result;
}

static int read_file(const char *root_path, const char *relative, int emit) {
  char buffer[8192];
  int root, parent, file;
  struct stat statbuf;
  ssize_t count = 0;
  if (!safe_relative(relative)) return UNSAFE;
  root = root_fd(root_path);
  if (root < 0) return UNSAFE;
  parent = parent_fd(root, relative, 0);
  if (parent < 0) { int code = errno == ENOENT ? MISSING : UNSAFE; close(root); return code; }
  file = openat(parent, leaf(relative), O_RDONLY | O_NOFOLLOW);
  close(parent); close(root);
  if (file < 0) return errno == ENOENT ? MISSING : UNSAFE;
  if (fstat(file, &statbuf) != 0 || !S_ISREG(statbuf.st_mode)) { close(file); return UNSAFE; }
  if (emit) while ((count = read(file, buffer, sizeof(buffer))) > 0) if (write_exact(STDOUT_FILENO, buffer, (size_t)count) != 0) { close(file); return FAILURE; }
  close(file);
  return count < 0 ? FAILURE : 0;
}

int main(int argc, char **argv) {
  if (argc == 5 && strcmp(argv[1], "write") == 0) return write_file(argv[2], argv[3], argv[4]);
  if (argc != 4) return FAILURE;
  if (strcmp(argv[1], "read") == 0) return read_file(argv[2], argv[3], 1);
  if (strcmp(argv[1], "regular") == 0) return read_file(argv[2], argv[3], 0);
  return FAILURE;
}
