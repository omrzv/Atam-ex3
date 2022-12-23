/* TODO: complete the script */


ENTRY(_hw3_dance)
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

  //TODO: add other sections
}
