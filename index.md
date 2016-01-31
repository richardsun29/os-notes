# Lecture 6 - OS Organization Revisited


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

The process descriptor does not remember the state of the ALU. It just throws away incomplete calculations instead.

### Handles for file descriptors

The OS needs a way to remember which files a process has open.

In Linux/Unix, an integer is used as a handle for an open file. The advantage of this approach is that it adds a layer of indirection, so the OS has more control over the file descriptors and can perform some optimizations.

In other systems, a pointer (eg. `struct filedes*`) might be used as a handle. This approach has better performance, programmers get direct access to the file descriptor, and the compiler can enforce type checking.

However, using a pointer is less portable because the file descriptor data structure may be different depending on the system. This approach is also not orthogonal because the implementation of file descriptors influences how applications have to be written.


## Pipes

Pipes are a way to send data between processes. A pipe has two file descriptors: one for writing to the pipe and one for reading from it. The data written to a pipe is stored in a bounded buffer and is deleted from the buffer when it is read.

What can go wrong here?
- A process tries to write to a pipe with a full buffer, an all readers are busy doing something else:
	- Making the buffer bigger would work, but it can exhaust memory. Discarding data and making calls to `read()` fail is cheaper, but this method is unreliable since it data is lost.
	- Solution: Suspending the writer until there is room in the buffer is the standard choice in Linux.
- A process tries to write to a pipe, but there are no readers:
	- In this case, suspending the writer will make it suspend forever.
	- Solution: kill the process with `SIGPIPE`. This is a valid solution because only the process and its children can ever read from a pipe (using the `fork`, `pipe`, and `dup` systemcalls). A process can choose to ignore `SIGPIPE`, in which case `write()` will fail with `errno` set to `EPIPE`.
- A process tries to read from a pipe with no writers
	- `read()` just returns 0 (`EOF`), indicating that there is no more data in the pipe.

### Infinite waiting problem

Because the way pipes are handled depend on if there are any readers or writers, processes will suspend indefinitely if another process holds onto a copy of a file descriptor but does not use it. In order to deal with this, a parent process and its children have to `close` the pipe ends that it is not using.

### Named pipes

In Linux, there are also named pipes, which are pipes that are actually a file. Using named pipes, processes can communicate to other processes that are not a parent or child.

```bash
$ mkfifo /tmp/pipe          # make a file that is a pipe
$ cat /tmp/pipe > out &     # cat hangs, trying to read from the pipe
$ echo "Hello" > /tmp/pipe  # writes to the pipe and unblocks cat
```

### More things that could go wrong

- Opening a pipe and never using it
	- For example:
```c
int ok = pipe(fd) == 0;
for (;;) { /* do something else */ }
```
This opens a pipe and never uses it, taking up kernel memory that no other process can use; this is called a pipe leak.
- Not closing write/read ends
	- If a write end of a pipe is never closed, the read ends of a pipe will keep hanging. For example, `while :; do :; done; | cat` will cause `cat` to hang since the while loop in the read end loops infinitely and doesn't return.
	- If a shell like `sh` implements `a | b` and it only closes `a`, `b` will hang since `sh` has still access to the write end of the pipe. To solve this, `sh` must close its connections to both `a` and `b`, or else there's still 1 writer to the write end.
- Pipe deadlock
	- If a parent communicates with a child process using a pipe, and that process communicates to the parent using another pipe, it's possible for both processes to hang. For example, if the child process executes `sed 'p;p;p;'`, this outputs every line that it receives from the parent 3 times to its own pipe to the parent. Then the child's pipe will fill up faster than the parent's pipe will, and the parent doesn't read from the child's pipe, so the child hangs. The parent is still writing to its pipe, but that pipe will eventually fill up too, and the parent will hang too.
	- This will only happen if the child writes to its pipe faster than the parent can. Other commands are safe; for example, if the child executes `sort`, it won't cause pipe deadlock since `sort` would wait until all input is finished (i.e., parent has finished writing) until it starts writing back to its own pipe.

### Orthogonality

Running `(rm bigfile; grep interesting) < bigfile` will have output if `bigfile` contains 'interesting' since file descriptors access files at a lower level than the file names; a file is orthogonal to its name. `rm` simply removes the name, but doesn't delete the data on disk since `grep` is accessing the file descriptor; a file won't be removed until all file descriptors pointing to it go away (just like `pipe()`). The OS keeps files around until no more readers are interested.

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

### Receiving signals

To catch a specific signal, we call the `signal` function: `sighandler_t signal(int signum, sighandler_t handler);`. `signum` is the signal number, and `handler` is the function that will run when the signal is caught. `sighandler_t` is defined as `typedef void (*sighandler_t)(int);`, which is a function that takes an integer and returns void. `handler` is the new signal handler that will get run, and the function returns the old handler.

This new signal handler can be run at any time in the middle of the rest of the program. For example, if your code looks like:
```c
signal(29, handlerFunc);
x = y + 1;
z = w + x;
```
The signal handler can be run in the middle of the instructions that add w and x, since the program can trigger an interrupt and run the signal handler between every pair of assembly instructions, such as the load and add instructions. This means that the signal handler can potentially modify variables and create race conditions.

### Signal handler example

We can write gzip, a program that compresses a directory, with a signal handler so that if the user interrupts the program, the program will delete the compressed directory that it started to make. For example, `$ gzip foo` creates foo.gz, and if the program is interrupted, foo.gz should be deleted.

With the following code, foo.gz will remain if the program is interrupted:
```c
int fd = open("foo", O_RDONLY);
int fo = open("foo.gz", O_WRONLY | O_CREAT);
while (compress(fd, fo))
	continue;
close(fd);
close(fo);
unlink("foo"); // delete foo at the end
```

We can attempt to add a signal handler like so:
```c
int fd = open("foo", O_RDONLY);
signal(SIGINT, cleanup);
int fo = open("foo.gz", O_WRONLY | O_CREAT);
while (compress(fd, fo))
	continue;
close(fd);
close(fo);
unlink("foo"); // delete foo at the end

...

static void cleanup(int sig) {
	unlink("foo.gz"); // delete foo.gz during cleanup
	_exit(1);
}
```
However, the second line introduces a race condition: if the signal handler is called right before foo.gz is opened in the third line, the program will attempt to delete foo.gz before it is even created. This means we should move the call to `signal()` to the third line:
```c
int fd = open("foo", O_RDONLY);
int fo = open("foo.gz", O_WRONLY | O_CREAT);
signal(SIGINT, cleanup);
while (compress(fd, fo))
	continue;
close(fd);
close(fo);
unlink("foo"); // delete foo at the end

...

static void cleanup(int sig) {
	unlink("foo.gz"); // delete foo.gz during cleanup
	_exit(1);
}
```
This is better, but it's possible that the user can interrupt the program after it finishes writing to foo.gz, in which case `cleanup()` will delete foo.gz, which isn't what we want. We can solve this by setting the `SIGINT` signal back to its default behavior after we close fd; putting `SIG_DFL` as the `handler` argument in `signal()` enables the signal number's default behavior.
```c
int fd = open("foo", O_RDONLY);
int fo = open("foo.gz", O_WRONLY | O_CREAT);
signal(SIGINT, cleanup);
while (compress(fd, fo))
	continue;
close(fd);
close(fo);
signal(SIGINT, SIG_DFL);
unlink("foo"); // delete foo at the end

...

static void cleanup(int sig) {
	unlink("foo.gz"); // delete foo.gz during cleanup
	_exit(1);
}
```
There's one last problem though: if the `SIGINT` signal is sent right before `unlink("foo")`, foo is left behind and foo.gz is too, since we're now using the default behavior for `SIGINT` instead of calling `cleanup()`. The solution to this issue is presented in the next lecture.
