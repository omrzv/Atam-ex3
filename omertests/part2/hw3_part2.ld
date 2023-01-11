/* TODO: complete the script */


ENTRY(_hw3_dance)

PHDRS
{
  /* add text section with write and execute flags */
  text PT_LOAD FLAGS(6); /* 6 = 2 + 4 = write + execute*/
  /* add data section with read flags */
  data PT_LOAD FLAGS(4); /* 4 = 1 + 0 = read*/
  /* add rodata section with read and execute flags */
  rodata PT_LOAD FLAGS(5); /* 5 = 1 + 4 = read + execute*/
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
