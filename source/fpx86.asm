#
#  _______ _______       _______ _______ 
# |   _   |   _   .--.--|   _   |   _   |
# |.  1___|.  1   |_   _|.  |   |   1___|
# |.  __) |.  ____|__.__|.  _   |.     \ 
# |:  |   |:  |         |:  1   |:  1   |
# |::.|   |::.|         |::.. . |::.. . |
# `---'   `---'         `-------`-------'
#
.section .rodata
	.BufferSize: .quad 2048

	.DecSys:
		.quad 1
		.quad 10
		.quad 100

.section .bss
	.Buffer: .zero 2048

.section .text

.macro EXIT status
	movq	\status, %rdi
	movq	$60, %rax
	syscall
.endm

.macro GETARG
	movq	-20(%rbp), %rax
	movq	(%rbp, %rax), %r9
	addq	$8, -20(%rbp)
.endm

.globl FPx86

FPx86:
	pushq	%rbp
	movq	%rsp, %rbp
	subq	$64, %rsp
	#
	# Stack distribution
	#  -8: format string
	# -12: file descriptor
	# -20: offset from rbp
	# -28: number of bytes written
	# -30: justify flag (< left & > right)
	# -32: padding number
	#
	movq	%rdi, -8(%rbp)
	movl	%esi, -12(%rbp)
	movq	$16,  -20(%rbp)
	movq	$0,   -28(%rbp)
	movw	$0,   -30(%rbp)
	movw	$0,   -32(%rbp)
	#
	# R8 is going to work as a pointer to the
	# location within the buffer where we can
	# write the next character.
	#
	leaq	.Buffer(%rip), %r8
	#
	# Making sure string provided is not NULL
	#
	cmpq	$0, %rdi
	jz	.__error_null_string
	xorq	%rdi, %rdi

.__1_main_loop:
	#
	# Making sure there's still space enough
	# to keep writing into the buffer
	#
	movq	-28(%rbp), %rax
	cmpq	.BufferSize(%rip), %rax
	jz	.__error_buffer_overflow
	# -*-
	movq	-8(%rbp), %rax
	movzbl	(%rax), %edi
	cmpb	$0, %dil
	jz	.__1_return
	# -*-
	cmpb	$'%', %dil
	jz	.__1_format_found
	# -*-
	movb	%dil, (%r8)
	incq	-28(%rbp)
	jmp	.__1_continue

.__1_format_found:
	#
	# The format indicator is right after the % symbol, therefore
	# we need to go one character further to get it
	#
	incq	-8(%rbp)
.__1_format_found_but_what:
	movq	-8(%rbp), %rax
	movzbl	(%rax), %edi
	# -*-
	cmpb	$'%', %dil
	jz	.__1_format_percentage
	# -*-
	cmpb	$'<', %dil
	jz	.__1_format_justify
	# -*-
	cmpb	$'>', %dil
	jz	.__1_format_justify
	# -*-
	cmpb	$'c', %dil
	jz	.__1_format_character

	jmp	.__error_unknonwn_format

.__1_format_percentage:
	movb	$'%', (%r8)
	incq	-28(%rbp)
	jmp	.__1_continue

.__1_format_justify:
	movw	%di, -30(%rbp)
	#
	# When the program gets here, the current character being
	# read is < or >, after that is the justify number (what we want)
	#
	incq	-8(%rbp)
	movq	-8(%rbp), %rdi
	call	.__fx_get_just_num
	movw	%ax, -32(%rbp)
	addq	%rcx, -8(%rbp)
	jmp	.__1_format_found_but_what

.__1_format_character:
	GETARG
	movb	%r9b, (%r8)
	incq	-28(%rbp)
	jmp	.__1_continue
	# XXX: here!

.__1_continue:
	#
	# Prepares the next character to be read into -8(%rbp) (formatted string)
	# and go to next byte into buffer to be written (R8)
	#
	incq	-8(%rbp)
	incq	%r8
	#
	# Formating justify flag
	#
	movw	$0, -32(%rbp)
	jmp	.__1_main_loop

.__1_return:
	movq	-28(%rbp), %rdx
	xorq	%rdi, %rdi
	movl	-12(%rbp), %edi
	leaq	.Buffer(%rip), %rsi
	movq	$1, %rax
	syscall

	movq	%rdx, %rax
	leave
	ret

.__fx_get_just_num:
	pushq	%rbp
	movq	%rsp, %rbp
	subq	$16, %rsp
	#
	# Stack distribution
	#  -8: number of bytes ran
	# -16: jutify number (return value)
	#
	movq	$0, -8(%rbp)
	movq	$0, -16(%rbp)
	#
	# Padding can also be given via stack
	#
	xorq	%rax, %rax
	movzbl	(%rdi), %eax
	cmpb	$'*', %al
	jz	.__2_was_pushed
.__2_loop:
	#
	# No fucking way you're gonna have
	# a padding of 256+ bytes
	#
	movq	-8(%rbp), %rcx
	cmpq	$4, %rcx
	jz	.__error_huge_justify
	# -*-
	movzbl	(%rdi), %eax
	cmpb	$'0', %al
	jl	.__2_nonumber
	cmpb	$'9', %al
	jg	.__2_nonumber
	# -*-
	incq	-8(%rbp)
	incq	%rdi
	jmp	.__2_loop
.__2_nonumber:
	movq	-8(%rbp), %rax
	#
	# Setting back rdi to where numbers start
	#
	subq	%rax, %rdi
	#
	# Setting the -16(%rbp)th 10 power
	#
	decq	%rax
	movq	$8, %rbx
	mulq	%rbx
	leaq	.DecSys(%rip), %r9
	addq	%rax, %r9
	# -*-
	xorq	%rcx, %rcx
	xorq	%rax, %rax
.__2_build_num:
	cmpq	-8(%rbp), %rcx
	jz	.__2_return
	# -*-
	movzbl	(%rdi), %eax
	cltq
	subq	$'0', %rax
	movq	(%r9), %rbx
	mulq	%rbx
	addq	%rax, -16(%rbp)
	subq	$8, %r9
	incq	%rcx
	incq	%rdi
	jmp	.__2_build_num
.__2_was_pushed:
	movq	$-1, %rax
	leave
	ret
.__2_return:
	movq	-16(%rbp), %rax
	movq	-8(%rbp),  %rcx
	leave
	ret

# %>2s
# " 4"
# 
# %<2s
# "4 "











.__error_null_string:
	EXIT	$-1
.__error_buffer_overflow:
	EXIT	$-2
.__error_unknonwn_format:
	EXIT	$-3
.__error_huge_justify:
	EXIT	$-4
