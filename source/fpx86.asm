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

.section .text

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

.macro EXIT status
	movq	\status, %rdi
	movq	$60, %rax
	syscall
.endm

.macro ADVBUF
	incq	%r9
	incq	-72(%rbp)
.endm

.globl __fpx86

__fpx86:
	pushq	%rbp
	movq	%rsp, %rbp
	subq	$76, %rsp
	# This function make use of all r8, ..., r15 regs
	SAVE_REGS_N
	#
	# Local variables:
	#  -72: number of bytes written in buffer
	#  -76: file descriptor
	#  -78: type of justificaion (either < or >)
	#
	movq	$0, -72(%rbp)
	movl	%esi, -76(%rbp)
	# R8: pointer to the current byte in fmt string
	# R9: pointer to the current byte in buffer
	movq	%rdi, %r8
	leaq	.BUFFER(%rip), %r9
	# -*-*-
	xorq	%rdi, %rdi
	xorq	%rsi, %rsi
.__0_loop:
	# Checking there's not any buffer overflow
	movq	-72(%rbp), %rax
	cmpq	.BUFFER_LENGTH(%rip), %rax
	jz	.__fatal_buf_overflow
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


	jmp	.__fatal_unknown_buf
.__0_fmt_per:
	# formatting % is like adding any other character, it's
	# just a special one...
	movb	$'%', (%r9)
	ADVBUF
	jmp	.__0_continue
.__0_fmt_jutify:
	movb	%dil, -78(%rbp)
	call	.__fx_get_justif_number

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

.__fx_get_justif_number:
	pushq	%rbp
	movq	%rsp, %rbp
	subq	$8, %rsp
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
	EXIT	-16(%rbp)

.__1_given_via_stack:
	movq	$-1, %rax
	leave
	ret
.__1_fini:
	movq	-8(%rbp), %rax
	leave
	ret


.__fatal_buf_overflow:
	EXIT	$-1
.__fatal_unknown_buf:
	EXIT	$-2
