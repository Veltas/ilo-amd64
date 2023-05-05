; x86-64 ilo, (c) 2023 Christopher Leonard, MIT License

        global _start

        ; rax: top of stack
        ; rbx: data stack
        ; rbp: jump table address
        ; r12: address stack
        ; r13: instruction pointer
        ; r14: opcode shift register
        ; r15: memory

        section .bss

dstack  resd    32
astack  resd    256
blocks  resq    1     ; name of blocks file (ilo.blocks)
rom     resq    1     ; name of image (ilo.rom)
a       resd    1     ; other variables for misc. purposes
b       resd    1
f       resd    1
s       resd    1
d       resd    1
l       resd    1
memory  resd    65536

        section .rodata

default_blocks
        db      "ilo.blocks", 0
default_rom
        db      "ilo.rom", 0

        section .text

rdonly  mov     eax, 2    ; sys_open
        xor     esi, esi  ; O_RDONLY
        mov     edx, 666o
        syscall
        mov     edi, eax
        ret

wronly  mov     eax, 2    ; sys_open
        mov     esi, 1    ; O_WRONLY
        mov     edx, 666o
        syscall
        mov     edi, eax
        ret

write   mov     eax, 1 ; sys_write
        syscall
        ret

close   mov     eax, 3 ; sys_close
        syscall
        ret

load_image
        mov     rdi, [rel rom]
        call    rdonly
        or      eax, eax
        jz      .end
        mov     rsi, r15
        mov     edx, 65536 * 4
        xor     eax, eax ; sys_read
        syscall
        call    close
        xor     eax, eax
        lea     rbx, [rel dstack - 4]
        lea     r12, [rel astack - 4]
        xor     r13d, r13d
.end    ret

save_image
        push    rax
        mov     rdi, [rel rom]
        call    wronly
        or      eax, eax
        jz      .end
        mov     rsi, r15
        mov     edx, 65536 * 4
        call    write
        call    close
.end    pop     rax
        ret

block_common
        mov     eax, 8   ; sys_lseek
        mov     esi, [rbx]
        shl     esi, 12
        xor     edx, edx ; SEEK_SET
        syscall
        xor     eax, eax ; sys_read
        or      r10b, r10b
        jz      .read
        mov     al, 1    ; sys_write
.read   lea     rsi, [r15 + 4*r8]
        mov     edx, 4096
        syscall
        mov     esi, [rbx - 4]
        sub     rbx, 8
        ret

        align   32
table   ret
        align   32
li      add     rbx, 4
        inc     r13d
        mov     [rbx], eax
        mov     eax, [r15 + 4*r13]
        ret
        align   32
du      add     rbx, 4
        mov     [rbx], eax
        ret
        align   32
dr      mov     eax, [rbx]
        sub     rbx, 4
        ret
        align   32
sw      xchg    eax, [rbx]
        ret
        align   32
pu      add     r12, 4
        mov     [r12], eax
        mov     eax, [rbx]
        sub     rbx, 4
        ret
        align   32
po      add     rbx, 4
        mov     [rbx], eax
        mov     eax, [r12]
        sub     r12, 4
        ret
        align   32
ju      lea     r13d, [eax - 1]
        mov     eax, [rbx]
        sub     rbx, 4
        ret
        align   32
ca      add     r12, 4
        mov     [r12], r13d
        lea     r13d, [eax - 1]
        mov     eax, [rbx]
        sub     rbx, 4
        ret
        align   32
cc      cmp     dword[rbx], 0
        jz      .nocall
        add     r12, 4
        mov     [r12], r13d
        lea     r13d, [eax - 1]
.nocall mov     eax, [rbx - 4]
        sub     rbx, 8
        ret
        align   32
cj      cmp     dword[rbx], 0
        jz      .nojump
        lea     r13d, [eax - 1]
.nojump mov     eax, [rbx - 4]
        sub     rbx, 8
        ret
        align   32
re      mov     r13d, [r12]
        sub     r12, 4
        ret
        align   32
eq      cmp     [rbx], eax
        sete    al
        movzx   eax, al
        neg     eax
        sub     rbx, 4
        ret
        align   32
ne      cmp     [rbx], eax
        setne   al
        movzx   eax, al
        neg     eax
        sub     rbx, 4
        ret
        align   32
lt      cmp     [rbx], eax
        setl    al
        movzx   eax, al
        neg     eax
        sub     rbx, 4
        ret
        align   32
gt      cmp     [rbx], eax
        setg    al
        movzx   eax, al
        neg     eax
        sub     rbx, 4
        ret
        align   32
fe      mov     eax, [r15 + 4*rax]
        ret
        align   32
st      mov     ecx, [rbx]
        mov     [r15 + 4*rax], ecx
        mov     eax, [rbx - 4]
        sub     rbx, 8
        ret
        align   32
ad      add     eax, [rbx]
        sub     rbx, 4
        ret
        align   32
su      sub     eax, [rbx]
        neg     eax
        sub     rbx, 4
        ret
        align   32
mu      mul     dword[rbx]
        sub     rbx, 4
        ret
        align   32
$di     mov     ecx, eax
        mov     eax, [rbx]
        cdq
        idiv    ecx
        sub     rbx, 4
        ret
        align   32
an      and     eax, [rbx]
        sub     rbx, 4
        ret
        align   32
$or     or      eax, [rbx]
        sub     rbx, 4
        ret
        align   32
xo      xor     eax, [rbx]
        sub     rbx, 4
        ret
        align   32
sl      mov     ecx, eax
        mov     eax, [rbx]
        sub     rbx, 4
        shl     eax, cl
        ret
        align   32
sr      mov     ecx, eax
        mov     eax, [rbx]
        sub     rbx, 4
        sar     eax, cl
        ret
        align   32
cp      mov     ecx, eax
        mov     edi, [rbx]
        mov     esi, [rbx - 4]
        sub     rbx, 8
        lea     rdi, [r15 + 4*rdi]
        lea     rsi, [r15 + 4*rsi]
        cmp     eax, eax
        repe cmpsd
        sete    al
        movzx   eax, al
        neg     eax
        ret
        align   32
cy      mov     ecx, eax
        mov     edi, [rbx]
        mov     esi, [rbx - 4]
        mov     eax, [rbx - 8]
        sub     rbx, 12
        lea     rdi, [r15 + 4*rdi]
        lea     rsi, [r15 + 4*rsi]
        repe movsd
        ret
        align   32
ioa     push    rax
        mov     eax, 1 ; sys_write
        mov     edi, eax
        mov     rsi, rsp
        mov     edx, eax
        syscall
        pop     rax
        mov     eax, [rbx]
        sub     rbx, 4
        ret
        align   32
iob     add     rbx, 4
        mov     [rbx], eax
        xor     eax, eax ; sys_read
        push    rax
        xor     edi, edi
        mov     rsi, rsp
        mov     edx, 1
        syscall
        pop     rax
        ret
        align   32
ioc     mov     r8d, eax
        mov     rdi, [rel blocks]
        call    rdonly
        xor     r10d, r10d
        call    block_common
        call    close
        mov     eax, esi
        ret
        align   32
iod     mov     r8d, eax
        mov     rdi, [rel blocks]
        call    wronly
        mov     r10b, 1
        call    block_common
        call    close
        mov     eax, esi
        ret
        align   32
ioe     jmp     save_image
        align   32
iof     call    load_image
        dec     r13d
        ret
        align   32
iog     mov     r13d, 65536
        ret
        align   32
ioh     add     rbx, 8
        mov     [rbx - 4], eax
        lea     rdx, [rel astack]
        neg     edx
        lea     rax, [rbx + rdx - 4*32]
        shr     eax, 2
        mov     [rbx], eax
        lea     rax, [r12 + rdx]
        jmp     iohcont
        align   32
io      mov     ecx, eax
        mov     eax, [rbx]
        sub     rbx, 4
        cmp     ecx, 7
        ja      .skip
        shl     ecx, 5
        lea     rcx, [rel ioa + rcx]
        jmp     rcx
.skip   ret

iohcont shr     eax, 2
        ret

_start  xor     eax, eax
        lea     r15, [rel memory]
        lea     rbx, [rel dstack - 4]
        lea     r12, [rel astack - 4]
        xor     r13d, r13d
        lea     rbp, [rel table]
        mov     rcx, [rsp+8]
        or      rcx, rcx
        jz      .noargs
        mov     [rel blocks], rcx
        mov     rcx, [rsp+16]
        or      rcx, rcx
        jz      .onearg
        mov     [rel rom], rcx
        jmp     .twoarg
.noargs lea     rcx, [rel default_blocks]
        mov     [rel blocks], rcx
.onearg lea     rcx, [rel default_rom]
        mov     [rel rom], rcx
.twoarg call    load_image
        jmp     .cond
.cont   mov     r14d, [r15 + 4*r13]
        movzx   edi, r14b
        shr     r14d, 8
        cmp     edi, 29
        ja      .nop1
        shl     edi, 5
        add     rdi, rbp
        call    rdi
.nop1   movzx   edi, r14b
        shr     r14d, 8
        cmp     edi, 29
        ja      .nop2
        shl     edi, 5
        add     rdi, rbp
        call    rdi
.nop2   movzx   edi, r14b
        shr     r14d, 8
        cmp     edi, 29
        ja      .nop3
        shl     edi, 5
        add     rdi, rbp
        call    rdi
.nop3   mov     edi, r14d
        cmp     edi, 29
        ja      .nop4
        shl     edi, 5
        add     rdi, rbp
        call    rdi
.nop4   inc     r13
.cond   cmp     r13, 65536
        jl      .cont
        mov     eax, 60 ; sys_exit
        xor     edi, edi
        syscall
