# CMPS 3240 Lab: Control of flow with ARM

## Objectives

During this lab you will:

* Learn about ARM64 stack linkage
* Use `gcc` to assemble examples of ARM stack linkage
* Implement a recursive version of Fibonacci

## Prerequisites

This lab assumes you have read or are familiar with the following topics:

* Different parts of memory
* The stack
* The idea of stack linkage
* The idea of stack frames / frame records
* ARM64 stack linkage<sup>1</sup>

Please study these topics if you are not familiar with them so that the lab can be completed in a timely manner.

## Requirements

The following is a list of requirements to complete the lab. Some labs can completed on any machine, whereas some require you to use a specific departmental teaching server. You will find this information here.

### Software

We will use the following programs:

* `gcc`
* `git`
* `gdb`

### Compatability

This lab requires the departmental ARM server. It will not work on `odin.cs.csubak.edu`, `sleipnir.cs.csubak.edu`, other PCs, etc. that have x86 processors. It may work on a Raspberry Pi or similar system on chip with ARM, but it must be ARMv8-a.

| Linux | Mac | Windows |
| :--- | :--- | :--- |
| Limited | No | No |

## Background

The purpose of this lab is to understand stack linkage (also called calling convention or call convention). A stack linkage defines how processes interact with each other. It defines how the stack should be used, what the caller and callee behavior are, and how the registers should be used. So, which stack linkage should be used? A process uses a specific linkage depending on the instruction set architecture (ISA) being used, and what operating system you're using. Some examples are Microsoft x64 calling convention and System V AMD64 ABI for x86-64 ISAs.<sup>a</sup> With low-level systems applications,  a project may implement their own stack linkage and long-running, legacy projects may have multiple stack linkages within the same project.<sup>b</sup> ARM has a specific stack linkage defined in the following document and this will be the topic of the lab today.<sup>1, c</sup> 

A stack linkage specifies the following:

1. How registers should be used
2. How the stack should be used
3. Behavior of how a subroutine calls another subroutine. The subroutine making the call is called the *caller*. The subroutine being called is called the *callee*.

For this lab, the number of arguments passed between the callee and caller should be known and fixed.<sup>d</sup>

### Registers

Some registers are *saved registers*. That is, if a callee uses the register--modifies the values originally in the register--they must be restored by the callee before returning to the caller. Other registers are *unsaved registers*. The callee can freely use and clobber the values in these registers, and does not need to restore their original values. The ARM calling convention specifies the following:

* Registers 0 to 7 are unsaved registers for passing arguments<sup>e</sup>
* A subroutine passes the return value through register 0
* Registers 9 to 15 are unsaved registers for scratch work
* Registers 19 to 28 are saved registers for scratch work 
* Register 29 is a saved register, called the *frame pointer*
* Register 30 is a saved register, called the *link pointer*. `bl` places the return address in this register and then jumps. `ret` returns to the address specified in this register.
* The stack pointer (`sp`) register is a saved register that should always point to the end of the stack. Values higher than `sp` contain valid data. Values lower than `sp` contain garbage. 
* Other registers not described here have specific purposes that go beyond the scope of this class.

### Stack

The stack lives in the memory. It holds temporary variables and data used by the current process. Generally it starts at a high addresses and grows downward. There is a pointer called the stack pointer `sp` that points to bottom of the stack. When a process needs stack space it allocates space by subtracting the stack pointer (recall that it starts high and grows downward). It is then free to use this newly allocated space (between the old value of the stack pointer and the new value). This area is called a *stack record* or frame. There is a danger that uncontrolled growth of the stack will cause it to grow into other parts of the memory, such as the heap.

Specific to the environment in this course the frame pointer should shadow the stack pointer. The old value of the frame pointer should be shadowed onto the stack. Thus, the stack records in ARM form a linked list. This is different from other calling conventions.<sup>f</sup>

ARM calling convention also specifies the following:
* The lowest addressed double-word in the frame record should contain the old frame pointer
* The second lowest addressed double-word in the frame record should contain the value passed in LR on entry to the current function 
* The stack must be quad word aligned
* To save values onto the stack the stack pointer must have been moved beforehand, or allocate space as needed with an arithmetic operation (such as `sub` or pre-indexed addressing). Then, use `str` or `stp` instruction to place the values relative to `sp`.<sup>g</sup> Example:
```arm
# Simple example
sub sp, sp, 16
str x0, [sp, 16]
```
Another example using pre-indexing:
```arm
# Recall that pre-index modifies the pointer before dereference
str x0, [sp, 16]!
```
* To load values from the stack use `ldr` or `ldp` commands pull values from the stack. Addressing is relative to `sp`.

### Caller Notes

Things the caller should do before jumping to the callee with `bl`:

* The first 8 arguments are passed in registers, in order. The first argument is stored in `0`, the second argument is stored in `1` and so on.
* The size of the argument dicatates which register to use (`w` or `x`)
* Arguments greater than 8 are passed on the stack. The order is reversed; the last argument is in the highest address.

After the above, the caller calls the callee with branch-and-link (`bl`) which saves the return address to the link register `x30`.

### Callee Notes

Things the callee should do the following:

1. Set up its frame record. If this is a leaf function--it call no other subroutines--the first instruction is often to move the stack pointer `sp` with a `sub` instruction. Example:

```arm
myfunc:
sub sp, sp, 32
```

However, if it is a non-leaf function, it must comply with the points we discussed above. Here is an example that adheres to everything:

```arm
myfunction:
# Suppose we want to pre-allocate 128 bytes. The stack pointer is placed
# at the bottom of the frame record:
str x29, [sp, -128]!
# Use pre-index to requisition stack space before saving x29. The link register is copied just above it:
str x30, [sp, 8]
# Set the current frame pointer. This seems weird but it is by convention. The frame records must form a link listed and point to each other
add x29, sp, 0
```

Note this is not unique. You could also use the `stp` for a more elegant but perhaps less understandable code:

```arm
myfunction:
stp x29, x30, [sp, -128]!
add x29, sp, 0
```

2. The first 8 input arguments are shadowed onto the stack. This is a standard operation specified by the convention, even if it may be wasteful. Use the `str` instruction to copy the input arguments onto the stack. The first argument is stored in the lowest position on the stack. Note that we do not need to shadow arguments that are on the stack because they were already placed onto the stack by the caller. Example:

```arm
myfunction: 
# Some leaf
sub sp, sp, 16
ldr x0, [sp, 0]
ldr x1, [sp, 8]
```

3. Perform the intended logic of the subroutine

4. When quitting, the callee should restore the stack pointer, link pointer and frame pointer to its original values before returning (`ret`). Example:

```arm
myfunction:
stp x29, x30, [sp, -128]!
add x29, sp, 0
...
ldp x29, x30, [sp], 128
ret
```

using `ldp` and post-indexing to both restore all the values and pop the stack (revert the pointer to its original value).


### Examples

In the following section, we go over some examples provided in this repository that should affirm everything we've covered so far.

#### `main.c`

For these first two examples we will use `gcc` to generate assembly code for us. Normally we prefer to work from the ground up, but `gcc` generates code that must adhere to the calling convention, and should generate compliant example code for us.

The first example we will look at is `main.c` that contains three functions that call each other and print a number to the screen. `main()` calls `foo()`, which calls `bar()` and then a number is printed to the screen. Open up `main.c` in a text editor:

```bash
$ vim main.c
```

Study it for a bit, then use the Make target `main.s` to generate the assembly code, then open the assembly code with your favorite text editor:

```bash
$ make main.s
gcc -O0 -Wall -S main.c -o main.s
$ vim main.s
```

`bar` is pretty simple, it just returns the literal 43 through `w0`. The 0 register is the return register, and note that `w` is used because 43 is an integer which is only 32-bits.

`foo` is the first function to implement a frame record. Note that it uses an `stp` instruction with pre-indexing to store both the old frame pointer and the link register:

```arm
stp x29, x30, [sp, -16]!
add x29, sp, 0
...
ldp x29, x30, [sp], 16
ret
```

Beyond that it does not really allocate additional stack space. The `ldp` instruction, using a post-index, both restores the link register and frame pointer and reverts the stack pointer (also called popping the stack). You should also look at `main`, it does something similar.

#### `manyargs.c`

This example contains a function that demonstrates passing arguments. A function adds 11 numbers together, which exceeds the number of registers designated as argument registers. We should see behavior for the callee expecting arguments on the stack. Open up `manyargs.c`:

```bash
$ vim manyargs.c
```

Note that there is no `main()`, this example just details how to pass arguments. Also note that this is a leaf function, so setting up a frame record isn't required. Fire the correct make target and take a look at the source code:

```bash
$ make manyargs.s
gcc -Wall -S manyargs.c -o manyargs.s
$ vim manyargs.s
```

Note that shadowing the link pointer and the frame pointer are not required because this is a leaf function. However, by convention, we still shadow the input arguments to the stack, so we still decrement `sp`. The first set of `str` operations store the arguments in `x0` thru `x7` into consecutive positions on the stack. The compiler does a weird thing here. Even though the registers `x0` thru `x7` already contain the input arguments, it wastes operations here bringing the values from the stack into scratch registers. This is an example of how the compiler is not perfect and there is always room for improvement of the code at a low-level. Also note that arguments 9-11 are passed on the stack and the callee pulls them off the stack in the order described by the background section.

#### `fact.s`

This is the first non-trivial example, ARM code for a recursive function that implements the following C-language code snipet:

```c
int fact( int n ) {
	if (n <= 1)
		return 1;
	else
		return n * fact( n - 1 );
}
```

Carefully study this code. You may want to do a hand-trace to understand it.

## Technical Approach

In a previous lab we implemented an interative version of Fibonacci code. We were not able to implement a recursive version because we had not yet covered how to generate function scope (the underlying frame record). In this lab, using `fact.s` as a baseline code, modify the code to generate a Fibonacci number. For reference, here is the C-language code:

```c
int fib( int n ) {
	if (n == 0)
		return 0;
	else if (n == 1)
		return 1;
	else {
		return fib( n - 2 ) + fib( n - 1 );
	}
}
```

Alternatively, you can condense the first two `if` blocks to `if (n <= 1) { return n; }`. Though you are using `gcc` to assemble and link your code, it is not permitted to have `gcc` generate your Fibonacci code for you. Your work must be original.

## Check off

For full credit, show the instructor that your code can calculate the 13th Fibonacci number.

## References
<sup>1</sup>http://infocenter.arm.com/help/topic/com.arm.doc.ihi0055b/IHI0055B_aapcs64.pdf

## Footnotes
<sup>a</sup>If you ever wondered why you can't run a Windows binary on a Linux machine even if they both have an x86 processor, this is one of the many reasons
<sup>b</sup>This happens often with military and aerospace applications
<sup>c</sup>This document may use different register prefixes from what is used with Linux ARM mnemonics. E.g., `r` vs. `x`.
<sup>d</sup>Variadic subroutines--varying number of arguments--are allowed in ARM, but we do not cover them in this class
<sup>e</sup>System calls use a reduced number of registers for passing arguments
<sup>f</sup>For example, with MIPS, the frame pointer should only point to the top of the current frame record
<sup>g</sup>Be careful getting help on the internet here, previous versions of ARM had `push` and `pop` instructions that no longer exist with ARM64
