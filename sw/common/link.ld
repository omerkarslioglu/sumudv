OUTPUT_ARCH("riscv")
ENTRY(_start)

MEMORY
{
  /* Tight code in low boot SRAM/BRAM window */
  RAM (rwx)  : ORIGIN = 0x80000000, LENGTH = 768K
  /* Large BSS / heap / WAD working set in DDR */
  DRAM (rwx) : ORIGIN = 0x81000000, LENGTH = 24M
}

STACK_SIZE = 64K;

SECTIONS
{
  .text : {
    KEEP(*(.text.init))
    *(.text .text.*)
  } > RAM

  .rodata : {
    *(.rodata .rodata.*)
    *(.srodata .srodata.*)
  } > RAM

  .data : {
    __data_start = .;
    *(.data .data.*)
    *(.sdata .sdata.*)
    __data_end = .;
  } > RAM

  .bss (NOLOAD) : {
    __bss_start = .;
    *(.bss .bss.*)
    *(.sbss .sbss.*)
    *(COMMON)
    __bss_end = .;
  } > DRAM

  .heap (NOLOAD) : {
    __heap_start = .;
    . = . + 2M;
    __heap_end = .;
  } > DRAM

  .stack (NOLOAD) : {
    . = ALIGN(16);
    . = . + STACK_SIZE;
    _sp = .;
  } > DRAM
}
