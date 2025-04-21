.section .rodata
	.msg: .string "12345"
	.fmt: .string "%d\n"


.section .text

.macro	EXIT c
	movq	\c, %rdi
	movq	$60, %rax
	syscall
.endm

.globl _start

_start:
	pushq	$12
	leaq	.fmt(%rip), %rdi
	movq	$1, %rsi
	call	fpx86

	popq	%rax
	EXIT	%rax

	movq	$60, %rax
	movq	$60, %rdi
	syscall
