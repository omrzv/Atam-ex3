.global _hw3_dance
.global main

.section .data
.byte 1, 2, 3

.section .text
_hw3_dance:
    mov $10, %rax
    jmp _hw3_dance

main:
    mov $20, %rax
    jmp main
