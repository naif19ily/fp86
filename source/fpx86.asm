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

.section .rodata
	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ max buffer size ~~~~~~~~~~~~ #
	.buffer_length: .quad 2048                                     #
	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ error messages ~~~~~~~~~~~~~ #
	.e_buf_overflow_msg: .string "\n  FPx86: buffer overflow\n\n"  #
	.e_buf_overflow_len: .quad 27                                  #
	                                                               #
	.e_unknown_format_msg: .string "\n  FPx86: unknown format\n\n" #
	.e_unknown_format_len: .quad 27                                #
	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

.section .text

.macro EXIT a
	movq	\a, %rdi
	movq	$60, %rax
	syscall
.endm

.macro FATAL a, b
	movq	$1, %rax
	movq	$2, %rdi
	leaq	\a, %rsi
	movq	\b, %rdx
	syscall
.endm

.macro GETARG
	movq	-36(%rbp), %rcx
	movq	(%rbp, %rcx), %r9
	addq	$8, -36(%rbp)
.endm


.globl FPx86

FPx86:
	pushq	%rbp
	movq	%rsp, %rbp
	subq	$64, %rsp
	#
	# Stack distribution
	#  -8: format string pointer
	# -16: buffer pointer
	# -20: file descriptor
	# -28: number of bytes used in buffer
	# -36: stack offset (to get the next argument previously pushed into the stack)
	#
	movq	%rdi, -8(%rbp)
	leaq	.buffer(%rip), %rax
	movq	%rax, -16(%rbp)
	movl	%esi, -20(%rbp)
	movq	$0, -28(%rbp)
	movq	$16, -36(%rbp)
.__0_loop:
	movq	-28(%rbp), %rax
	cmpq	.buffer_length(%rip), %rax
	je	.e_buffer_overflow
	movq	-8(%rbp), %rax
	movzbl	(%rax), %edi
	cmpb	$0, %dil
	jz	.__0_return
	cmpb	$'%', %dil
	jz	.__0_fmt_found
	movq	-16(%rbp), %rax
	movb	%dil, (%rax)
	incq	-28(%rbp)
	jmp	.__0_continue
.__0_fmt_found:
	incq	-8(%rbp)
	movq	-8(%rbp), %rax
	movzbl	(%rax), %edi
	cmpb	$'%', %dil
	jz	.__0_fmt_is_per
	cmpb	$'c', %dil
	jz	.__0_fmt_is_chr
	cmpb	$'s', %dil
	jz	.__0_fmt_is_str
	jmp	.e_unknown_fmt


#  _________________________
# < Parsing percentage sign >
#  -------------------------
#         \   ^__^
#          \  (oo)\_______
#             (__)\       )\/\
#                 ||----w |
#                 ||     ||
.__0_fmt_is_per:
	movq	-16(%rbp), %r8
	movb	$'%', (%r8)
	incq	-28(%rbp)
	jmp	.__0_continue

#  _________________________
# <      Parsing chars      >
#  -------------------------
#         \   ^__^
#          \  (oo)\_______
#             (__)\       )\/\
#                 ||----w |
#                 ||     ||
.__0_fmt_is_chr:
	GETARG
	movq	-16(%rbp), %r8
	movb	%r9b, (%r8)
	incq	-28(%rbp)
	jmp	.__0_continue

#  _________________________
# <      Parsing strgs      >
#  -------------------------
#         \   ^__^
#          \  (oo)\_______
#             (__)\       )\/\
#                 ||----w |
#                 ||     ||
.__0_fmt_is_str:
	GETARG
.__0_fmt_str_loop:
	movzbl	(%r9), %edi
	cmpb	$0, %dil
	jz	.__0_fmt_str_fini
	movq	-16(%rbp), %rax
	movb	%dil, (%rax)
	incq	-28(%rbp)
	incq	-16(%rbp)
	incq	%r9
	jmp	.__0_fmt_str_loop
.__0_fmt_str_fini:
	decq	-16(%rbp)
	jmp	.__0_continue

.__0_continue:
	incq	-8(%rbp)
	incq	-16(%rbp)
	jmp	.__0_loop

.__0_return:
	movq	-28(%rbp), %rdx
	leaq	.buffer(%rip), %rsi
	xorq	%rdi, %rdi
	movl	-20(%rbp), %edi
	movq	$1, %rax
	syscall
	movq	%rdx, %rax
	leave
	ret

.e_buffer_overflow:
	FATAL	.e_buf_overflow_msg(%rip), .e_buf_overflow_len(%rip)
	EXIT	$-1

.e_unknown_fmt:
	FATAL	.e_unknown_format_msg(%rip), .e_unknown_format_len(%rip)
	EXIT	$-2
