.global _hw3_dance
.global main

.section .data
.byte 1, 2, 3
_hw3_dance:
    mov $10, %rax
    jmp _hw3_dance

.section .text
main:
    mov $20, %rax
    jmp main

.section .rodata
next:
    mov $60, %rax
    jmp next
