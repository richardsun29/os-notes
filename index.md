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

## Signals

Why do we use signals when they are so much trouble?
- Asynchronous I/O:
	- When we do a `read()`, we wait until the entire file gets read, and then continue. `aio_read()` on the other hand returns right away and sends a `SIGIO` signal when it's done reading.
- Errors in the code: 
	- If we're running a large program, it's possible that we don't want to crash the entire program if there's an error such as division by 0, floating point overflow, or an invalid instruction. Instead, we want to catch the signal, deal with the error, and move on without exiting entirely.
- `Ctrl-C`: 
	- The user is impatient and wants the program to exit, or the program is in an infinite loop, and we don't want the program to exit right away. Hitting `Ctrl-C` sends the `SIGINT` signal.
- Impending power outage:
	- If a computer's power plug is pulled, it might only have a few milliseconds before the computer entirely shuts down, but in that time the operating system can get all the programs to properly exit first, and it does so by sending the `SIGPWR` signal.
- Creating many children processes:
	- It would be expensive for the parent to call `waitpid(-1, &status, WNOHANG)` often to find out if any child process has finished yet while it's doing its own work; plus, depending on how often the parent polls the children, there will also be a time delay between a child finishing and the parent finding out. Instead, the parent can catch the `SIGCHLD` signal, which is automatically sent to the parent whenever a child is finished.
- User goes away
	- If the user logged out of their account, disconnected from the server, etc., the operating system sends the `SIGHUP` signal to the program.
- End a bad process
	- A SEASNET sysadmin can end a fork bomb that a student created by using the `SIGKILL` signal, which kills a process and can't be caught or ignored. The command `kill -KILL -6010` kills the process with PID 6010, and the negative sign on the PID means it kills the children processes too.
- End a runaway program
	- Kill a program that won't stop running
- Suspend a process
	- `kill -STOP 2542` suspends the process with PID 2542 using a `SIGSTOP` signal, and `kill -CONT 2542` continues that process.
- Set a timeout:
	- `alarm(20)` sends a `SIGALRM` signal in 20 seconds, and this signal by default kills the program.
- Important, unusual, or unexpected events
	- Some OSes have a `SIGEOF` signal, but this doesn't seem to be a very unusual event since every file has an EOF, so having a signal dedicated to it seems unnecessary.
