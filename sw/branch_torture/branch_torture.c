/* SUMUD-V micro-bench: predictable vs unpredictable branches.
 * Measures BP quality via mcycle/minstret (IPC) once CSR counters exist.
 */

#define TOHOST    (*(volatile unsigned int *)0x80001000u)
#define MCYCLE    ({ unsigned int __v; __asm__ volatile ("csrr %0, mcycle" : "=r"(__v)); __v; })
#define MINSTRET  ({ unsigned int __v; __asm__ volatile ("csrr %0, minstret" : "=r"(__v)); __v; })

static unsigned int lfsr = 0xACE1u;

static unsigned int next_bit(void)
{
  unsigned int bit = ((lfsr >> 0) ^ (lfsr >> 2) ^ (lfsr >> 3) ^ (lfsr >> 5)) & 1u;
  lfsr = (lfsr >> 1) | (bit << 15);
  return bit;
}

static unsigned int predictable(unsigned int n)
{
  unsigned int i, acc = 0;
  for (i = 0; i < n; i++) {
    if ((i & 1u) == 0u)
      acc += i;
    else
      acc -= i;
  }
  return acc;
}

static unsigned int unpredictable(unsigned int n)
{
  unsigned int i, acc = 0;
  for (i = 0; i < n; i++) {
    if (next_bit())
      acc += i;
    else
      acc ^= i;
  }
  return acc;
}

int main(void)
{
  unsigned int t0, t1, i0, i1, sink;
  unsigned int n = 8192;

  t0 = MCYCLE; i0 = MINSTRET;
  sink = predictable(n);
  t1 = MCYCLE; i1 = MINSTRET;
  TOHOST = t1 - t0;
  TOHOST = i1 - i0;

  t0 = MCYCLE; i0 = MINSTRET;
  sink ^= unpredictable(n);
  t1 = MCYCLE; i1 = MINSTRET;
  TOHOST = t1 - t0;
  TOHOST = i1 - i0;
  TOHOST = sink;
  TOHOST = 1;

  for (;;)
    ;
  return 0;
}
