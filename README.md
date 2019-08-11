## Background

The purpose of this lab is to understand stack linkage (also called calling convention or call convention). A stack linkage defines how processes interact with each other. It defines how the stack should be used, what the caller and callee behavior are, and how the registers should be used. So, which stack linkage should be used? A process uses a specific linkage depending on the instruction set architecture (ISA) being used, and what operating system you're using. Some examples are Microsoft x64 calling convention and System V AMD64 ABI for x86-64 ISAs.<sup>a</sup> With low-level systems applications,  a project may implement their own stack linkage and long-running, legacy projects may have multiple stack linkages within the same project.<sup>b</sup> ARM has a specific stack linkage defined in the following document and this will be the topic of the lab today.<sup>1, c</sup> 

A stack linkage specifies the following:

1. How registers should be used
2. How the stack should be used
3. Behavior of how a subroutine calls another subroutine. The subroutine making the call is called the *caller*. The subroutine being called is called the *callee*.


For this lab, the number of arguments passed between the callee and caller should be known and fixed.<sup>d</sup>

### Registers

Some registers are *saved registers*. That is, if a callee uses the register--modifies the values originally in the register--they must be restored by the callee before returning to the caller. Other registers are *unsaved registers*. The callee can freely use and clobber the values in these registers, and does not need to restore their original values. The ARM calling convention specifies the following:

* Registers 0 to 7 are unsaved registers for passing arguments and returning values<sup>e</sup>
* Registers 9 to 15 are unsaved registers for scratch work
* Registers 19 to 28 are saved registers for scratch work 
* Register 29 is a saved register, called the *frame pointer*
* Register 30 is a saved register, called the *link pointer*. It contains the return address of the caller and is automatically handled for us by `bl` and `ret` instructions.
* The stack pointer (`sp`) register is a saved register that should always point to the end of the stack. Values higher than `sp` contain valid data. Values lower than `sp` contain garbage. 
* Other registers not described here have specific purposes that go beyond the scope of this class.

### Stack

The stack can be thought of as a single-index array that holds temporary variables and data used by the current process. Generally it starts at a high addresses and grows downward. There is a pointer called the stack pointer `sp` that points to bottom of the stack. When a process needs stack space it allocates space by subtracting the stack pointer (recall that it starts high and grows downward). It is then free to use this newly allocated space (between the old value of the stack pointer and the new value). This are is called a *stack record* or frame. Specific to ARM calling convention, the frame pointer should point to the starting address of the previous stack record. Thus, stack records in ARM form a linked list. This is different from other calling conventions.<sup>f</sup>

ARM calling convention also specifies the following:
* The lowest addressed double word in the frame record should point to the previous frame record. The highest addressed double-word shall contain the value passed in LR on entry to the current function. 
* The stack must be quad word aligned. That is, even if you only intend to use a byte or word (4 bytes), you must increment the stack pointer in units of 16 bytes. 
* To save values onto the stack you must move the stack pointer (such as `sub` or pre-indexed addressing) and then use `str` or `stp` instruction to place the values relative to `sp`.<sup>g</sup> Example:
```arm
# Simple example
sub sp, sp, 16
str x0, [sp, 16]
```
Another example using pre-indexing:
```arm
# Recall that pre-index modifies the pointer
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

Things the callee should do before it's primary function:

1. The callee allocates its frame record. So, one of the first instructions in a subroutine is to move the stack pointer `sp` with a `sub` instruction. Example:

```arm
sub sp, sp, #32
```

However, we covered a lot of points above, and this is an example that adheres to everything:

```arm
myfunction:
# In this example we allocate 5 blocks: 5 * 16 = 80 blocks plus
# the required SP and LR space (so a total 96). 

# The link pointer is shadowed to the highest point in the stack
str x30, [sp, 8]
# Save the previous frame pointer
str x29, [sp, 96]
# Set the current frame pointer
add x30, sp, 0
# Now move the stack pointer
sub sp, sp, 96
```
Note this is not unique, you could have used pre-indexing here. Note that it is the simplest/laziest way to calculate the current frame pointer because we delay moving `sp`.

2. The first 8 input arguments are shadowed. Use the `str` instruction to copy the input arguments onto the stack. The first argument is stored in the lowest position on the stack. Note that we do not need to shadow arguments that are on the stack because they were already placed onto the stack by the caller.

When quitting, the callee should restore the stack pointer, link pointer and frame pointer to its original values before returning (`ret`).

### Examples

In the following section, we go over some examples provided in this repository that should affirm everything we've covered so far.

#### `main.c`



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