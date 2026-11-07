/* SUMUD-V micro-bench: pointer-chase / stride memory latency.
 * Bare-metal style; compile later with riscv32-unknown-elf-gcc.
 */

#define TOHOST   (*(volatile unsigned int *)0x80001000u)
#define MCYCLE   ({ unsigned int __v; __asm__ volatile ("csrr %0, mcycle" : "=r"(__v)); __v; })

#define N_NODES  1024
#define STRIDE   16

static unsigned int nodes[N_NODES];

static void init_chase(void)
{
  unsigned int i;
  for (i = 0; i < N_NODES; i++)
    nodes[i] = (i + STRIDE) % N_NODES;
}

static unsigned int chase(unsigned int iters)
{
  unsigned int idx = 0;
  unsigned int i;
  for (i = 0; i < iters; i++)
    idx = nodes[idx];
  return idx;
}

int main(void)
{
  unsigned int t0, t1, sink;
  unsigned int iters = 4096;

  init_chase();
  t0 = MCYCLE;
  sink = chase(iters);
  t1 = MCYCLE;

  /* avg cycles/access roughly (t1-t0)/iters — dump via tohost for now */
  TOHOST = (t1 - t0);
  TOHOST = sink;
  TOHOST = 1; /* exit */

  for (;;)
    ;
  return 0;
}
