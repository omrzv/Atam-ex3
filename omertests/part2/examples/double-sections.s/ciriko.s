.section .data
.ascii "The cake is a lie"
.byte 0

.section .rodata
next:
    mov $60, %rax
    jmp next

.section .bss
.fill 100, 1, 0
