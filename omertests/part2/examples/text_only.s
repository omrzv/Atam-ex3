.global _hw3_dance
.global main

.section .text
_hw3_dance:
    mov $10, %rax
    jmp _hw3_dance

main:
    mov $20, %rax
    jmp main
