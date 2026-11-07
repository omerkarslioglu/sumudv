#ifndef SUMUDV_PLATFORM_H
#define SUMUDV_PLATFORM_H

#include <stdint.h>

/* Memory map (matches docs / soc_pkg) */
#define BOOT_BASE        0x80000000u
#define DRAM_BASE        0x81000000u
#define MMIO_BASE        0x10000000u
#define UART_BASE        (MMIO_BASE + 0x0000u)
#define TIMER_BASE       (MMIO_BASE + 0x1000u)
#define TOHOST_ADDR      0x80001000u
#define FB_BASE          0x20000000u

#define FB_WIDTH         320
#define FB_HEIGHT        200
#define FB_BPP           8

#define UART_TX          (*(volatile uint32_t *)(UART_BASE + 0x00))
#define UART_STATUS      (*(volatile uint32_t *)(UART_BASE + 0x04))
#define GPIO_BASE        (MMIO_BASE + 0x2000u)
#define GPIO_LED         (*(volatile uint32_t *)(GPIO_BASE + 0x00))
#define TIMER_MTIME      (*(volatile uint32_t *)(TIMER_BASE + 0x00))
#define TIMER_MTIMEH     (*(volatile uint32_t *)(TIMER_BASE + 0x04))
#define TIMER_MTIMECMP   (*(volatile uint32_t *)(TIMER_BASE + 0x08))
#define TOHOST           (*(volatile uint32_t *)(TOHOST_ADDR))

static inline uint32_t rdcycle(void)
{
  uint32_t v;
  __asm__ volatile ("csrr %0, mcycle" : "=r"(v));
  return v;
}

static inline uint32_t rdinstret(void)
{
  uint32_t v;
  __asm__ volatile ("csrr %0, minstret" : "=r"(v));
  return v;
}

static inline void uart_putc(char c)
{
  while ((UART_STATUS & 1u) == 0u)
    ;
  UART_TX = (uint32_t)(uint8_t)c;
}

static inline void uart_puts(const char *s)
{
  while (*s)
    uart_putc(*s++);
}

static inline void fb_plot(unsigned x, unsigned y, uint8_t color)
{
  if (x >= FB_WIDTH || y >= FB_HEIGHT)
    return;
  ((volatile uint8_t *)FB_BASE)[y * FB_WIDTH + x] = color;
}

#endif
