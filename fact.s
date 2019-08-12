.data
.global string1
string1:
	.ascii	"The factorial of %d is %d!\n\0"
string2:
	.ascii	"Entering fact() with n=%d\n\0"

.text
.extern printf
.global main
main:
### SET UP FRAME RECORD ###
# Save FP and LR with pre-indexing, allocated another 16 bytes for temp.
stp	x29, x30, [sp, -16]!
# Set FP
add	x29, sp, 0

### MAIN() LOGIC ###
# Call fact(6)
mov	x0, 8
bl	fact
# Respond with prompt
add	x2, x0, 0
mov	x1, 6
ldr	x0, =string1
bl	printf

### TAKE DOWN FRAME RECORD ###
ldp	x29, x30, [sp], 16
mov	w0, 0
ret

.global fact
fact:
### SET UP FRAME RECORD ###
# Save FP and LR with pre-indexing, allocated another 16 bytes for temp.
stp	x29, x30, [sp, -32]!
# Set FP
add	x29, sp, 0
# Shadow input argument
str	x0, [sp, 16]

### SOME PROMPTS ###
ldr	x0, =string2
ldr	x1, [sp, 16]
bl printf

### LOGIC FOR FACT() ###
ldr	x0, [sp, 16]
cmp	x0, 1
# If n <= 1, return 1 ... jump to block that returns 1
ble 	return1
# Logic for calc. n * fact(n-1) here. At this instruction the value for x0 
# should still hold arg1 for this call. Calculate n-1, note it's set up in x0 
# which is the argument register
sub	x0, x0, 1
# This is the call to fact(n-1)
bl	fact
# At this point x0 contains the return value for fact(n-1). Refresh value for
# arg1.
ldr	x1, [sp, 16]
# Now do the multiplication op, set it up to place result in return register.
mul	x0, x0, x1
b 	return

return1:
mov	x0, 1
# return1 block falls through to the return code

return:
ldp	x29, x30, [sp], 32
ret
