.global _hw3_dance

.bss
.fill 100, 1, 0

.data
.byte 1, 2, 3
.ascii "numa numa yeah"

.text
_hw3_dance:
    mov $10, %rax
    jmp _hw3_dance


.section .rodata
next:
    mov $60, %rax
    jmp next
