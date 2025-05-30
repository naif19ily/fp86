.section .rodata
	.message: .string "%s%c%d\n"
	.st: .string "hola"

.section .text

.globl _start

_start:

        pushq   $777

        pushq   $'s'

        leaq    .st(%rip), %rax
        pushq   %rax

	leaq	.message(%rip), %rdi
	movl	$1, %esi
	call	fp86
	movq	%rax, %rdi
	movq	$60, %rax
	syscall
