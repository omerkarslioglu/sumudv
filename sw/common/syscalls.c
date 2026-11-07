#include <stddef.h>
#include <stdint.h>
#include "platform.h"

extern char __heap_start;
extern char __heap_end;
static char *heap_ptr;

void *_sbrk(int incr)
{
  if (!heap_ptr)
    heap_ptr = &__heap_start;
  char *prev = heap_ptr;
  if (heap_ptr + incr > &__heap_end)
    return (void *)-1;
  heap_ptr += incr;
  return prev;
}

int _write(int fd, const void *buf, size_t count)
{
  (void)fd;
  const char *p = (const char *)buf;
  for (size_t i = 0; i < count; i++)
    uart_putc(p[i]);
  return (int)count;
}

int _close(int fd) { (void)fd; return -1; }
int _fstat(int fd, void *st) { (void)fd; (void)st; return -1; }
int _isatty(int fd) { (void)fd; return 1; }
int _lseek(int fd, int off, int wh) { (void)fd; (void)off; (void)wh; return 0; }
int _read(int fd, void *buf, size_t n) { (void)fd; (void)buf; (void)n; return 0; }
void _exit(int code) { TOHOST = (uint32_t)code; for (;;) ; }

int mkdir(const char *path, int mode)
{
  (void)path;
  (void)mode;
  return 0;
}

/* Weak stubs some doom paths touch */
int _open(const char *p, int f, ...) { (void)p; (void)f; return -1; }
int _unlink(const char *p) { (void)p; return -1; }
int _stat(const char *p, void *s) { (void)p; (void)s; return -1; }
int _kill(int p, int s) { (void)p; (void)s; return -1; }
int _getpid(void) { return 1; }

