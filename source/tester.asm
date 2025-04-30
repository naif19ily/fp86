.section .rodata
        .fmt: .string "simple string printing\n"

.section .text

.globl _start

_start:
        pushq   %rbp
        movq    %rsp, %rbp

        leaq    .fmt(%rip), %rdi
        movl    $1, %esi
        call    fpx86


	movq	$0, %rdi
	movq	$60, %rax
	syscall
