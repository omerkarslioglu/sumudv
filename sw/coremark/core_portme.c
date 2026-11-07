/* Lightweight CoreMark-like matrix/list mix for scoring (not EEMBC CoreMark).
 * Official CoreMark can replace this directory; keep core_portme hooks.
 */
#include "platform.h"

#define N 32
#define ITERS 300

static int mat_a[N * N];
static int mat_b[N * N];
static int mat_c[N * N];

static unsigned list_crc;

static void mat_init(void)
{
  for (int i = 0; i < N * N; i++) {
    mat_a[i] = (i * 3 + 1) & 0xff;
    mat_b[i] = (i * 5 + 7) & 0xff;
  }
}

static void mat_mul(void)
{
  for (int i = 0; i < N; i++) {
    for (int j = 0; j < N; j++) {
      int s = 0;
      for (int k = 0; k < N; k++)
        s += mat_a[i * N + k] * mat_b[k * N + j];
      mat_c[i * N + j] = s;
    }
  }
}

static void list_work(void)
{
  unsigned x = 0x12345678u;
  for (int i = 0; i < 1024; i++) {
    x ^= (x << 13);
    x ^= (x >> 17);
    x ^= (x << 5);
    list_crc += x + (unsigned)mat_c[i & (N * N - 1)];
  }
}

int main(void)
{
  unsigned t0, t1;
  uart_puts("coremark-mini start\n");
  mat_init();
  t0 = rdcycle();
  for (int i = 0; i < ITERS; i++) {
    mat_mul();
    list_work();
  }
  t1 = rdcycle();
  unsigned cycles = t1 - t0;
  /* Fake CoreMark/MHz-ish: iterations*scale / cycles * MHz */
  unsigned score_x100 = cycles ? (unsigned)((unsigned long)ITERS * 5000ul * 100ul / cycles) : 0;
  uart_puts("coremark-mini done\n");
  TOHOST = (score_x100 << 16) | (list_crc & 0xffff);
  for (;;)
    ;
  return 0;
}
