.global _hw3_dance

.section .data
.byte 1, 2, 3
.asciz "I take care of my friends!"

.text
_hw3_dance:
    mov $10, %rax
    jmp _hw3_dance

.section .bss
.quad 0
