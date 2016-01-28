# OS Organization Revisited

## Processes and Files

Processes and files are all "fakes". They appear to have a real machine to themselves, but the operating system generally has control of the process.

The major resources needed to implement a "pretend" computer for a process with files are:

  - Arithmetic Logic Unit (ALU)
    - Same as the real machine's ALU, because it is too slow and unnecessary for the kernel to simulate the ALU
  - Registers
    - Same as real machine's registers when running
    - Otherwise, stored in memory when a different process is running
  - Memory (RAM)
    - Same as real machine's physical memory when running and actually accessing it
    - Otherwise, the process's memory could be stored on disk
    - The process thinks it has access to all memory, but the operating system gives it its own address space ("virtual memory")
  - I/O
    - Emulated/simulated by the kernel's implementation of communicating to disk controllers, writing to the screen, etc.

The ALU, registers, and memory are more like the real machine because they use machine instructions. On the other hand, I/O is abstracted by a system call interface.

## Process Table

The kernel has to keep track of processes so that it can allocate CPU time and memory, and let the processes think that they have a real machine.

The kernel memory contains a `process table`, which is an array of `process descriptors`.

A process descriptor stores the following information:
  - A copy of user-visible registers: registers are stored here when the kernel does a context switch
  - Memory: a register containing a pointer to the process's memory.
  - I/O: A file descriptor table: 1024 item array of the files that that process opened.

> The process descriptor does not remember the state of the ALU. It just throws away incomplete calculations instead.


### Handles for file descriptors

The OS needs a way to remember which files a process has open.

In Linux/Unix, an integer is used as a handle for an open file. The advantage of this approach is that it adds a layer of indirection, so the OS has more control over the file descriptors and can perform some optimizations.

In other systems, a pointer (eg. `struct filedes*`) might be used as a handle. This approach has better performance, programmers get direct access to the file descriptor, and the compiler can enforce type checking.

However, using a pointer is less portable because the file descriptor data structure may be different depending on the system. This approach is also not orthogonal because the implementation of file descriptors influences how applications have to be written.

## Pipes


<!-- Break! -->

