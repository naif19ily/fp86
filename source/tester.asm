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
	msg: .string "%<12\n"

.section .text

.globl _start

_start:
	leaq	msg(%rip), %rdi
	movl	$1, %esi
	call	__fpx86

	movq	%rax, %rdi
	movq	$60, %rax
	syscall
