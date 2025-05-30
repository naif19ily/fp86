.section .rodata
	.message: .string "0x%x\n"
	.st: .string "hola"

.section .text

.globl _start

_start:

        pushq   $15

	leaq	.message(%rip), %rdi
	movl	$1, %esi
	call	fp86
	movq	%rax, %rdi
	movq	$60, %rax
	syscall
