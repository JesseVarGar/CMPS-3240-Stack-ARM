	.arch armv8-a
	.file	"mcCar.c"
	.text
	.align	2
	.global	mc91
	.type	mc91, %function
mc91:
.LFB0:
	.cfi_startproc
	stp	x29, x30, [sp, -64]!
	.cfi_def_cfa_offset 32
	.cfi_offset 29, -32
	.cfi_offset 30, -24
	mov	x29, sp
	str	w0, [sp, 28]
	ldr	w0, [sp, 28]
	cmp	w0, 2
	bge	.L2
	ldr	w0, [sp, 28]
	
	b	.L3
.L2:
	ldr	w0, [sp, 28]
	sub	w0, w0, 1
	str	w0, [sp, 28]
#store n - 1

	bl	mc91
#complete fib(n - 1)

	str	w0, [sp, 32]
#store result of fib(n - 1)


	ldr	w0, [sp, 28]
#load n-1
	sub	w0, w0, 1
#sub (n-1)-1

	bl	mc91
#complete fib(n - 2)

	ldr	w1, [sp, 32]
#load fib(n - 1)
#w0 contains fib(n - 2)

	add	w0, w0, w1


.L3:
	ldp	x29, x30, [sp], 64
	.cfi_restore 30
	.cfi_restore 29
	.cfi_def_cfa_offset 0
	ret
	.cfi_endproc
.LFE0:
	.size	mc91, .-mc91
	.section	.rodata
	.align	3
.LC0:
	.string	"%d\n"
	.text
	.align	2
	.global	main
	.type	main, %function
main:
.LFB1:
	.cfi_startproc
	stp	x29, x30, [sp, -32]!
	.cfi_def_cfa_offset 32
	.cfi_offset 29, -32
	.cfi_offset 30, -24
	mov	x29, sp
	mov	w0, 13
	bl	mc91
	str	w0, [sp, 28]
	ldr	w1, [sp, 28]
	adrp	x0, .LC0
	add	x0, x0, :lo12:.LC0
	bl	printf
	mov	w0, 0
	ldp	x29, x30, [sp], 32
	.cfi_restore 30
	.cfi_restore 29
	.cfi_def_cfa_offset 0
	ret
	.cfi_endproc
.LFE1:
	.size	main, .-main
	.ident	"GCC: (Ubuntu 9.4.0-1ubuntu1~20.04.2) 9.4.0"
	.section	.note.GNU-stack,"",@progbits
