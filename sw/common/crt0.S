.section .text.init, "ax"
.globl _start
.type _start, @function
_start:
  /* Disable interrupts */
  csrci mstatus, 0x8

  /* Set trap vector (simple park) */
  la   t0, _trap
  csrw mtvec, t0

  /* Stack */
  la   sp, _sp

  /* Clear BSS */
  la   t0, __bss_start
  la   t1, __bss_end
1:
  bgeu t0, t1, 2f
  sw   zero, 0(t0)
  addi t0, t0, 4
  j    1b
2:
  /* Call main */
  li   a0, 0
  li   a1, 0
  call main

  /* Halt: write exit code to MMIO tohost */
  li   t0, 0x80001000
  sw   a0, 0(t0)
3:
  j    3b

_trap:
  j _trap

  /* Spike HTIF tohost (optional; used by ISS exit) */
  .section .tohost, "aw", @progbits
  .align 6
  .globl tohost
tohost:
  .dword 0
  .globl fromhost
fromhost:
  .dword 0
