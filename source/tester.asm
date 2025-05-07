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
	msg: .string "%c %c %c\n"

.section .text

.globl _start

_start:
	pushq	$97
	pushq	$98
	pushq	$99
	leaq	msg(%rip), %rdi
	movl	$1, %esi
	call	__fpx86

	movq	%rax, %rdi
	movq	$60, %rax
	syscall
