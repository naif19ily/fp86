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

	movb	%dil, (%r9)
	incq	%r9
	incq	-72(%rbp)
	jmp	.__0_continue

.__0_format_found:

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

.__fatal_buf_overflow:
	EXIT	$-1
