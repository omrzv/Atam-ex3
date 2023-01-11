.global iliko

.section .rodata
.ascii "Life is more than a series of ones and zeroes."

.section .text
.align 4, 0x90
iliko:
    push %rax
    push %rsi
# CLASSIFIED
    cmp $0x0f, %al
    jnz one_byte
    mov %ah, %al
    inc %r8

one_byte:
    movzx %al, %rdi
# CLASSIFIED
    test %eax, %eax
    jnz set_and_exit
    pop %r8
    pop %rsi
    pop %rax

set_and_exit:
# CLASSIFIED
    pop %r8
    pop %rsi
    pop %rax
    iretq
