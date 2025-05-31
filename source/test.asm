#  ______  _____  _____   ____  
# |   ___||     |<  -  > /   /_ 
# |   ___||    _|/  _  \|   _  |
# |___|   |___|  \_____/|______|

.section .rodata
	.f1: .string "your name is: %>s\n"
	.f2: .string "your age is: %d 0x%x 0b%b 0o%o\n"

	.name: .string "Juan Diego Patino Munoz"

.section .text

.globl _start

_start:
	pushq	%rbp
	movq	%rsp, %rbp
	call	test1
	call	test2
	movq	$0, %rdi
	movq	$60, %rax
	syscall

test1:
	pushq	%rbp
	movq	%rsp, %rbp
	leaq	.name(%rip), %rax
	pushq	%rax
	pushq	$30
	leaq	.f1(%rip), %rdi
	movl	$1, %esi
	call	fp86
	addq	$16, %rsp
	leave
	ret

test2:
	pushq	%rbp
	movq	%rsp, %rbp
	pushq	$19
	pushq	$19
	pushq	$19
	pushq	$19
	leaq	.f2(%rip), %rdi
	movl	$1, %esi
	call	fp86
	addq	$16, %rsp
	leave
	ret
