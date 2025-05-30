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

	movw	$0, -70(%rbp)
	movw	$0, -72(%rbp)

	incq	%r8
	movzbl	(%r8), %edi
	cmpb	$'%', %dil
	jz	.fper_init

	cmpb	$'<', %dil
	jz	.format_ind

	cmpb	$'>', %dil
	jz	.format_ind

.format_1:
	cmpb	$'c', %dil
	jz	.fchr_init

	cmpb	$'s', %dil
	jz	.fstr_init

	cmpb	$'d', %dil
	jz	.fdec_init

	cmpb	$'x', %dil
	jz	.fhex_init

	cmpb	$'b', %dil
	jz	.fbin_init

	cmpb	$'o', %dil
	jz	.foct_init

	jmp	.fatal_1

.format_ind:
	movw	%di, -70(%rbp)
	GA
	movw	%r15w, -72(%rbp)
	incq	%r8
	movzbl	(%r8), %edi
	jmp	.format_1

#
# Percentage symbol formatting:
#
.fper_init:
.fper_loop:
.fper_term:
	movb	$'%', (%r9)
	incq	%r9
	incq	%r10
	jmp	.resume

#
# Character formatting:
#
.fchr_init:
	GA
.fchr_loop:
	movb	%r15b, (%r11)
	movq	$1, %r12
.fchr_term:
	jmp	.buf_trans

#
# String formatting:
#
.fstr_init:
	GA
	xorq	%rdi, %rdi
.fstr_loop:
	movzbl	(%r15), %edi
	cmpb	$0, %dil
	jz	.fstr_term
	movb	%dil, (%r11, %r12)
	incq	%r12
	incq	%r15
	jmp	.fstr_loop
.fstr_term:
	jmp	.buf_trans

#
# Decimal formatting:
#
.fdec_init:
	GA
	movq	%r15, %rax
	leaq	.BA(%rip), %r11
	addq	.BL(%rip), %r11
	decq	%r11
.fdec_loop:
	cmpq	$0, %rax
	jz	.fdec_term
	movq	$10, %rbx
	xorq	%rdx, %rdx
	divq	%rbx
	addb	$'0', %dl
	movb	%dl, (%r11)
	decq	%r11
	incq	%r12
	jmp	.fdec_loop
.fdec_term:
	incq	%r11
	jmp	.buf_trans

#
# Hexadecimal formatting:
#
.fhex_init:
	GA
	movq	%r15, %rax
	leaq	.BA(%rip), %r11
	addq	.BL(%rip), %r11
	decq	%r11
.fhex_loop:
	cmpq	$0, %rax
	jz	.fhex_term
	movq	$16, %rbx
	xorq	%rdx, %rdx
	divq	%rbx
	cmpq	$10, %rdx
	jl	.fhex_c1
	addb	$'7', %dl
	jmp	.fhex_put
.fhex_c1:
	addb	$'0', %dl
	jmp	.fhex_put
.fhex_put:
	movb	%dl, (%r11)
	decq	%r11
	incq	%r12
	jmp	.fhex_loop
.fhex_term:
	incq	%r11
	jmp	.buf_trans


#
# Binary formatting:
#
.fbin_init:
	GA
	movq	%r15, %rax
	leaq	.BA(%rip), %r11
	addq	.BL(%rip), %r11
	decq	%r11
.fbin_loop:
	cmpq	$0, %rax
	jz	.fbin_term
	movq	$2, %rbx
	xorq	%rdx, %rdx
	divq	%rbx
	addb	$'0', %dl
	movb	%dl, (%r11)
	decq	%r11
	incq	%r12
	jmp	.fbin_loop
.fbin_term:
	incq	%r11
	jmp	.buf_trans

#
# Octal formatting:
#
.foct_init:
	GA
	movq	%r15, %rax
	leaq	.BA(%rip), %r11
	addq	.BL(%rip), %r11
	decq	%r11
.foct_loop:
	cmpq	$0, %rax
	jz	.foct_term
	movq	$8, %rbx
	xorq	%rdx, %rdx
	divq	%rbx
	addb	$'0', %dl
	movb	%dl, (%r11)
	decq	%r11
	incq	%r12
	jmp	.foct_loop
.foct_term:
	incq	%r11
	jmp	.buf_trans


#
# Writing buffer argument into printable buffer:
#
.buf_trans:
	xorq	%rcx, %rcx
	xorq	%rax, %rax
	cmpw	$'>', -70(%rbp)
	jz	.buft_right_ind
	jmp	.buft_write
.buft_right_ind:
	movw	-72(%rbp), %bx
	subw	%r12w, %bx

	cmpw	$0, %bx
	jle	.buft_write					# TODO: debug

	leaq	.buft_write_init(%rip), %rcx
.buft_ind_cond:
	cmpw	$0, %bx
	jnz	.buft_ind_loop
	jmp	*%rcx
.buft_ind_loop:
	cmpq	.BL(%rip), %r10
	jz	.fatal_0
	movb	$' ', (%r9)
	incq	%r9
	incq	%r10
	decw	%bx
	jmp	.buft_ind_cond
.buft_write_init:
	xorq	%rcx, %rcx
.buft_write:
	cmpq	%rcx, %r12
	jz	.buft_write_term
	movb	(%r11, %rcx), %al
	movb	%al, (%r9)
	incq	%r9
	incq	%r10
	incq	%rcx
	jmp	.buft_write
.buft_write_term:
	cmpw	$'<', -70(%rbp)
	jnz	.resume
	movw	-72(%rbp), %bx
	subw	%r12w, %bx
	leaq	.resume(%rip), %rcx
	jmp	.buft_ind_cond

#
# Part of the main loop
#
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

#
# Error handling system:
#
.fatal_0:
	EX	$-1

.fatal_1:
	EX	$-2
