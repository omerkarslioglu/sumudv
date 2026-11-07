#include "svdpi.h"
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <string>
#include <vector>

static std::vector<uint32_t> mem;
static std::vector<uint32_t> dram;
static std::vector<uint32_t> fb;
static std::string uart_log;
static constexpr uint32_t kBoot = 0x80000000u;
static constexpr uint32_t kDram = 0x81000000u;
static constexpr uint32_t kFb   = 0x20000000u;
static constexpr size_t kWords     = 262144;                 // 1 MiB boot/code
static constexpr size_t kDramWords = (8u * 1024u * 1024u) / 4u; // 8 MiB BSS/heap/stack
static constexpr size_t kFbWords   = (320 * 200 + 3) / 4;

static uint32_t merge_be(uint32_t cur, uint32_t d, int be) {
  if (be & 1) cur = (cur & 0xffffff00u) | (d & 0xffu);
  if (be & 2) cur = (cur & 0xffff00ffu) | (d & 0xff00u);
  if (be & 4) cur = (cur & 0xff00ffffu) | (d & 0xff0000u);
  if (be & 8) cur = (cur & 0x00ffffffu) | (d & 0xff000000u);
  return cur;
}

extern "C" {

void dpi_mem_init(const char* hex_path) {
  mem.assign(kWords, 0x00000013u);
  dram.assign(kDramWords, 0);
  fb.assign(kFbWords, 0);
  uart_log.clear();
  FILE* f = std::fopen(hex_path, "r");
  if (!f) {
    std::fprintf(stderr, "dpi_mem_init: cannot open %s\n", hex_path);
    return;
  }
  char line[64];
  size_t i = 0;
  while (i < kWords && std::fgets(line, sizeof line, f)) {
    unsigned v = 0;
    if (std::sscanf(line, "%x", &v) == 1)
      mem[i++] = v;
  }
  std::fclose(f);
  std::printf("DPI mem loaded %zu words from %s\n", i, hex_path);
}

void dpi_mem_write(int addr, int data, int be) {
  const uint32_t a = static_cast<uint32_t>(addr);
  if ((a & 0xffff0000u) == 0x10000000u) {
    if ((a & 0xffffu) == 0) {
      const char c = static_cast<char>(data & 0xff);
      std::fputc(c, stdout);
      std::fflush(stdout);
      uart_log.push_back(c);
    }
    return;
  }
  if ((a & 0xf0000000u) == kFb) {
    const size_t idx = (a - kFb) >> 2;
    if (idx < fb.size())
      fb[idx] = merge_be(fb[idx], static_cast<uint32_t>(data), be);
    return;
  }
  if (a >= kDram && a < kDram + kDramWords * 4u) {
    const size_t idx = (a - kDram) >> 2;
    dram[idx] = merge_be(dram[idx], static_cast<uint32_t>(data), be);
    return;
  }
  if (a < kBoot) return;
  const size_t idx = (a - kBoot) >> 2;
  if (idx >= kWords) return;
  mem[idx] = merge_be(mem[idx], static_cast<uint32_t>(data), be);
}

int dpi_mem_read(int addr) {
  const uint32_t a = static_cast<uint32_t>(addr);
  if ((a & 0xffff0000u) == 0x10000000u) {
    if ((a & 0xffffu) == 0x4) return 0; // UART_STATUS: no RX
    return 1;                           // TX ready
  }
  if ((a & 0xf0000000u) == kFb) {
    const size_t idx = (a - kFb) >> 2;
    if (idx < fb.size()) return static_cast<int>(fb[idx]);
    return 0;
  }
  if (a >= kDram && a < kDram + kDramWords * 4u) {
    const size_t idx = (a - kDram) >> 2;
    return static_cast<int>(dram[idx]);
  }
  if (a < kBoot) return 0x00000013;
  const size_t idx = (a - kBoot) >> 2;
  if (idx >= kWords) return 0;
  return static_cast<int>(mem[idx]);
}

int dpi_uart_contains(const char* needle) {
  if (!needle) return 0;
  return uart_log.find(needle) != std::string::npos;
}

}
