.global _hw3_dance
.global main

.section .bss
.byte 0
.word 0
.long 0
.quad 0

.section .data
.asciz "Oh, I'm just a social drinker. Every time someone says, 'I'll have a drink', I say, 'So shall I'!"
.byte 1, 2, 3

.section .text
_hw3_dance:
    mov $10, %rax
    jmp _hw3_dance

main:
    mov $20, %rax
    jmp main

.section .rodata
next:
    mov $60, %rax
    jmp next
