.section .rodata
	.BUFFER_LENGTH: .quad 2056


.section .bss
	.BUFFER: .zero 2056

.section .text

.macro	EXIT c
	movq	\c, %rdi
	movq	$60, %rax
	syscall
.endm


#
# How to get the next argument:
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
.macro	GET_NEXT_ARG
	movq	-40(%rbp), %rax
	movq	$8, %rbx
	mulq	%rbx
	addq	$16, %rax
	movq	(%rbp, %rax, 1), %rax
.endm

.globl	fpx86

fpx86:
	pushq	%rbp
	movq	%rsp, %rbp
	subq	$40, %rsp
	#
	# Stack distribution
	# -8(%rbp):	format string copy
	# -16(%rbp):	bytes written so far
	# -24(%rbp):	pointer to buffer content
	# -32(%rbp):	fd to write
	# -40(%rbp):	number of args used
	#
	movq	%rdi, -8(%rbp)
	movq	$0, -16(%rbp)
	leaq	.BUFFER(%rip), %rax
	movq	%rax, -24(%rbp)
	movq	%rsi, -32(%rbp)
	movq	$0, -40(%rbp)

	GET_NEXT_ARG
	EXIT	%rax

# Eats the next character into the format string
# also makes sure there is not overflow since
# the maximum buffer length is '.BUFFER_LENGTH'
.collect_chr_from_fmt:
	movq	-16(%rbp), %rax
	cmpq	.BUFFER_LENGTH(%rip), %rax
	je	.fatal_buffer_overflow
	movq	-8(%rbp), %rax
	movzbl	(%rax), %edi
	cmpb	$0, %dil
	je	.c_fini
	cmpb	$'%', %dil
	je	.parse_format
	#
	# Stores the current character into the buffer
	# format: "this is a fmt"
	#          `---v
	#             +--+--+--+--+--+--+
	# buffer:     |t |  |  |  |  |  |
	#             +--+--+--+--+--+--+
	#              ^
	#
	movq	-24(%rbp), %rax
	movb	%dil, (%rax)
	incq	-16(%rbp)
	incq	-24(%rbp)
	jmp	.go_next_char

.parse_format:
	incq	-8(%rbp)
	movq	-8(%rbp), %rax
	movzbl	(%rax), %edi

	cmpb	$'c', %dil
	je	.parse_character

	cmpb	$'d', %dil
	je	.parse_integer



	cmpb	$'s', %dil
	je	.parse_string

.parse_character:

.parse_integer:

.parse_string:


.go_next_char:
	incq	-8(%rbp)
	jmp	.collect_chr_from_fmt

.c_fini:
	movq	$1, %rax
	movq	-32(%rbp), %rdi
	leaq	.BUFFER(%rip), %rsi
	movq	-16(%rbp), %rdx
	syscall

	movq	-16(%rbp), %rax
	leave
	ret

#  ________________
# < error messages >
#  ----------------
#         \   ^__^
#          \  (oo)\_______
#             (__)\       )\/\
#                 ||----w |
#                 ||     ||
.fatal_buffer_overflow:
	EXIT	$1
