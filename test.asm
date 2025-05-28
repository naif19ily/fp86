.section .rodata
	.message: .string "simple string\n"

.section .text

.globl _start

_start:
	leaq	.message(%rip), %rdi
	movl	$1, %esi
	call	fp86
	movq	$60, %rax
	movq	$0, %rdi
	syscall
