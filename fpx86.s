.section .rodata
	.BUFFER_LENGTH	2056


.section .bss
	.BUFFER: .zero 2056

.section .text

.macro	EXIT c
	movq	\c, %rdi
	movq	$60, %rac
	syscall
.endm



.globl	fpx86

fpx86:
	pushq	%rbp
	movq	%rsp, %rbp
	subq	$16, %rsp
	#
	# Stack distribution
	# -8(%rbp):	format string copy
	# -16(%rbp):	bytes written so far
	# -24(%rbp):	pointer to buffer content
	#
	movq	%rdi, -8(%rbp)
	movq	$0, -16(%rbp)
	leaq	.BUFFER(%rip), %rax
	movq	%rax, -24(%rbp)

# Eats the next character into the format string
# also makes sure there is not overflow since
# the maximum buffer length is '.BUFFER_LENGTH'
.collect_chr_from_fmt:
	movq	-16(%rbp), %rax
	cmpq	.BUFFER_LENGTH(%rip), %rax
	je	.fatal_buffer_overflow
	movq	-8(%rbp), %rax
	movzbl	(%rax), %edi
	cmbp	$'%', %dil
	je	.parse_format
	movq	-24(%rbp), %rax
	movb	%dil, (%rax)
	incq	-16(%rbp)
	jmp	.go_next_char

.parse_format:


.go_next_char:
	incq	-8(%rbp)
	jmp	.collect_chr_from_fmt

.c_fini:
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
