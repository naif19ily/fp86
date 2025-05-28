.section .rodata
	.message: .string "1%c3\n"

.section .text

.globl _start

_start:
	
	pushq	$'2'

	leaq	.message(%rip), %rdi
	movl	$1, %esi
	call	fp86
	movq	%rax, %rdi
	movq	$60, %rax
	syscall
