.section .rodata
	.fmt: .string "this is a fmt\n"


.section .text

.globl _start

_start:
	pushq	$69
	leaq	.fmt(%rip), %rdi
	movq	$1, %rsi
	call	fpx86

	addq	$8, %rsp

	movq	$60, %rax
	movq	$60, %rdi
	syscall
