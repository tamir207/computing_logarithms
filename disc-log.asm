section .data
    fmt_result  db  "log_{%s}(%s) = %.18Lg", 10, 0
    fmt_usage   db  "Usage:", 10, 9, "<program> <base> <number> <epsilon>", 10, 0
    usage_len   equ $ - fmt_usage
    zero        dq  0.0
    one         dq  1.0

section .bss
    a_value           resq 2
    b_value           resq 2
    epsilon_value     resq 2

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
    fstp tword [a_value]

    mov  rdi, [r12 + 16]
    xor  rsi, rsi
    call strtold
    fstp tword [b_value]

    mov  rdi, [r12 + 24]
    xor  rsi, rsi
    call strtold
    fstp tword [epsilon_value]

    fld  qword [one]
    fld  tword [a_value]
    fucomip st0, st1
    fstp st0
    jbe  .usage_error

    fld  qword [zero]
    fld  tword [b_value]
    fucomip st0, st1
    fstp st0
    jbe  .usage_error

    fld  qword [zero]
    fld  tword [epsilon_value]
    fucomip st0, st1
    fstp st0
    jbe  .usage_error

    sub  rsp, 48
    fld  tword [a_value]
    fstp tword [rsp]
    fld  tword [b_value]
    fstp tword [rsp + 16]
    fld  tword [epsilon_value]
    fstp tword [rsp + 32]
    call compute_log
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

compute_log:
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
    ja   .a_is_greater

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
    jb   .epsilon_is_greater

    sub  rsp, 48
    fld  tword [rbp - 16]
    fstp tword [rsp]
    fld  tword [rbp - 32]
    fstp tword [rsp + 16]
    fld  tword [rbp - 48]
    fstp tword [rsp + 32]
    call compute_log
    add  rsp, 48

    fld1
    faddp
    jmp  .epilogue

.epsilon_is_greater:
    fld1
    jmp  .epilogue

.a_is_greater:
    sub  rsp, 48
    fld  tword [rbp - 32]
    fstp tword [rsp]
    fld  tword [rbp - 16]
    fstp tword [rsp + 16]
    fld  tword [rbp - 48]
    fstp tword [rsp + 32]
    call compute_log
    add  rsp, 48

    fstp tword [rbp - 16]
    fld1
    fld  tword [rbp - 16]
    fdivp

.epilogue:
    mov  rsp, rbp
    pop  rbp
    ret