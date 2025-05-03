#
#  _______ _______       _______ _______ 
# |   _   |   _   .--.--|   _   |   _   |
# |.  1___|.  1   |_   _|.  |   |   1___|
# |.  __) |.  ____|__.__|.  _   |.     \ 
# |:  |   |:  |         |:  1   |:  1   |
# |::.|   |::.|         |::.. . |::.. . |
# `---'   `---'         `-------`-------'
#
# Tester file, do not include this file into
# your project ;)
#

.section .rodata
        .fmt: .string "> %b\n"
	.cat: .string "1"

.section .text

.globl _start

_start:
        pushq   $0
        leaq    .fmt(%rip), %rdi
        movl    $1, %esi
        call    FPx86
        movq    %rax, %rdi
        movq    $60, %rax
        syscall
