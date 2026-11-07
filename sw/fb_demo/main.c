#include "platform.h"

/* Color bars → HDMI framebuffer bring-up */
int main(void)
{
  uart_puts("fb_demo start\n");
  for (unsigned y = 0; y < FB_HEIGHT; y++) {
    for (unsigned x = 0; x < FB_WIDTH; x++) {
      uint8_t c = (uint8_t)((x * 8) / FB_WIDTH); /* 8 bars */
      fb_plot(x, y, (uint8_t)(c * 32));
    }
  }
  uart_puts("fb_demo done\n");
  TOHOST = 1;
  for (;;)
    ;
  return 0;
}
