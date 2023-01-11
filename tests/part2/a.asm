.global buff, _hw3_dance

.section .data
buff: .zero 8
msg: .ascii "Tell me why\n"
endmsg:

.section .rodata
this_is_ro: .ascii "ain't nothing but a mistake\n"

.section .text

_hw3_dance:
  call foo
