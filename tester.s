.section .rodata
	.msg: .string "12345"
	.fmt: .string "this is %s %% fmt\n"


.section .text

.globl _start

_start:
	leaq	.msg(%rip), %rax
	pushq	%rax
	leaq	.fmt(%rip), %rdi
	movq	$1, %rsi
	call	fpx86

	addq	$8, %rsp

	movq	$60, %rax
	movq	$60, %rdi
	syscall
