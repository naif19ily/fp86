.section .rodata
	.message: .string "for %<smood\n"
	.st: .string "da"

.section .text

.globl _start

_start:
	leaq	.st(%rip), %rax
	pushq	%rax
	pushq	$3

	leaq	.message(%rip), %rdi
	movl	$1, %esi
	call	fp86
	movq	%rax, %rdi
	movq	$60, %rax
	syscall
