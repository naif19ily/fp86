#  ______  _____  _____   ____  
# |   ___||     |<  -  > /   /_ 
# |   ___||    _|/  _  \|   _  |
# |___|   |___|  \_____/|______|

.section .rodata
	.BL: .quad 2048

	.TRUE: .string  "TRUE"
	.FALSE: .string "FALSE"

	.TL: .quad 4
	.FL: .quad 5

	.f1: .string "\n\tfp86: fatal: buffer overflow, maximum is 4096 bytes per call.\n\n"
	.f1l: .quad 65

	.f2: .string "\n\tfp86: fatal: unknown formatting type, check docs.\n\n"
	.f2l: .quad 53

.section .bss
	.BF: .zero 2048
	.BA: .zero 2048

.section .text

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

.macro ER msg, len, status
	movq	$1, %rax
	movq	$2, %rdi
	leaq	\msg, %rsi
	movq	\len, %rdx
	syscall
	movq	\status, %rdi
	movq	$60, %rax
	syscall
.endm

.globl fp86

fp86:
	pushq	%rbp
	movq	%rsp, %rbp
	subq	$88, %rsp
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
	movw	$0, -82(%rbp)					# flag to know if a number is negative
	xorq	%rax, %rax
	xorq	%rdi, %rdi
	xorq	%rsi, %rsi
.loop:
	cmpb	$0, (%r8)
	jz	.print
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
	cmpb	$'x', %dil
	jz	.fhex_init
	cmpb	$'d', %dil
	jz	.fdec_init
	cmpb	$'b', %dil
	jz	.fbin_init
	cmpb	$'o', %dil
	jz	.foct_init
	cmpb	$'B', %dil
	jz	.fbol_init
	cmpb	$'p', %dil
	jz	.fhex_init
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
# Decimal, Binary and Octal formatting:
#
.fdec_init:
	movq	$10, %rbx
	jmp	.fdbo_init
.fbin_init:
	movq	$2, %rbx
	jmp	.fdbo_init
.foct_init:
	movq	$8, %rbx
.fdbo_init:
	GA
	cmpq	$0, %r15
	jz	.fbdo_zero
	jl	.fbdo_neg
	jmp	.fbdo_keep
.fbdo_zero:
	movb	$'0', (%r11)
	movq	$1, %r12
	jmp	.buf_trans
.fbdo_neg:
	movw	$1, -82(%rbp)
	negq	%r15
.fbdo_keep:
	movq	%r15, %rax
	leaq	.BA(%rip), %r11
	addq	.BL(%rip), %r11
	decq	%r11
.fdbo_loop:
	cmpq	$0, %rax
	jz	.fdbo_term
	xorq	%rdx, %rdx
	divq	%rbx
	addb	$'0', %dl
	movb	%dl, (%r11)
	decq	%r11
	incq	%r12
	jmp	.fdbo_loop
.fdbo_term:
	incq	%r11
	jmp	.buf_trans

#
# Hexadecimal formatting:
#
.fhex_init:
	GA
	cmpq	$0, %r15
	jz	.fhex_zero
	jl	.fhex_neg
	jmp	.fhex_keep
.fhex_zero:
	movb	$'0', (%r11)
	movq	$1, %r12
	jmp	.buf_trans
.fhex_neg:
	movw	$1, -82(%rbp)
	negq	%r15
.fhex_keep:
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
# Boolean formatting:
#
.fbol_init:
	GA
	cmpq	$0, %r15
	jz	.fbol_false
	leaq	.TRUE(%rip), %r11
	movq	.TL(%rip), %r12
	jmp	.buf_trans
.fbol_false:
	leaq	.FALSE(%rip), %r11
	movq	.FL(%rip), %r12
	jmp	.buf_trans

#
# Writing buffer argument into printable buffer:
#
.buf_trans:
	xorq	%rcx, %rcx
	xorq	%rax, %rax
	cmpw	$'>', -70(%rbp)
	jz	.buft_right_ind
	jmp	.buft_write_init
.buft_right_ind:
	movw	-72(%rbp), %bx
	subw	%r12w, %bx
	cmpw	$0, %bx
	jle	.buft_write
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
	cmpw	$1, -82(%rbp)
	jnz	.buft_write
	movb	$'-', (%r9)
	incq	%r10
	incq	%r9
	movb	$0, -82(%rbp)
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
.print:
	movq	$1, %rax
	xorq	%rdi, %rdi
	movl	-68(%rbp), %edi
	leaq	.BF(%rip), %rsi
	movq	%r10, %rdx
	syscall
	movq	%r10, %rax
.fini:
	BR
	leave
	ret

#
# Error handling system:
#
.fatal_0:
	ER	.f1(%rip), .f1l(%rip), $1

.fatal_1:
	ER	.f2(%rip), .f2l(%rip), $1
