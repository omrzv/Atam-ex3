/* TODO: complete the script */


ENTRY(_hw3_dance)

PHDRS
{
  /* add text section with write and execute flags */
  text PT_LOAD FLAGS(3); /* 3 = 011 = write + execute*/
  /* add data section with read flags */
  data PT_LOAD FLAGS(2); /* 2 = 010 = write*/
  /* add rodata section with read and execute flags */
  rodata PT_LOAD FLAGS(5); /* 5 = 101 = read + execute*/
}

EXTERN(greens)
EXTERN(blacks)

SECTIONS
{
  . = 0x20000;
  .data :
  {
	*(.data)
	*(.bss)
  } :data

  . = 0x400000;
  .text :
  {
  *(.text)
  } :text 

  . = 0x90000000;
  .rodata :
  {
  *(.rodata)
  } :rodata 
  
}
