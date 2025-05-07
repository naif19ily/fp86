#
#  _______ _______       _______ _______ 
# |   _   |   _   .--.--|   _   |   _   |
# |.  1___|.  1   |_   _|.  |   |   1___|
# |.  __) |.  ____|__.__|.  _   |.     \ 
# |:  |   |:  |         |:  1   |:  1   |
# |::.|   |::.|         |::.. . |::.. . |
# `---'   `---'         `-------`-------'
#

.section .bss
	.BUFFER: .zero 2048

.section .rodata
	.BUFFER_LENGTH: .quad 2048

	.DECSYSTEM:
		.quad 1
		.quad 10
		.quad 100

.section .text

#
# Makes copy of all registers
#
.macro SAVE_REGS_N
	movq	%r8,  -8(%rbp)
	movq	%r9,  -16(%rbp)
	movq	%r10, -24(%rbp)
	movq	%r11, -32(%rbp)
	movq	%r12, -40(%rbp)
	movq	%r13, -48(%rbp)
	movq	%r14, -56(%rbp)
	movq	%r15, -64(%rbp)
.endm

#
# Restore all registers to their previous values
#
.macro RESTORE_REGS_N
	movq	-8(%rbp),  %r8
	movq	-16(%rbp), %r9
	movq	-24(%rbp), %r10
	movq	-32(%rbp), %r11
	movq	-40(%rbp), %r12
	movq	-48(%rbp), %r13
	movq	-56(%rbp), %r14
	movq	-64(%rbp), %r15
.endm

#
# Exit syscall shortcut
#
.macro EXIT status
	movq	\status, %rdi
	movq	$60, %rax
	syscall
.endm

#
# Advances by one byte in the buffer
#
.macro ADVBUF
	incq	%r9
	incq	-72(%rbp)
.endm

#
# Gets the next argument pushed into the stack
#
.macro GETARG
	movq	-94(%rbp), %rax
	movq	(%rbp, %rax), %r10
	addq	$8, -94(%rbp)
.endm

.macro AINTBUFOV
	cmpq	.BUFFER_LENGTH(%rip), %rax
	jz	.__fatal_buf_overflow
.endm

.globl __fpx86

__fpx86:
	pushq	%rbp
	movq	%rsp, %rbp
	subq	$94, %rsp
	# This function make use of all r8, ..., r15 regs
	SAVE_REGS_N
	#
	# Local variables:
	#  -72: number of bytes written in buffer
	#  -76: file descriptor
	#  -78: type of justificaion (either < or >)
	#  -86: padding number
	#  -94: stack offset
	#
	movq	$0, -72(%rbp)
	movl	%esi, -76(%rbp)
	# R8: pointer to the current byte in fmt string
	# R9: pointer to the current byte in buffer
	movq	%rdi, %r8
	leaq	.BUFFER(%rip), %r9
	# -*-*-
	movq	$16, -94(%rbp)
	# -*-*-
	xorq	%rdi, %rdi
	xorq	%rsi, %rsi
.__0_loop:
	# Checking there's not any buffer overflow
	movq	-72(%rbp), %rax
	AINTBUFOV
	# Formats are given via % sign, whenever a % is found
	# it means there's a formatting
	movzbl	(%r8), %edi
	cmpb	$0, %dil
	jz	.__0_fini
	# -*-*-
	cmpb	$'%', %dil
	jz	.__0_format_found
	# -*-*-
	movb	%dil, (%r9)
	ADVBUF
	jmp	.__0_continue
.__0_format_found:
	# if the program hits this point r8 will be pointing to %
	# the program needs what comes after that
	incq	%r8
	movzbl	(%r8), %edi
	# -*-*-
	cmp	$'%', %dil
	jz	.__0_fmt_per
	# -*-*-
	cmp	$'<', %dil
	jz	.__0_fmt_jutify
	# -*-*-
	cmp	$'>', %dil
	jz	.__0_fmt_jutify
	# -*-*-
	cmp	$'c', %dil
	jz	.__0_fmt_char
	# -*-*-
	jmp	.__fatal_unknown_buf
.__0_fmt_per:
	# formatting % is like adding any other character, it's
	# just a special one...
	movb	$'%', (%r9)
	ADVBUF
	jmp	.__0_continue
.__0_fmt_jutify:
	# setting justification type
	movb	%dil, -78(%rbp)
	call	.__fx_get_justif_number
	movq	%rax, -86(%rbp)
	decq	%r8
	jmp	.__0_format_found
.__0_fmt_char:
	GETARG
	leaq	(%r10), %r10
	movq	$-1, %rdi
	leaq	-72(%rbp), %rsi
	call	.__fx_write_argument

.__0_continue:
	incq	%r8
	jmp	.__0_loop
.__0_fini:
	# Printing the final buffer via write syscall, how else?
	movq	-72(%rbp), %rdx
	leaq	.BUFFER(%rip), %rsi
	xorq	%rdi, %rdi
	movl	-76(%rbp), %edi
	movq	$1, %rax
	syscall
	# Restore the original values of r8, ..., r15
	RESTORE_REGS_N
	movq	%rdx, %rax
	leave
	ret

# function
#
#
#
#
.__fx_get_justif_number:
	pushq	%rbp
	movq	%rsp, %rbp
	subq	$16, %rsp
	#
	# Local variables:
	#   -8: return value
	#  -16: number's length (bytes ran)
	#
	movq	$0, -8(%rbp)
	movq	$0, -16(%rbp)
	# -*-*-
	incq	%r8
	movzbl	(%r8), %edi
	# if justificaion is given via stack, it is specified
	# by giving a * instead of a raw number
	cmpb	$'*', %dil
	jz	.__1_given_via_stack
.__1_loop:
	cmpq	$4, -16(%rbp)
	jz	.__fatal_justify_overfow
	# Getting character with an offset of -16(%rbp) since the first
	# number found
	movq	%r8, %rax
	addq	-16(%rbp), %rax
	movzbl	(%rax), %edi
	# -*-*-
	cmpb	$'0', %dil
	jl	.__1_num_fini
	cmpb	$'9', %dil
	jg	.__1_num_fini
	incq	-16(%rbp)
	jmp	.__1_loop
.__1_num_fini:
	# rdi is gonna be used to go through the number
	movq	%r8, %rdi
	# Update r8 to the new position (after whole number)
	addq	-16(%rbp), %r8
	leaq	.DECSYSTEM(%rip), %r10
	decq	-16(%rbp)
.__1_build_number:
	cmpq	$-1, -16(%rbp)
	jz	.__1_fini
	# getting the nth 10's power (RBX)
	movq	-16(%rbp), %rax
	movq	(%r10, %rax, 8), %rbx
	# getting the nths digit's number
	xorq	%rax, %rax
	movzbl	(%rdi), %eax
	cltq
	subq	$'0', %rax
	# -*-*-
	mulq	%rbx
	# building the number
	addq	%rax, -8(%rbp)
	# -*-*-
	incq	%rdi
	decq	-16(%rbp)
	jmp	.__1_build_number
.__1_given_via_stack:
	movq	$-1, %rax
	leave
	ret
.__1_fini:
	xorq	%r10, %r10
	movq	-8(%rbp), %rax
	leave
	ret

# function
#
#
#
#
.__fx_write_argument:
	pushq	%rbp
	movq	%rsp, %rbp
	subq	$16, %rsp
	# -*-*-
	movq	%rdi, -8(%rbp)
	movq	$0, -16(%rbp)
	# -*-*-
	cmpq	$-1, %rdi
	jz	.__2_is_char
	# RSI register is a pointer to the number of bytes
	# written in the buffer so far
	jmp	.__2_loop
.__2_is_char:
	# character arguments must be different handled since
	# a character does hot have an actual address, it is
	# just a value
	movq	(%rsi), %rax
	AINTBUFOV
	movb	%r10b, %al
	movb	%al, (%r9)
	incq	%r9
	incq	(%rsi)
	jmp	.__2_fini
.__2_loop:
	# argument also has a length which we have to respect
	movq	-16(%rbp), %rax
	cmpq	-8(%rbp), %rax
	jz	.__2_fini
	# -*-*-
	movq	(%rsi), %rax
	AINTBUFOV
	# -*-*-
	xorq	%rax, %rax
	movb	(%r10), %al
	movb	%al, (%r9)
	# -*-*-
	incq	%r9
	incq	(%rsi)
	incq	-16(%rbp)
	# -*-*-
	jmp	.__2_loop
.__2_fini:
	leave
	ret
	


.__fatal_buf_overflow:
	EXIT	$69
.__fatal_unknown_buf:
	EXIT	$70
.__fatal_justify_overfow:
	EXIT	$71
