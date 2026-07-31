#include <errno.h>
#include <stdio.h>
#include <sys/stat.h>

#if defined(__linux__)
#include <fcntl.h>
#include <sys/syscall.h>
#include <unistd.h>
#ifndef RENAME_NOREPLACE
#define RENAME_NOREPLACE (1 << 0)
#endif
#elif defined(__APPLE__)
#include <fcntl.h>
#include <stdio.h>
#include <sys/attr.h>
#endif

int main(int argc, char **argv) {
  struct stat source;
  if (argc != 3 || stat(argv[1], &source) != 0 || !S_ISDIR(source.st_mode)) return 20;
#if defined(__linux__)
  if (syscall(SYS_renameat2, AT_FDCWD, argv[1], AT_FDCWD, argv[2], RENAME_NOREPLACE) == 0) return 0;
#elif defined(__APPLE__)
  if (renameatx_np(AT_FDCWD, argv[1], AT_FDCWD, argv[2], RENAME_EXCL) == 0) return 0;
#else
  return 20;
#endif
  if (errno == EEXIST || errno == ENOTEMPTY) return 10;
  if (errno == ENOSYS || errno == ENOTSUP || errno == EOPNOTSUPP || errno == EINVAL) return 20;
  return 20;
}
