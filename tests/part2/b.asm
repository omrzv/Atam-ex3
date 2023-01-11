.global foo
.section .data
b_data: .zero 8

.section .rodata
b_ro: .ascii "Tell me whyyy\n"

.section .bss
.lcomm b_bss, 8

.section .text
foo:
  movq $60, %rax
  movq $0, %rdi
  syscall
