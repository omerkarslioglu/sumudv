/* Cache-less DDR memtest on Zybo PS HP path + UART/LED. */
#include "../common/platform.h"

/* Keep clear of low image (.text/.bss/stack live near 0x80000000) */
#define TEST_BASE   0x80080000u
#define TEST_WORDS  4096u

static void delay(volatile uint32_t n)
{
  while (n--)
    __asm__ volatile ("" ::: "memory");
}

static int test_pattern(uint32_t seed)
{
  volatile uint32_t *p = (volatile uint32_t *)TEST_BASE;
  for (uint32_t i = 0; i < TEST_WORDS; i++)
    p[i] = seed + i * 0x9E3779B9u;

  for (uint32_t i = 0; i < TEST_WORDS; i++) {
    uint32_t want = seed + i * 0x9E3779B9u;
    if (p[i] != want)
      return 0;
  }
  return 1;
}

int main(void)
{
  uart_puts("SUMUD-V DDR memtest\r\n");
  GPIO_LED = 0x1;

  if (!test_pattern(0xA5A5A5A5u) || !test_pattern(0x5A5A5A5Au)) {
    uart_puts("DDR FAIL\r\n");
    for (;;) {
      GPIO_LED = 0xF;
      delay(500000u);
      GPIO_LED = 0x0;
      delay(500000u);
    }
  }

  uart_puts("DDR PASS\r\n");
  for (;;) {
    for (unsigned i = 0; i < 4; i++) {
      GPIO_LED = (1u << i);
      delay(1000000u);
    }
  }
  return 0;
}
