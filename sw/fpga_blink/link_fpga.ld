OUTPUT_ARCH("riscv")
ENTRY(_start)

MEMORY
{
  /* Matches fpga_bram 64 KiB window at BootAddr */
  RAM (rwx) : ORIGIN = 0x80000000, LENGTH = 64K
}

STACK_SIZE = 4K;

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
    . = . + 2K;
    __heap_end = .;
  } > RAM

  .stack (NOLOAD) : {
    . = ALIGN(16);
    . = . + STACK_SIZE;
    _sp = .;
  } > RAM
}
