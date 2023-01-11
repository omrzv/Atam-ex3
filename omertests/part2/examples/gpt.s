        .section    .data
        .align 4
array:
        .long       0, 0, 0, 0, 0
        .section    .bss
        .align 4
counter:
        .zero       4
        .section    .rodata
        .align 4
string:
        .asciz      "This is a random string."
        .globl      _hw3_dance
        .type       _hw3_dance, @function
_hw3_dance:
        movl        $string, %edi
        #call        puts
        movl        $0, counter
        movl        counter, %eax
        ret
