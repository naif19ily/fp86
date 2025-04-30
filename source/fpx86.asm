.section .bss
	.lcomm buffer, 2048

.section .text

.globl fpx86

fpx86:
	pushq	%rbp
	movq	%rsp, %rbp
	subq	$28, %rsp
	#
	# Stack distribution
	#
	#  -8: number of bytes written
	# -16: pointer to buffer
	# -24: format string
	# -28: fd
	#
	movq	%rdi, -24(%rbp)
	movl	%esi, -28(%rbp)
	call	.__is_formated_string
	cmpq	$0, %rax
	jl	.__0_no_fmt_used

	jmp	.__0_return

.__0_no_fmt_used:
	negq	%rax
	leave
	ret

.__0_return:
	movq	-8(%rbp), %rax
	leave
	ret


#
# Function: checks if the given string contains an actual
# format, if the string does not, then this will print the
# string via write syscall and it will return -1 * bytes to indicate
# it, otherwise it will return the number of characters already
# read before hitting the format specifier symbol (%)
#
.__is_formated_string:
	pushq	%rbp
	movq	%rsp, %rbp
	subq	$20, %rsp
	#
	# Stack  distribution
	#
	#  -8: string
	# -16: number of bytes read
	# -20: fd
	#
	movq	%rdi, -8(%rbp)
	movq	$0, -16(%rbp)
	movl	%esi, -20(%rbp)
	xorq	%rdi, %rdi
.__1_loop:
	movq	-8(%rbp), %rax
	movq	-16(%rbp), %rcx
	addq	%rcx, %rax
	movzbl	(%rax), %eax
	cmpb	$0, %al
	jz	.__1_print_and_leave
	cmpb	$'%', %al
	jz	.__1_return
	incq	-16(%rbp)
	jmp	.__1_loop
.__1_print_and_leave:
	movq	$1, %rax
	movl	-20(%rbp), %edi
	movq	-8(%rbp), %rsi
	movq	-16(%rbp), %rdx
	syscall
	movq	-16(%rbp), %rax
	negq	%rax
	leave
	ret
.__1_return:
	# it decrements the value of rax since it is currently
	# pointing to the % sign which is used to know there's
	# a format, we cannot print % itself.
	movq	-16(%rbp), %rax
	decq	%rax
	leave
	ret
