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
	.fmt: .string "naif19il%<5c\n"

.section .text


.globl _start

_start:
	pushq	$'y'
	leaq	.fmt(%rip), %rdi
	movl	$1, %esi
	call	FPx86

	movq	%rax, %rdi
	movq	$60, %rax
	syscall
