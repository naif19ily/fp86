.section .rodata
	.message: .string "0o%o\n"
	.st: .string "hola"

.section .text

.globl _start

_start:

        pushq   $777

	leaq	.message(%rip), %rdi
	movl	$1, %esi
	call	fp86
	movq	%rax, %rdi
	movq	$60, %rax
	syscall
