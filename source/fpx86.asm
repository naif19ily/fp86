#
#  _______ _______       _______ _______ 
# |   _   |   _   .--.--|   _   |   _   |
# |.  1___|.  1   |_   _|.  |   |   1___|
# |.  __) |.  ____|__.__|.  _   |.     \ 
# |:  |   |:  |         |:  1   |:  1   |
# |::.|   |::.|         |::.. . |::.. . |
# `---'   `---'         `-------`-------'
#
# Tiny implementation of `fprintf` funtion found
# in C programming language
#
# CC0-1.0 license
#

.section .bss
	.buffer: .zero 2048
	.numbuf: .zero 64

.section .rodata
	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ constants ~~~~~~~~~~~~~~~~~~ #
	.buffer_length: .quad 2048                                     #
	.numbuf_length: .quad 64                                       # 
	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ error messages ~~~~~~~~~~~~~ #
	.e_buf_overflow_msg: .string "\n  FPx86: buffer overflow\n\n"  #
	.e_buf_overflow_len: .quad 27                                  #
	                                                               #
	.e_unknown_format_msg: .string "\n  FPx86: unknown format\n\n" #
	.e_unknown_format_len: .quad 27                                #
	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

.section .text

.macro WRITER a, b
	leaq	\a, %rsi
	movq	\b, %rdx
	movq	$2, %rdi
	movq	$1, %rax
	syscall
.endm

.macro EXIT a
	movq	\a, %rdi
	movq	$60, %rax
	syscall
.endm

.macro GETARG
	movq	-28(%rbp), %rcx
	movq	(%rbp, %rcx), %r9
	addq	$8, -28(%rbp)
.endm

.macro PREFIX a
	movq	-20(%rbp), %rax
	addq	$2, %rax
	cmpq	.buffer_length(%rip), %rax
	jge	.__fatal__buffer_overflow
	movb	$'0', (%r8)
	incq	%r8
	incq	-20(%rbp)
	movb	\a, (%r8)
	incq	%r8
	incq	-20(%rbp)
.endm

.globl FPx86

FPx86:
	pushq	%rbp
	movq	%rsp, %rbp
	subq	$32, %rsp
	#
	# Stack disttibution
	#  -8: format string pointer
	# -12: file descriptor
	# -20: number of bytes written in buffer
	# -28: offset to next argument into stack
	#
	movq	%rdi, -8(%rbp)
	movl	%esi, -12(%rbp)
	movq	$0, -20(%rbp)
	#
	# R8 register is used to access the buffer, this is done
	# to improve performance
	#
	leaq	.buffer(%rip), %r8
	#
	# Variable starts with an offset of 16 bytes
	# in order to skip rbp and return address positions
	#
	movq	$16, -28(%rbp)
.__0_loop:
	movq	-20(%rbp), %rax
	cmpq	.buffer_length(%rip), %rax
	jz	.__fatal__buffer_overflow
	#
	# RAX is gonna hold the address of current
	# character begin read, the character itself
	# is going to be stored into RDI
	#
	movq	-8(%rbp), %rax
	movzbl	(%rax), %edi
	cmpb	$0, %dil
	jz	.__0_return
	cmpb	$'%', %dil
	jz	.__0_fmt_found
	#
	# If no format is found then the last character
	# read shall be stored into the buffer
	#
	movb	%dil, (%r8)
	incq	-20(%rbp)
	jmp	.__0_inc_and_continue
.__0_fmt_found:
	incq	-8(%rbp)
	movq	-8(%rbp), %rax
	movzbl	(%rax), %edi
	#
	# Parsing percentage (%)
	#
	cmpb	$'%', %dil
	jz	.__0_parse_per
	#
	# Parsing character (c)
	#
	cmpb	$'c', %dil
	jz	.__0_parse_chr
	#
	# Parsing string (s)
	#
	cmpb	$'s', %dil
	jz	.__0_parse_str
	cmpb	$'d', %dil
	jz	.__0_indicate_dec
	cmpb	$'b', %dil
	jz	.__0_indicate_bin
	cmpb	$'x', %dil
	jz	.__0_indicate_hex
	cmpb	$'o', %dil
	jz	.__0_indicate_oct
	jmp	.__fatal__unknown_format
.__0_parse_per:
	movb	$'%', (%r8)
	incq	-20(%rbp)
	jmp	.__0_inc_and_continue
.__0_parse_chr:
	GETARG
	movb	%r9b, (%r8)
	incq	-20(%rbp)
	jmp	.__0_inc_and_continue
.__0_parse_str:
	GETARG
	movq	-20(%rbp), %rcx
.__0_str_loop:
	#
	# Making sure there is not any buffer overflow
	#
	cmpq	.buffer_length(%rip), %rcx
	jz	.__fatal__buffer_overflow
	movzbl	(%r9), %edi
	cmpb	$0, %dil
	jz	.__0_str_fini
	movb	%dil, (%r8)
	incq	%r9
	incq	%r8
	incq	-20(%rbp)
	jmp	.__0_str_loop
.__0_str_fini:
	decq	%r8
	jmp	.__0_inc_and_continue
.__0_indicate_dec:
	jmp	.__0_parse_number
.__0_indicate_bin:
	PREFIX	$'b'
	jmp	.__0_parse_number
.__0_indicate_hex:
	PREFIX	$'x'
	jmp	.__0_parse_number
.__0_indicate_oct:
	PREFIX	$'o'
	jmp	.__0_parse_number
.__0_parse_number:
	GETARG
	cmpq	$0, %r9
	jz	.__0_num_zero
.__0_num_zero:
	movb	$'0', (%r8)
	incq	-20(%rbp)
	jmp	.__0_inc_and_continue

	
.__0_inc_and_continue:
	incq	%r8
	incq	-8(%rbp)
	jmp	.__0_loop

.__0_return:
	movq	-20(%rbp), %rdx
	leaq	.buffer(%rip), %rsi
	xorq	%rdi, %rdi
	movl	-12(%rbp), %edi
	movq	$1, %rax
	syscall
	#
	# TODO: clean and get ready for next call
	#
	movq	%rdx, %rax
	leave
	ret


.__fatal__buffer_overflow:
	WRITER	.e_buf_overflow_msg(%rip), .e_buf_overflow_len(%rip)
	EXIT	$-1
.__fatal__unknown_format:
	WRITER	.e_unknown_format_msg(%rip), .e_unknown_format_len(%rip)
	EXIT	$-1
