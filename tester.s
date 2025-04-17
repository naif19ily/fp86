.section .rodata
	.fmt: .string "this is a fmt\n"


.section .text

.globl _start

_start:
	leaq	.fmt(%rip), %rdi
	movq	$1, %rsi
	call	fpx86

	movq	$60, %rax
	movq	$60, %rdi
	syscall
