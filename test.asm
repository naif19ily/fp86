.section .rodata
	.message: .string "0x%p\n"
	.st: .string "hola"

.section .text

.globl _start

_start:
	leaq	.st(%rip), %rax
	pushq	%rax

	leaq	.message(%rip), %rdi
	movl	$1, %esi
	call	fp86
	movq	%rax, %rdi
	movq	$60, %rax
	syscall
