OUTPUT_ARCH("riscv")
ENTRY(_start)

MEMORY
{
  /* CPU view: adapter maps 0x80000000 → PS DDR phys 0x00000000 */
  RAM (rwx) : ORIGIN = 0x80000000, LENGTH = 1M
}

STACK_SIZE = 8K;

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
    *(.data .data.*)
    *(.sdata .sdata.*)
  } > RAM

  .bss (NOLOAD) : {
    __bss_start = .;
    *(.bss .bss.*)
    *(.sbss .sbss.*)
    *(COMMON)
    __bss_end = .;
  } > RAM

  .heap (NOLOAD) : {
    __heap_start = .;
    . = . + 16K;
    __heap_end = .;
  } > RAM

  .stack (NOLOAD) : {
    . = ALIGN(16);
    . = . + STACK_SIZE;
    _sp = .;
  } > RAM
}
