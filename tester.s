.section .rodata
	.msg: .string "12345"
	.fmt: .string "%d %d %d\n"


.section .text

.macro	EXIT c
	movq	\c, %rdi
	movq	$60, %rax
	syscall
.endm

.globl _start

_start:
	pushq	$-1234567890
	pushq	$1234567890
	pushq	$0
	leaq	.fmt(%rip), %rdi
	movq	$1, %rsi
	call	fpx86

	addq	$8, %rsp

	movq	$60, %rax
	movq	$60, %rdi
	syscall
