section .data
    fmt_result  db  "log_{%s}(%s) = %.18Lg", 10, 0
    fmt_usage   db  "Usage:", 10, 9, "<program> <base> <number> <epsilon>", 10, 0
    usage_len   equ $ - fmt_usage
    zero        dq  0.0
    one         dq  1.0

section .bss
    val_a       resq 2
    val_b       resq 2
    val_eps     resq 2

section .text
    global main
    extern strtold, printf

main:
    push rbp
    mov  rbp, rsp
    push rbx
    push r12

    cmp  rdi, 4
    jne  .usage_error

    mov  r12, rsi

    mov  rdi, [r12 + 8]
    xor  rsi, rsi
    call strtold
    fstp tword [val_a]

    mov  rdi, [r12 + 16]
    xor  rsi, rsi
    call strtold
    fstp tword [val_b]

    mov  rdi, [r12 + 24]
    xor  rsi, rsi
    call strtold
    fstp tword [val_eps]

    fld  qword [one]
    fld  tword [val_a]
    fucomip st0, st1
    fstp st0
    jbe  .usage_error

    fld  qword [zero]
    fld  tword [val_b]
    fucomip st0, st1
    fstp st0
    jbe  .usage_error

    fld  qword [zero]
    fld  tword [val_eps]
    fucomip st0, st1
    fstp st0
    jbe  .usage_error

    sub  rsp, 48
    fld  tword [val_a]
    fstp tword [rsp]
    fld  tword [val_b]
    fstp tword [rsp + 16]
    fld  tword [val_eps]
    fstp tword [rsp + 32]
    call disc_log
    add  rsp, 48

    sub  rsp, 16
    fstp tword [rsp]
    mov  rdi, fmt_result
    mov  rsi, [r12 + 8]
    mov  rdx, [r12 + 16]
    mov  al, 0
    call printf
    add  rsp, 16

    xor  eax, eax
    jmp  .done

.usage_error:
    mov  rax, 1
    mov  rdi, 2
    mov  rsi, fmt_usage
    mov  rdx, usage_len
    syscall
    mov  eax, 1

.done:
    pop  r12
    pop  rbx
    mov  rsp, rbp
    pop  rbp
    ret

disc_log:
    push rbp
    mov  rbp, rsp
    sub  rsp, 48

    fld  tword [rbp + 16]
    fstp tword [rbp - 16]
    fld  tword [rbp + 32]
    fstp tword [rbp - 32]
    fld  tword [rbp + 48]
    fstp tword [rbp - 48]

    fld  tword [rbp - 32]
    fld  tword [rbp - 16]
    fucomip st0, st1
    fstp st0
    ja   .a_greater

    fld  tword [rbp - 32]
    fld  tword [rbp - 16]
    fdivp
    fstp tword [rbp - 32]

    fld  tword [rbp - 48]
    fld  tword [rbp - 32]
    fld1
    fsubp
    fucomip st0, st1
    fstp st0
    jb   .small

    sub  rsp, 48
    fld  tword [rbp - 16]
    fstp tword [rsp]
    fld  tword [rbp - 32]
    fstp tword [rsp + 16]
    fld  tword [rbp - 48]
    fstp tword [rsp + 32]
    call disc_log
    add  rsp, 48

    fld1
    faddp
    jmp  .return

.small:
    fld1
    jmp  .return

.a_greater:
    sub  rsp, 48
    fld  tword [rbp - 32]
    fstp tword [rsp]
    fld  tword [rbp - 16]
    fstp tword [rsp + 16]
    fld  tword [rbp - 48]
    fstp tword [rsp + 32]
    call disc_log
    add  rsp, 48

    fstp tword [rbp - 16]
    fld1
    fld  tword [rbp - 16]
    fdivp

.return:
    mov  rsp, rbp
    pop  rbp
    ret