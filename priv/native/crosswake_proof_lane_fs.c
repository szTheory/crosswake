#include <errno.h>
#include <fcntl.h>
#include <limits.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>

enum { EXISTS = 10, MISSING = 11, UNSAFE = 12, FAILURE = 20 };

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
      if (mkdirat(fd, part, 0700) != 0 && errno != EEXIST) {
        close(fd);
        return -1;
      }
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
  return fstat(first, &a) == 0 && fstat(second, &b) == 0 &&
         a.st_dev == b.st_dev && a.st_ino == b.st_ino;
}

static void test_hook(void) {
  const char *hook = getenv("CROSSWAKE_PROOF_LANE_FS_TEST_BEFORE_FINAL_OPEN");
  if (hook && *hook) {
    int fd = open(hook, O_WRONLY | O_CREAT | O_EXCL, 0600);
    if (fd >= 0) close(fd);
    usleep(50000);
  }
}

static int write_file(const char *root_path, const char *relative, const char *input_path) {
  char buffer[8192];
  int root, parent, fresh, file, input;
  struct stat input_stat;
  ssize_t read_count;
  if (!safe_relative(relative)) return UNSAFE;
  root = root_fd(root_path);
  if (root < 0) return UNSAFE;
  parent = parent_fd(root, relative, 1);
  if (parent < 0) { int code = errno == ENOENT ? MISSING : UNSAFE; close(root); return code; }
  test_hook();
  fresh = parent_fd(root, relative, 0);
  if (fresh < 0 || !same_directory(parent, fresh)) {
    if (fresh >= 0) close(fresh);
    close(parent); close(root); return UNSAFE;
  }
  close(fresh);
  input = open(input_path, O_RDONLY | O_NOFOLLOW);
  if (input < 0 || fstat(input, &input_stat) != 0 || !S_ISREG(input_stat.st_mode)) {
    if (input >= 0) close(input);
    close(parent); close(root); return FAILURE;
  }
  file = openat(parent, leaf(relative), O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW, 0600);
  if (file < 0) {
    int code = errno == EEXIST ? EXISTS : (errno == ELOOP || errno == ENOTDIR ? UNSAFE : FAILURE);
    close(input); close(parent); close(root); return code;
  }
  while ((read_count = read(input, buffer, sizeof(buffer))) > 0) {
    ssize_t written = 0;
    while (written < read_count) {
      ssize_t count = write(file, buffer + written, (size_t)(read_count - written));
      if (count <= 0) { close(input); close(file); close(parent); close(root); return FAILURE; }
      written += count;
    }
  }
  if (read_count < 0 || fsync(file) != 0) { close(input); close(file); close(parent); close(root); return FAILURE; }
  close(input); close(file); close(parent); close(root); return 0;
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
  if (emit) while ((count = read(file, buffer, sizeof(buffer))) > 0) {
    if (write(STDOUT_FILENO, buffer, (size_t)count) != count) { close(file); return FAILURE; }
  }
  close(file);
  return count < 0 ? FAILURE : 0;
}

static int publish_file(const char *root_path, const char *staging, const char *destination) {
  int root, stage_parent, destination_parent;
  if (!safe_relative(staging) || !safe_relative(destination)) return UNSAFE;
  root = root_fd(root_path);
  if (root < 0) return UNSAFE;
  stage_parent = parent_fd(root, staging, 0);
  destination_parent = parent_fd(root, destination, 0);
  if (stage_parent < 0 || destination_parent < 0) {
    if (stage_parent >= 0) close(stage_parent);
    if (destination_parent >= 0) close(destination_parent);
    close(root); return UNSAFE;
  }
  if (linkat(stage_parent, leaf(staging), destination_parent, leaf(destination), 0) != 0) {
    int code = errno == EEXIST ? EXISTS : (errno == ELOOP || errno == ENOTDIR ? UNSAFE : FAILURE);
    close(stage_parent); close(destination_parent); close(root); return code;
  }
  if (unlinkat(stage_parent, leaf(staging), 0) != 0) {
    close(stage_parent); close(destination_parent); close(root); return FAILURE;
  }
  close(stage_parent); close(destination_parent); close(root); return 0;
}

int main(int argc, char **argv) {
  if (argc == 5 && strcmp(argv[1], "write") == 0) return write_file(argv[2], argv[3], argv[4]);
  if (argc == 5 && strcmp(argv[1], "publish") == 0) return publish_file(argv[2], argv[3], argv[4]);
  if (argc != 4) return FAILURE;
  if (strcmp(argv[1], "read") == 0) return read_file(argv[2], argv[3], 1);
  if (strcmp(argv[1], "regular") == 0) return read_file(argv[2], argv[3], 0);
  return FAILURE;
}
