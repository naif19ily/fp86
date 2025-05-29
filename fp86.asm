.section .rodata
	.BL: .quad 2048

.section .bss
	.BF: .zero 2048
	.BA: .zero 2048

.section .text

.macro EX status
	movq	\status, %rdi
	movq	$60, %rax
	syscall
.endm

.macro SR
	movq	%r8 , -8(%rbp)
	movq	%r9 , -16(%rbp)
	movq	%r10, -24(%rbp)
	movq	%r11, -32(%rbp)
	movq	%r12, -40(%rbp)
	movq	%r13, -48(%rbp)
	movq	%r14, -56(%rbp)
	movq	%r15, -64(%rbp)
.endm

.macro BR
	movq	-8(%rbp) , %r8
	movq	-16(%rbp), %r9
	movq	-24(%rbp), %r10
	movq	-32(%rbp), %r11
	movq	-40(%rbp), %r12
	movq	-48(%rbp), %r13
	movq	-56(%rbp), %r14
	movq	-64(%rbp), %r15
.endm

.macro GA
	movq	-80(%rbp), %rax
	movq	(%rbp, %rax), %r15
	addq	$8, -80(%rbp)
.endm

.globl fp86

fp86:
	pushq	%rbp
	movq	%rsp, %rbp
	subq	$80, %rsp
	SR

	movq	%rdi, %r8					# format string's placeholder
	leaq	.BF(%rip), %r9					# buffer's placeholder
	movq	$0, %r10					# number of bytes written
	movl	%esi, -68(%rbp)					# file descriptor given
	movw	$0, -70(%rbp)					# indentation-kind (< or >)
	movw	$0, -72(%rbp)					# indentation width
	movq	$16, -80(%rbp)					# next argument's offset to rbp
	leaq	.BA(%rip), %r11					# argument buffer's placeholder
	movq	$0, %r12					# argument's length

	xorq	%rax, %rax
	xorq	%rdi, %rdi
	xorq	%rsi, %rsi

.loop:
	cmpb	$0, (%r8)
	jz	.fini
	movzbl	(%r8), %edi

	cmpq	.BL(%rip), %r10
	jz	.fatal_0

	cmpb	$'%', %dil
	jz	.format_0

	movb	%dil, (%r9)
	incq	%r9
	incq	%r10
	jmp	.resume

.format_0:
	leaq	.BA(%rip), %r11
	movq	$0, %r12

	incq	%r8
	movzbl	(%r8), %edi
	cmpb	$'%', %dil
	jz	.format_per

	cmpb	$'<', %dil
	jz	.format_ind

	cmpb	$'>', %dil
	jz	.format_ind

.format_1:
	cmpb	$'c', %dil
	jz	.format_chr

	jmp	.fatal_1

.format_ind:
	movw	%di, -70(%rbp)
	GA
	movw	%r15w, -72(%rbp)
	incq	%r8
	movzbl	(%r8), %edi
	jmp	.format_1

.format_per:
	movb	$'%', (%r9)
	incq	%r9
	incq	%r10
	jmp	.resume

.format_chr:
	GA
	movb	%r15b, (%r11)
	movq	$1, %r12
	jmp	.write_ba

.write_ba:
	xorq	%rcx, %rcx
	xorq	%rax, %rax

	cmpw	$0, -70(%rbp)
	jz	.write_arg

	cmpw	$'>', -70(%rbp)
	jz	.indent_r

	jmp	.write_arg

.indent_r:
	movw	-72(%rbp), %bx
	subw	%r12w, %bx
	js	.write_arg					# TODO: debug
	leaq	.write_arg(%rip), %rcx

.indentation:							# TODO: check bounds
	cmpw	$0, %bx
	jnz	.indentation_s
	jmp	*%rcx

.indentation_s:
	movb	$' ', (%r9)
	incq	%r9
	incq	%r10
	decw	%bx
	jmp	.indentation
	
.write_arg:
	cmpq	%rcx, %r12
	jz	.warg_final

	movb	(%r11), %al
	movb	%al, (%r9)

	incq	%r9
	incq	%r10

	incq	%rcx
	jmp	.write_arg

.warg_final:
	cmpw	$'<', -70(%rbp)
	jnz	.resume

	movw	-72(%rbp), %bx
	subw	%r12w, %bx
	leaq	.resume(%rip), %rcx
	jmp	.indentation

.resume:
	incq	%r8
	jmp	.loop

.fini:
	movq	$1, %rax
	xorq	%rdi, %rdi
	movl	-68(%rbp), %edi
	leaq	.BF(%rip), %rsi
	movq	%r10, %rdx
	syscall

	movq	%r10, %rax
	BR
	leave
	ret

.fatal_0:
	EX	$-1

.fatal_1:
	EX	$-2
