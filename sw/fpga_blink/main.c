/* Zybo PL bring-up: UART banner + LED walk. */
#include "../common/platform.h"

static void delay(volatile uint32_t n)
{
  while (n--)
    __asm__ volatile ("" ::: "memory");
}

int main(void)
{
  uart_puts("SUMUD-V FPGA blink\r\n");
  for (;;) {
    for (unsigned i = 0; i < 4; i++) {
      GPIO_LED = (1u << i);
      uart_putc('0' + (char)i);
      delay(2000000u);
    }
    uart_puts("\r\n");
  }
  return 0;
}
