/* SUMUD-V micro-bench: multiply-heavy loop for M-extension gain.
 * Compare cycles with -march=rv32im vs soft-mul baseline (rv32i).
 */

#define TOHOST   (*(volatile unsigned int *)0x80001000u)
#define MCYCLE   ({ unsigned int __v; __asm__ volatile ("csrr %0, mcycle" : "=r"(__v)); __v; })

static unsigned int mul_chain(unsigned int n)
{
  unsigned int a = 1u, b = 3u, i;
  for (i = 0; i < n; i++) {
    a = a * b + 0x9e3779b9u;
    b = b * a + i;
  }
  return a ^ b;
}

int main(void)
{
  unsigned int t0, t1, sink;
  unsigned int n = 16384;

  t0 = MCYCLE;
  sink = mul_chain(n);
  t1 = MCYCLE;

  TOHOST = t1 - t0;
  TOHOST = sink;
  TOHOST = 1;

  for (;;)
    ;
  return 0;
}
