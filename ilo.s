/* AMD64 ilo, (c) 2023 Christopher Leonard, MIT License */

        .global _start

        /* rax: top of stack */
        /* rbx: data stack */
        /* rbp: jump table address */
        /* r12: address stack */
        /* r13: instruction pointer */
        /* r14: opcode shift register */
        /* r15: memory */

        .bss

        .align  8
blocks: .skip   8        /* name of blocks file (ilo.blocks) */
rom:    .skip   8        /* name of image (ilo.rom) */
dstack: .skip   32*4
astack: .skip   256*4
a:      .skip   4        /* other variables for misc. purposes */
b:      .skip   4
f:      .skip   4
s:      .skip   4
d:      .skip   4
l:      .skip   4
memory: .skip   65536*4

        .section .rodata

default_blocks:
        .asciz  "ilo.blocks"
default_rom:
        .asciz  "ilo.rom"

io_table:
        .byte   0
        .byte   iob-ioa
        .byte   ioc-ioa
        .byte   iod-ioa
        .byte   ioe-ioa
        .byte   iof-ioa
        .byte   iog-ioa
        .byte   ioh-ioa

        .text

rdonly: mov     $2, %eax    /* sys_open */
        xor     %esi, %esi  /* O_RDONLY */
        mov     $0666, %edx
        syscall
        mov     %eax, %edi
        ret

wronly: mov     $2, %eax    /* sys_open */
        mov     $1, %esi    /* O_WRONLY */
        mov     $0666, %edx
        syscall
        mov     %eax, %edi
        ret

close:  mov     $3, %eax /* sys_close */
        syscall
        ret

load_image:
        mov     rom(%rip), %rdi
        call    rdonly
        or      %eax, %eax
        jz      1f
        mov     %r15, %rsi
        mov     $65536 * 4, %edx
        xor     %eax, %eax /* sys_read */
        syscall
        call    close
        xor     %eax, %eax
        lea     dstack-4(%rip), %rbx
        lea     astack-4(%rip), %r12
        xor     %r13d, %r13d
1:      ret

save_image:
        push    %rax
        mov     rom(%rip), %rdi
        call    wronly
        or      %eax, %eax
        jz      1f
        mov     %r15, %rsi
        mov     $65536 * 4, %edx
        mov     $1, %eax
        syscall
        call    close
1:      pop     %rax
        ret

block_common:
        mov     $8, %eax   /* sys_lseek */
        mov     (%rbx), %esi
        shl     $12, %esi
        xor     %edx, %edx /* SEEK_SET */
        syscall
        xor     %eax, %eax /* sys_read */
        or      %r10b, %r10b
        jz      1f
        mov     $1, %al    /* sys_write */
1:      lea     (%r15,%r8,4), %rsi
        mov     $4096, %edx
        syscall
        mov     -4(%rbx), %esi
        sub     $8, %rbx
        ret

        .align  32
table:  ret
        .align  32
li:     add     $4, %rbx
        inc     %r13d
        mov     %eax, (%rbx)
        mov     (%r15,%r13,4), %eax
        ret
        .align  32
du:     add     $4, %rbx
        mov     %eax, (%rbx)
        ret
        .align  32
dr:     mov     (%rbx), %eax
        sub     $4, %rbx
        ret
        .align  32
sw:     xchg    (%rbx), %eax
        ret
        .align  32
pu:     add     $4, %r12
        mov     %eax, (%r12)
        mov     (%rbx), %eax
        sub     $4, %rbx
        ret
        .align  32
po:     add     $4, %rbx
        mov     %eax, (%rbx)
        mov     (%r12), %eax
        sub     $4, %r12
        ret
        .align  32
ju:     lea     -1(%eax), %r13d
        mov     (%rbx), %eax
        sub     $4, %rbx
        ret
        .align  32
ca:     add     $4, %r12
        mov     %r13d, (%r12)
        lea     -1(%eax), %r13d
        mov     (%rbx), %eax
        sub     $4, %rbx
        ret
        .align  32
cc:     cmpl    $0, (%rbx)
        jz      1f
        add     $4, %r12
        mov     %r13d, (%r12)
        lea     -1(%eax), %r13d
1:      mov     -4(%rbx), %eax
        sub     $8, %rbx
        ret
        .align  32
cj:     cmpl    $0, (%rbx)
        jz      1f
        lea     -1(%eax), %r13d
1:      mov     -4(%rbx), %eax
        sub     $8, %rbx
        ret
        .align  32
re:     mov     (%r12), %r13d
        sub     $4, %r12
        ret
        .align  32
eq:     cmp     %eax, (%rbx)
        sete    %al
        movzbl  %al, %eax
        neg     %eax
        sub     $4, %rbx
        ret
        .align  32
ne:     cmp     %eax, (%rbx)
        setne   %al
        movzbl  %al, %eax
        neg     %eax
        sub     $4, %rbx
        ret
        .align  32
lt:     cmp     %eax, (%rbx)
        setl    %al
        movzbl  %al, %eax
        neg     %eax
        sub     $4, %rbx
        ret
        .align  32
gt:     cmp     %eax, (%rbx)
        setg    %al
        movzbl  %al, %eax
        neg     %eax
        sub     $4, %rbx
        ret
        .align  32
fe:     mov     (%r15,%rax,4), %eax
        ret
        .align  32
st:     mov     (%rbx), %ecx
        mov     %ecx, (%r15,%rax,4)
        mov     -4(%rbx), %eax
        sub     $8, %rbx
        ret
        .align  32
ad:     add     (%rbx), %eax
        sub     $4, %rbx
        ret
        .align  32
su:     sub     (%rbx), %eax
        neg     %eax
        sub     $4, %rbx
        ret
        .align  32
mu:     mull    (%rbx)
        sub     $4, %rbx
        ret
        .align  32
di:     mov     %eax, %ecx
        mov     (%rbx), %eax
        cdq
        idiv    %ecx
        sub     $4, %rbx
        ret
        .align  32
an:     and     (%rbx), %eax
        sub     $4, %rbx
        ret
        .align  32
or:     or      (%rbx), %eax
        sub     $4, %rbx
        ret
        .align  32
xo:     xor     (%rbx), %eax
        sub     $4, %rbx
        ret
        .align  32
sl:     mov     %eax, %ecx
        mov     (%rbx), %eax
        sub     $4, %rbx
        shl     %cl, %eax
        ret
        .align  32
sr:     mov     %eax, %ecx
        mov     (%rbx), %eax
        sub     $4, %rbx
        sar     %cl, %eax
        ret
        .align  32
cp:     mov     %eax, %ecx
        mov     (%rbx), %edi
        mov     -4(%rbx), %esi
        sub     $8, %rbx
        lea     (%r15,%rdi,4), %rdi
        lea     (%r15,%rsi,4), %rsi
        cmp     %eax, %eax
        repe cmpsd
        sete    %al
        movzbl  %al, %eax
        neg     %eax
        ret
        .align  32
cy:     mov     %eax, %ecx
        mov     (%rbx), %edi
        mov     -4(%rbx), %esi
        mov     -8(%rbx), %eax
        sub     $12, %rbx
        lea     (%r15,%rdi,4), %rdi
        lea     (%r15,%rsi,4), %rsi
        repe movsd
        ret
        .align  32
io:     mov     %eax, %ecx
        mov     (%rbx), %eax
        sub     $4, %rbx
        cmp     $7, %ecx
        ja      1f
        lea     io_table(%rip), %rdx
        movzbl  (%rdx,%rcx), %ecx
        lea     ioa(%rip), %rdx
        add     %rdx, %rcx
        jmp     *%rcx
1:      ret

ioa:    push    %rax
        mov     $1, %eax /* sys_write */
        mov     %eax, %edi
        mov     %rsp, %rsi
        mov     %eax, %edx
        syscall
        pop     %rax
        mov     (%rbx), %eax
        sub     $4, %rbx
        ret
iob:    add     $4, %rbx
        mov     %eax, (%rbx)
        xor     %eax, %eax /* sys_read */
        push    %rax
        xor     %edi, %edi
        mov     %rsp, %rsi
        mov     $1, %edx
        syscall
        pop     %rax
        ret
ioc:    mov     %eax, %r8d
        mov     blocks(%rip), %rdi
        call    rdonly
        xor     %r10d, %r10d
        call    block_common
        call    close
        mov     %esi, %eax
        ret
iod:    mov     %eax, %r8d
        mov     blocks(%rip), %rdi
        call    wronly
        mov     $1, %r10b
        call    block_common
        call    close
        mov     %esi, %eax
        ret
ioe:    jmp     save_image
iof:    push    %rax
        call    load_image
        dec     %r13d
        pop     %rax
        ret
iog:    mov     $65536, %r13d
        ret
ioh:    add     $8, %rbx
        mov     %eax, -4(%rbx)
        lea     astack-4(%rip), %rdx
        neg     %edx
        lea     4*32-8(%rbx,%rdx), %rax
        shr     $2, %eax
        mov     %eax, (%rbx)
        lea     (%r12,%rdx), %rax
        shr     $2, %eax
        ret

_start: xor     %eax, %eax
        lea     memory(%rip), %r15
        lea     dstack-4(%rip), %rbx
        lea     astack-4(%rip), %r12
        xor     %r13d, %r13d
        lea     table(%rip), %rbp
        mov     8(%rsp), %rcx
        or      %rcx, %rcx
        jz      1f
        mov     16(%rsp), %rcx
        or      %rcx, %rcx
        jz      1f
        mov     %rcx, blocks(%rip)
        mov     24(%rsp), %rcx
        or      %rcx, %rcx
        jz      2f
        mov     %rcx, rom(%rip)
        jmp     3f
1:      lea     default_blocks(%rip), %rcx
        mov     %rcx, blocks(%rip)
2:      lea     default_rom(%rip), %rcx
        mov     %rcx, rom(%rip)
3:      call    load_image
        jmp     3f
2:      mov     (%r15,%r13,4), %r14d
        movzbl  %r14b, %edi
        shr     $8, %r14d
        cmp     $29, %edi
        ja      1f
        shl     $5, %edi
        add     %rbp, %rdi
        call    *%rdi
1:      movzbl  %r14b, %edi
        shr     $8, %r14d
        cmp     $29, %edi
        ja      1f
        shl     $5, %edi
        add     %rbp, %rdi
        call    *%rdi
1:      movzbl  %r14b, %edi
        shr     $8, %r14d
        cmp     $29, %edi
        ja      1f
        shl     $5, %edi
        add     %rbp, %rdi
        call    *%rdi
1:      mov     %r14d, %edi
        cmp     $29, %edi
        ja      1f
        shl     $5, %edi
        add     %rbp, %rdi
        call    *%rdi
1:      inc     %r13
3:      cmp     $65536, %r13
        jl      2b
        mov     $60, %eax /* sys_exit */
        xor     %edi, %edi
        syscall
