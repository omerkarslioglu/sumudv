/* doomgeneric platform glue for SUMUD-V / Zybo framebuffer */
#include "doomkeys.h"
#include "doomgeneric.h"
#include "../common/platform.h"

#include <string.h>
#include <stdint.h>

#ifndef CMAP256
#error "SUMUD-V port expects -DCMAP256 (8-bit palette framebuffer)"
#endif

#define KEYQ 32
static uint16_t key_q[KEYQ];
static unsigned key_r, key_w;
static uint32_t ticks_ms;

static void key_push(int pressed, unsigned char key)
{
  key_q[key_w] = (uint16_t)((pressed << 8) | key);
  key_w = (key_w + 1) % KEYQ;
}

/* UART RX → doom keys (simple ASCII mapping for bring-up) */
static void poll_uart_keys(void)
{
  /* STATUS bit0 = RX valid (matches uart_stub convention if implemented) */
  if (UART_STATUS & 1u) {
    unsigned char c = (unsigned char)UART_TX; /* stub: reuse TX reg as RX for sim */
    unsigned char k = 0;
    int pressed = 1;
    switch (c) {
      case 'w': case 'W': k = KEY_UPARROW; break;
      case 's': case 'S': k = KEY_DOWNARROW; break;
      case 'a': case 'A': k = KEY_LEFTARROW; break;
      case 'd': case 'D': k = KEY_RIGHTARROW; break;
      case ' ': k = KEY_USE; break;
      case 'e': case 'E': case '\n': case '\r': k = KEY_ENTER; break;
      case 27: k = KEY_ESCAPE; break;
      case 'j': case 'J': k = KEY_FIRE; break;
      default: break;
    }
    if (k)
      key_push(pressed, k);
  }
}

void DG_Init(void)
{
  ticks_ms = 0;
  key_r = key_w = 0;
  uart_puts("SUMUD-V doomgeneric init\n");
  volatile uint32_t *fb32 = (volatile uint32_t *)FB_BASE;
  for (unsigned i = 0; i < (FB_WIDTH * FB_HEIGHT) / 4u; i++)
    fb32[i] = 0;
}

void DG_DrawFrame(void)
{
  /* DG_ScreenBuffer is 320x200 (or RESX/RESY) 8-bit indexed when CMAP256 */
  const unsigned w = DOOMGENERIC_RESX;
  const unsigned h = DOOMGENERIC_RESY;
  volatile uint8_t *fb = (volatile uint8_t *)FB_BASE;

  unsigned dw = (w > FB_WIDTH) ? FB_WIDTH : w;
  unsigned dh = (h > FB_HEIGHT) ? FB_HEIGHT : h;

  for (unsigned y = 0; y < dh; y++) {
    const uint8_t *src = (const uint8_t *)(DG_ScreenBuffer + y * w);
    volatile uint8_t *dst = fb + y * FB_WIDTH;
    unsigned x = 0;
    for (; x + 4 <= dw; x += 4) {
      uint32_t w32;
      memcpy(&w32, src + x, 4);
      *(volatile uint32_t *)(dst + x) = w32;
    }
    for (; x < dw; x++)
      dst[x] = src[x];
  }

  poll_uart_keys();
}

void DG_SleepMs(uint32_t ms)
{
  /* Busy-wait using mcycle; assume ~50 MHz → 50000 cycles/ms */
  uint32_t start = rdcycle();
  uint32_t need = ms * 50000u;
  while ((rdcycle() - start) < need)
    ;
  ticks_ms += ms;
}

uint32_t DG_GetTicksMs(void)
{
  /* Prefer MMIO timer if present; else approximate from mcycle */
  uint32_t lo = TIMER_MTIME;
  if (lo != 0 || TIMER_MTIMEH != 0)
    return lo; /* treat as ms tick if SoC programs it that way */
  return ticks_ms + (rdcycle() / 50000u);
}

int DG_GetKey(int *pressed, unsigned char *doomKey)
{
  if (key_r == key_w)
    return 0;
  uint16_t d = key_q[key_r];
  key_r = (key_r + 1) % KEYQ;
  *pressed = d >> 8;
  *doomKey = (unsigned char)(d & 0xff);
  return 1;
}

void DG_SetWindowTitle(const char *title)
{
  uart_puts(title);
  uart_putc('\n');
}

int main(int argc, char **argv)
{
  static char *args[] = { "doom", "-iwad", "doom1.wad", 0 };
  if (argc < 1) {
    argc = 3;
    argv = args;
  }
  doomgeneric_Create(argc, argv);
  for (;;)
    doomgeneric_Tick();
  return 0;
}
