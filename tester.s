.section .rodata
	.fmt: .string "this is %c %% fmt\n"


.section .text

.globl _start

_start:
	pushq	$'a'
	leaq	.fmt(%rip), %rdi
	movq	$1, %rsi
	call	fpx86

	addq	$8, %rsp

	movq	$60, %rax
	movq	$60, %rdi
	syscall
