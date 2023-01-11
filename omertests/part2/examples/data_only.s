.global _hw3_dance

.section .data
.byte 1, 2, 3
.asciz "Hello World"
.long 0x12345678
.quad 0x1234567890123456

_hw3_dance:
    mov $10, %rax
    jmp _hw3_dance
