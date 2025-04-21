.section .rodata
	.BUFFER_LENGTH: .quad 2056
	.NUMBUF_LENGTH: .quad   16

	.err1m: .string "\n  fpx86: fatal error: buffer overflow detected — the string provided exceeds the allowed size\n\n"
	.err1l: .quad   99

	.err2m: .string "\n  fpx86: fatal error: unknown printing format — ensure all format specifiers are valid and supported\n\n"
	.err2l: .quad   105

	.err3m: .string "\n  fpx86: fatal error: numeric overflow — the value given exceeds the representable range for this type\n\n"
	.err3l: .quad   106

.section .bss
	.BUFFER: .zero 2056
	.NUMBUF: .zero   16

.section .text

.macro	EXIT c
	movq	\c, %rdi
	movq	$60, %rax
	syscall
.endm

.macro	ADVANCE_BY_ONE_IN_BUFFER
	incq	-16(%rbp)
	incq	-24(%rbp)
.endm

.macro	GET_NEXT_ARG__R8
	movq	-40(%rbp), %rax
	movq	$8, %rbx
	mulq	%rbx
	addq	$16, %rax
	movq	(%rbp, %rax, 1), %r8
.endm

.macro	CHECK_BUFFER_SPACE
	movq	-16(%rbp), %rax
	cmpq	.BUFFER_LENGTH(%rip), %rax
	je	.fatal_buffer_overflow
.endm

.macro	ERRMSG a, b
	movq	$1, %rax
	movq	$2, %rdi
	leaq	\a, %rsi
	movq	\b, %rdx
	syscall
.endm

.globl	fpx86

fpx86:
	pushq	%rbp
	movq	%rsp, %rbp
	subq	$48, %rsp
	#
	# Stack distribution
	# -8(%rbp):	format string copy
	# -16(%rbp):	bytes written so far
	# -24(%rbp):	pointer to buffer content
	# -32(%rbp):	fd to write
	# -40(%rbp):	number of args used
	# -48(%rbp):    nubuf position
	#
	movq	%rdi, -8(%rbp)
	movq	$0, -16(%rbp)
	leaq	.BUFFER(%rip), %rax
	movq	%rax, -24(%rbp)
	movq	%rsi, -32(%rbp)
	movq	$0, -40(%rbp)
	movq	$0, -48(%rbp)

# Eats the next character into the format string
# also makes sure there is not overflow since
# the maximum buffer length is '.BUFFER_LENGTH'
.collect_chr_from_fmt:
	CHECK_BUFFER_SPACE
	movq	-8(%rbp), %rax
	movzbl	(%rax), %edi
	cmpb	$0, %dil
	je	.print_and_clean
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
	ADVANCE_BY_ONE_IN_BUFFER
	jmp	.go_next_char

.parse_format:
	GET_NEXT_ARG__R8
	incq	-40(%rbp)
	incq	-8(%rbp)
	movq	-8(%rbp), %rax
	movzbl	(%rax), %edi
	cmpb	$'c', %dil
	je	.parse_character
	cmpb	$'d', %dil
	je	.parse_integer
	cmpb	$'s', %dil
	je	.parse_string
	cmpb	$'%', %dil
	je	.parse_percentage
	jmp	.fatal_unknown_format

.parse_character:
	movq	-24(%rbp), %rax
	movb	%r8b, (%rax)
	ADVANCE_BY_ONE_IN_BUFFER
	jmp	.go_next_char

.parse_integer:
	cmpq	$0, %r8
	jl	.parse_integer_add_neg
	cmpq	$0, %r8
	jg	.parse_integer_loop
	movq	-24(%rbp), %rax
	movb	$'0', (%rax)
	ADVANCE_BY_ONE_IN_BUFFER
	jmp	.go_next_char

.parse_integer_add_neg:
	movq	-24(%rbp), %rax
	movb	$'-', (%rax)
	negq	%r8
	ADVANCE_BY_ONE_IN_BUFFER

.parse_integer_loop:
	cmpq	$0, %r8
	je	.parse_integer_fully_parsed
	movq	.NUMBUF_LENGTH(%rip), %rax
	cmpq	%rax, -48(%rbp)
	je	.fatal_number_overflow
	movq	%r8, %rax
	movq	$10, %rbx
	xorq	%rdx, %rdx
	divq	%rbx
	movq	%rax, %r8
	addq	$'0', %rdx
	leaq	.NUMBUF(%rip), %rax
	addq	-48(%rbp), %rax
	movb	%dl, (%rax)
	incq	-48(%rbp)
	jmp	.parse_integer_loop

.parse_integer_fully_parsed:
	CHECK_BUFFER_SPACE
	movq	-48(%rbp), %rbx
	decq	%rbx
	leaq	.NUMBUF(%rip), %rax
	addq	%rbx, %rax
	movzbl	(%rax), %ebx
	movq	-24(%rbp), %rax
	movb	%bl, (%rax)
	decq	-48(%rbp)
	ADVANCE_BY_ONE_IN_BUFFER
	cmpq	$0, -48(%rbp)
	je	.go_next_char
	jmp	.parse_integer_fully_parsed

.parse_string:
	CHECK_BUFFER_SPACE
	movzbl	(%r8), %edi
	cmpb	$0, %dil
	je	.go_next_char
	movq	-24(%rbp), %rax
	movb	%dil, (%rax)
	incq	%r8
	ADVANCE_BY_ONE_IN_BUFFER
	jmp	.parse_string	

.parse_percentage:
	movq	-24(%rbp), %rax
	movb	$'%', (%rax)
	incq	-16(%rbp)
	incq	-24(%rbp)
	jmp	.go_next_char

.go_next_char:
	incq	-8(%rbp)
	jmp	.collect_chr_from_fmt

.print_and_clean:
	movq	$1, %rax
	movq	-32(%rbp), %rdi
	leaq	.BUFFER(%rip), %rsi
	movq	-16(%rbp), %rdx
	syscall
	leaq	.BUFFER(%rip), %rax
	movq	$0, %r8
.clean_loop:
	cmpq	.BUFFER_LENGTH(%rip), %r8
	je	.ret
	movq	$0, %rax
	addq	$8, %rax
	addq	$8, %r8
	jmp	.clean_loop
.ret:
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
	ERRMSG  .err1m(%rip), .err1l(%rip)
	EXIT	$1

.fatal_unknown_format:
	ERRMSG  .err2m(%rip), .err2l(%rip)
	EXIT	$2

.fatal_number_overflow:
	ERRMSG  .err3m(%rip), .err3l(%rip)
	EXIT	$3
