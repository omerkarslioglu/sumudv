/*
 * SUMUD-V CoreMark port: timebase = mcycle CSR.
 * Assume CPU_HZ for converting ticks→seconds (reporting only).
 * CoreMark/MHz = ITERATIONS * 1e6 / cycles  (frequency-independent).
 */
#include "coremark.h"
#include "core_portme.h"

#ifndef CPU_HZ
#define CPU_HZ 50000000u
#endif

#if VALIDATION_RUN
volatile ee_s32 seed1_volatile = 0x3415;
volatile ee_s32 seed2_volatile = 0x3415;
volatile ee_s32 seed3_volatile = 0x66;
#endif
#if PERFORMANCE_RUN
volatile ee_s32 seed1_volatile = 0x0;
volatile ee_s32 seed2_volatile = 0x0;
volatile ee_s32 seed3_volatile = 0x66;
#endif
#if PROFILE_RUN
volatile ee_s32 seed1_volatile = 0x8;
volatile ee_s32 seed2_volatile = 0x8;
volatile ee_s32 seed3_volatile = 0x8;
#endif
volatile ee_s32 seed4_volatile = ITERATIONS;
volatile ee_s32 seed5_volatile = 0;

/* Keep results in MMIO hole above code image (TB mirrors these into mem[]) */
#define TOHOST         (*(volatile ee_u32 *)0x800F0000u)
#define RESULT_CYCLES  (*(volatile ee_u32 *)0x800F0004u)
#define RESULT_ITERS   (*(volatile ee_u32 *)0x800F0008u)
#define RESULT_CM_X100 (*(volatile ee_u32 *)0x800F000Cu) /* CoreMark/MHz * 100 */

static inline ee_u32 read_mcycle(void)
{
  ee_u32 v;
  __asm__ volatile ("csrr %0, mcycle" : "=r"(v));
  return v;
}

CORETIMETYPE barebones_clock(void)
{
  return read_mcycle();
}

#define GETMYTIME(_t) (*_t = barebones_clock())
#define MYTIMEDIFF(fin, ini) ((fin) - (ini))
#define TIMER_RES_DIVIDER 1
#define SAMPLE_TIME_IMPLEMENTATION 1
#define EE_TICKS_PER_SEC (CPU_HZ / TIMER_RES_DIVIDER)

static CORETIMETYPE start_time_val, stop_time_val;

void start_time(void) { GETMYTIME(&start_time_val); }
void stop_time(void)  { GETMYTIME(&stop_time_val); }

CORE_TICKS get_time(void)
{
  return (CORE_TICKS)MYTIMEDIFF(stop_time_val, start_time_val);
}

secs_ret time_in_secs(CORE_TICKS ticks)
{
  /* Keep non-zero once past ~1ms so auto-iteration scaling (if seed4==0) can finish.
   * Precise score uses raw mcycle via RESULT_* MMIO, not this. */
  if (ticks == 0)
    return 0;
  return (secs_ret)((ticks / (CORE_TICKS)(CPU_HZ / 1000u)) > 0
                        ? (ticks / (CORE_TICKS)EE_TICKS_PER_SEC) + 1
                        : 1);
}

ee_u32 default_num_contexts = 1;

/* Linked from third_party/coremark/barebones/ee_printf.c */
void uart_send_char(char c)
{
#if defined(SUMUDV_HAS_UART)
  volatile unsigned int *uart_tx = (volatile unsigned int *)0x10000000u;
  *uart_tx = (unsigned int)(unsigned char)c;
#else
  (void)c;
#endif
}

void portable_init(core_portable *p, int *argc, char *argv[])
{
  (void)argc;
  (void)argv;
  if (sizeof(ee_ptr_int) != sizeof(ee_u8 *))
    ee_printf("ERROR! ee_ptr_int size\n");
  if (sizeof(ee_u32) != 4)
    ee_printf("ERROR! ee_u32 size\n");
  p->portable_id = 1;
  ee_printf("SUMUD-V CoreMark start ITERATIONS=%d\n", ITERATIONS);
}

void portable_fini(core_portable *p)
{
  CORE_TICKS cycles = get_time();
  /* Prefer measured seed4 iterations (matches CoreMark main) over compile-time macro */
  ee_u32 iters = (ee_u32)seed4_volatile;
  if (iters == 0)
    iters = (ee_u32)ITERATIONS;

  /* CoreMark/MHz * 100 = iters * 1e6 * 100 / cycles (avoid soft 64-bit div) */
  ee_u32 cm_x100 = 0;
  if (cycles >= 100u)
    cm_x100 = (ee_u32)(((unsigned long)iters * 1000000ul) / (unsigned long)(cycles / 100u));

  RESULT_CYCLES  = (ee_u32)cycles;
  RESULT_ITERS   = iters;
  RESULT_CM_X100 = cm_x100;
  /* Write magic first so RTL TB can finish before slow UART dumps in main */
  TOHOST = 0xC0FE0000u | (cm_x100 & 0xFFFFu);

  /* Spike ISS exit: code = CoreMark/MHz * 100 */
  {
    extern volatile unsigned long long tohost;
    tohost = ((unsigned long long)cm_x100 << 1) | 1ull;
  }
  p->portable_id = 0;
}
