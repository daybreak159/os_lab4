#include <proc.h>
#include <kmalloc.h>
#include <string.h>
#include <sync.h>
#include <pmm.h>
#include <error.h>
#include <sched.h>
#include <elf.h>
#include <vmm.h>
#include <trap.h>
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

/* ------------- process/thread mechanism design&implementation -------------
(an simplified Linux process/thread mechanism )
introduction:
  ucore implements a simple process/thread mechanism. process contains the independent memory sapce, at least one threads
for execution, the kernel data(for management), processor state (for context switch), files(in lab6), etc. ucore needs to
manage all these details efficiently. In ucore, a thread is just a special kind of process(share process's memory).
------------------------------
process state       :     meaning               -- reason
    PROC_UNINIT     :   uninitialized           -- alloc_proc
    PROC_SLEEPING   :   sleeping                -- try_free_pages, do_wait, do_sleep
    PROC_RUNNABLE   :   runnable(maybe running) -- proc_init, wakeup_proc,
    PROC_ZOMBIE     :   almost dead             -- do_exit

-----------------------------
process state changing:

  alloc_proc                                 RUNNING
      +                                   +--<----<--+
      +                                   + proc_run +
      V                                   +-->---->--+
PROC_UNINIT -- proc_init/wakeup_proc --> PROC_RUNNABLE -- try_free_pages/do_wait/do_sleep --> PROC_SLEEPING --
                                           A      +                                                           +
                                           |      +--- do_exit --> PROC_ZOMBIE                                +
                                           +                                                                  +
                                           -----------------------wakeup_proc----------------------------------
-----------------------------
process relations
parent:           proc->parent  (proc is children)
children:         proc->cptr    (proc is parent)
older sibling:    proc->optr    (proc is younger sibling)
younger sibling:  proc->yptr    (proc is older sibling)
-----------------------------
related syscall for process:
SYS_exit        : process exit,                           -->do_exit
SYS_fork        : create child process, dup mm            -->do_fork-->wakeup_proc
SYS_wait        : wait process                            -->do_wait
SYS_exec        : after fork, process execute a program   -->load a program and refresh the mm
SYS_clone       : create child thread                     -->do_fork-->wakeup_proc
SYS_yield       : process flag itself need resecheduling, -- proc->need_sched=1, then scheduler will rescheule this process
SYS_sleep       : process sleep                           -->do_sleep
SYS_kill        : kill process                            -->do_kill-->proc->flags |= PF_EXITING
                                                                 -->wakeup_proc-->do_wait-->do_exit
SYS_getpid      : get the process's pid

*/

// the process set's list
list_entry_t proc_list;

#define HASH_SHIFT 10
#define HASH_LIST_SIZE (1 << HASH_SHIFT)
#define pid_hashfn(x) (hash32(x, HASH_SHIFT))

// has list for process set based on pid
static list_entry_t hash_list[HASH_LIST_SIZE];

// idle proc
struct proc_struct *idleproc = NULL;
// init proc
struct proc_struct *initproc = NULL;
// current proc
struct proc_struct *current = NULL;

static int nr_process = 0;

void kernel_thread_entry(void);
void forkrets(struct trapframe *tf);
void switch_to(struct context *from, struct context *to);

// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct *
alloc_proc(void)
{
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
    if (proc != NULL)
    {
        // LAB4:EXERCISE1 2310675
        proc->state = PROC_UNINIT;              // 进程初始状态设为“未初始化”，等待进一步配置
        proc->pid = -1;                        // -1表示尚未分配PID，后续由get_pid发放唯一编号
        proc->runs = 0;                        // 运行次数清零，便于调度器统计
        proc->kstack = 0;                      // 内核栈稍后由setup_kstack分配
        proc->need_resched = 0;                // 初始不请求调度，让调度器按需设置
        proc->parent = NULL;                   // 尚无父进程关系
        proc->mm = NULL;                       // 内核线程共享内核地址空间，此处先置空
        memset(&(proc->context), 0, sizeof(struct context)); // 清空上下文，保证switch_to时有确定初值
        proc->tf = NULL;                       // trapframe稍后在copy_thread中建立
        proc->pgdir = boot_pgdir_pa;           // 新线程默认使用内核页表，保持同一虚拟空间
        proc->flags = 0;
        memset(proc->name, 0, sizeof(proc->name));
        list_init(&(proc->list_link));         // 将链表指针初始化，便于加入全局进程队列
        list_init(&(proc->hash_link));         // 初始化哈希链表，便于PID快速索引
    }
    return proc;
}

// set_proc_name - set the name of proc
char *
set_proc_name(struct proc_struct *proc, const char *name)
{
    memset(proc->name, 0, sizeof(proc->name));
    return memcpy(proc->name, name, PROC_NAME_LEN);
}

// get_proc_name - get the name of proc
char *
get_proc_name(struct proc_struct *proc)
{
    static char name[PROC_NAME_LEN + 1];
    memset(name, 0, sizeof(name));
    return memcpy(name, proc->name, PROC_NAME_LEN);
}

// get_pid - alloc a unique pid for process
static int
get_pid(void)
{
    static_assert(MAX_PID > MAX_PROCESS);
    struct proc_struct *proc;
    list_entry_t *list = &proc_list, *le;
    static int next_safe = MAX_PID, last_pid = MAX_PID;
    if (++last_pid >= MAX_PID)
    {
        last_pid = 1;
        goto inside;
    }
    if (last_pid >= next_safe)
    {
    inside:
        next_safe = MAX_PID;
    repeat:
        le = list;
        while ((le = list_next(le)) != list)
        {
            proc = le2proc(le, list_link);
            if (proc->pid == last_pid)
            {
                if (++last_pid >= next_safe)
                {
                    if (last_pid >= MAX_PID)
                    {
                        last_pid = 1;
                    }
                    next_safe = MAX_PID;
                    goto repeat;
                }
            }
            else if (proc->pid > last_pid && next_safe > proc->pid)
            {
                next_safe = proc->pid;
            }
        }
    }
    return last_pid;
}

// proc_run - make process "proc" running on cpu
// NOTE: before call switch_to, should load  base addr of "proc"'s new PDT
void proc_run(struct proc_struct *proc)
{
    if (proc != current)
    {
        // LAB4:EXERCISE3 2310675
        // 关中断保证切换过程中上下文、全局变量修改的原子性
        bool intr_flag;
        struct proc_struct *prev = current;
        local_intr_save(intr_flag);
        current = proc;                        // 更新当前运行的进程指针
        lsatp(proc->pgdir);                    // 切换satp寄存器，加载目标进程页表基址
        switch_to(&(prev->context), &(proc->context)); // 保存旧上下文，恢复新上下文
        local_intr_restore(intr_flag);
    }
}

// forkret -- the first kernel entry point of a new thread/process
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
static void
forkret(void)
{
    forkrets(current->tf);
}

// hash_proc - add proc into proc hash_list
static void
hash_proc(struct proc_struct *proc)
{
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
}

// find_proc - find proc frome proc hash_list according to pid
struct proc_struct *
find_proc(int pid)
{
    if (0 < pid && pid < MAX_PID)
    {
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
        while ((le = list_next(le)) != list)
        {
            struct proc_struct *proc = le2proc(le, hash_link);
            if (proc->pid == pid)
            {
                return proc;
            }
        }
    }
    return NULL;
}

// kernel_thread - create a kernel thread using "fn" function
// NOTE: the contents of temp trapframe tf will be copied to
//       proc->tf in do_fork-->copy_thread function
// 2310675: 创建内核线程的包装函数，通过构造临时trapframe来设置线程入口和参数
int kernel_thread(int (*fn)(void *), void *arg, uint32_t clone_flags)
{
    struct trapframe tf;
    memset(&tf, 0, sizeof(struct trapframe));  // 2310675: 清零trapframe，保证未设置字段为0
    tf.gpr.s0 = (uintptr_t)fn;                 // 2310675: s0保存线程函数指针（如init_main）
    tf.gpr.s1 = (uintptr_t)arg;                // 2310675: s1保存函数参数（如"Hello world!!"）
    // 2310675: 设置status为S模式、中断使能，但当前禁用中断（进程切换时会恢复）
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
    tf.epc = (uintptr_t)kernel_thread_entry;   // 2310675: 设置epc为统一的内核线程入口
    return do_fork(clone_flags | CLONE_VM, 0, &tf);  // 2310675: 调用do_fork创建线程
}

// setup_kstack - alloc pages with size KSTACKPAGE as process kernel stack
// 2310675: 为新进程分配内核栈（2个物理页=8KB）
static int
setup_kstack(struct proc_struct *proc)
{
    struct Page *page = alloc_pages(KSTACKPAGE);  // 2310675: 分配KSTACKPAGE（2）个连续物理页
    if (page != NULL)
    {
        proc->kstack = (uintptr_t)page2kva(page);  // 2310675: 保存内核栈的虚拟地址
        return 0;
    }
    return -E_NO_MEM;  // 2310675: 分配失败，返回内存不足错误
}

// put_kstack - free the memory space of process kernel stack
static void
put_kstack(struct proc_struct *proc)
{
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
}

// copy_mm - process "proc" duplicate OR share process "current"'s mm according clone_flags
//         - if clone_flags & CLONE_VM, then "share" ; else "duplicate"
// 2310675: 复制或共享内存管理结构（mm_struct），内核线程共享内核空间，此处简化处理
static int
copy_mm(uint32_t clone_flags, struct proc_struct *proc)
{
    assert(current->mm == NULL);  // 2310675: 确保当前是内核线程（mm为NULL）
    /* do nothing in this project */  // 2310675: 本实验只创建内核线程，无需处理mm
    return 0;
}

// copy_thread - setup the trapframe on the  process's kernel stack top and
//             - setup the kernel entry point and stack of process
// 2310675: 设置新进程的trapframe和context，为首次运行做准备
static void
copy_thread(struct proc_struct *proc, uintptr_t esp, struct trapframe *tf)
{
    // 2310675: 将子进程的trapframe放在内核栈顶，保证异常返回时能恢复完整寄存器
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE - sizeof(struct trapframe));
    *(proc->tf) = *tf;  // 2310675: 复制父进程传入的trapframe（包含s0=fn, s1=arg, epc=kernel_thread_entry）

    // Set a0 to 0 so a child process knows it's just forked
    // 2310675: 子进程第一次调度运行时a0=0，实现fork的"子进程返回0"语义
    proc->tf->gpr.a0 = 0;
    // 2310675: 若esp为0表示创建内核线程，则令sp指向trapframe，否则使用传入的用户栈指针
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;

    // 2310675: 设置context的返回地址为forkret，使switch_to后跳转到统一的trap返回流程
    proc->context.ra = (uintptr_t)forkret;     // 2310675: switch_to的ret将跳转到forkret
    proc->context.sp = (uintptr_t)(proc->tf);  // 2310675: 栈指针指向trapframe，作为forkret的参数
}

/* do_fork -     parent process for a new child process
 * @clone_flags: used to guide how to clone the child process
 * @stack:       the parent's user stack pointer. if stack==0, It means to fork a kernel thread.
 * @tf:          the trapframe info, which will be copied to child process's proc->tf
 */
int do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf)
{
    int ret = -E_NO_FREE_PROC;
    struct proc_struct *proc;
    if (nr_process >= MAX_PROCESS)
    {
        goto fork_out;
    }
    ret = -E_NO_MEM;
    // LAB4:EXERCISE2 2310675
    // 1. 为子进程申请PCB并完成基础字段的默认初始化
    if ((proc = alloc_proc()) == NULL)
    {
        goto fork_out;
    }

    proc->parent = current; // 记录父进程，便于后续wait/回收等处理

    // 2. 分配子进程专用的内核栈
    if ((ret = setup_kstack(proc)) != 0)
    {
        goto bad_fork_cleanup_proc;
    }

    // 3. 复制或共享内存管理结构（内核线程默认共享内核地址空间）
    if ((ret = copy_mm(clone_flags, proc)) != 0)
    {
        goto bad_fork_cleanup_kstack;
    }

    // 4. 按照trapframe内容初始化新进程的寄存器现场
    copy_thread(proc, stack, tf);

    // 5. 分配唯一PID并挂入PID哈希表/进程链表，更新全局进程计数
    proc->pid = get_pid();
    hash_proc(proc);
    list_add(&proc_list, &(proc->list_link));
    nr_process++;

    // 6. 将子进程状态设置为可运行，让调度器能够选择它
    wakeup_proc(proc);
    ret = proc->pid;   // 7. 返回子进程PID给父进程，用于区分父子执行路径
    
fork_out:
    return ret;

bad_fork_cleanup_kstack:
    put_kstack(proc);
bad_fork_cleanup_proc:
    kfree(proc);
    goto fork_out;
}

// do_exit - called by sys_exit
//   1. call exit_mmap & put_pgdir & mm_destroy to free the almost all memory space of process
//   2. set process' state as PROC_ZOMBIE, then call wakeup_proc(parent) to ask parent reclaim itself.
//   3. call scheduler to switch to other process
int do_exit(int error_code)
{
    panic("process exit!!.\n");
}

// init_main - the second kernel thread used to create user_main kernel threads
// 2310675: 第一个真正的内核线程initproc的主函数，本实验只输出欢迎信息
static int
init_main(void *arg)
{
    // 2310675: 输出当前进程信息，验证进程创建成功
    cprintf("this initproc, pid = %d, name = \"%s\"\n", current->pid, get_proc_name(current));
    cprintf("To U: \"%s\".\n", (const char *)arg);  // 2310675: 输出传入的参数"Hello world!!"
    cprintf("To U: \"en.., Bye, Bye. :)\"\n");
    return 0;  // 2310675: 返回后会调用do_exit退出进程
}

// proc_init - set up the first kernel thread idleproc "idle" by itself and
//           - create the second kernel thread init_main
// 2310675: 进程管理初始化函数，创建idleproc（0号）和initproc（1号）两个内核线程
void proc_init(void)
{
    int i;

    // 2310675: 初始化全局进程链表和PID哈希表
    list_init(&proc_list);
    for (i = 0; i < HASH_LIST_SIZE; i++)
    {
        list_init(hash_list + i);
    }

    // 2310675: 分配并初始化idleproc（第0个内核线程）
    if ((idleproc = alloc_proc()) == NULL)
    {
        panic("cannot alloc idleproc.\n");
    }

    // check the proc structure
    int *context_mem = (int *)kmalloc(sizeof(struct context));
    memset(context_mem, 0, sizeof(struct context));
    int context_init_flag = memcmp(&(idleproc->context), context_mem, sizeof(struct context));

    int *proc_name_mem = (int *)kmalloc(PROC_NAME_LEN);
    memset(proc_name_mem, 0, PROC_NAME_LEN);
    int proc_name_flag = memcmp(&(idleproc->name), proc_name_mem, PROC_NAME_LEN);

    if (idleproc->pgdir == boot_pgdir_pa && idleproc->tf == NULL && !context_init_flag && idleproc->state == PROC_UNINIT && idleproc->pid == -1 && idleproc->runs == 0 && idleproc->kstack == 0 && idleproc->need_resched == 0 && idleproc->parent == NULL && idleproc->mm == NULL && idleproc->flags == 0 && !proc_name_flag)
    {
        cprintf("alloc_proc() correct!\n");
    }

    // 2310675: 为idleproc设置特殊属性（pid=0，使用bootstack，立即请求调度）
    idleproc->pid = 0;                         // 2310675: idleproc的PID固定为0
    idleproc->state = PROC_RUNNABLE;           // 2310675: 设置为就绪状态
    idleproc->kstack = (uintptr_t)bootstack;   // 2310675: 使用boot时的栈，不需要重新分配
    idleproc->need_resched = 1;                // 2310675: 立即请求调度，让出CPU给initproc
    set_proc_name(idleproc, "idle");
    nr_process++;

    current = idleproc;  // 2310675: 设置idleproc为当前进程

    // 2310675: 创建第一个真正的内核线程initproc（1号进程）
    int pid = kernel_thread(init_main, "Hello world!!", 0);
    if (pid <= 0)
    {
        panic("create init_main failed.\n");
    }

    // 2310675: 通过PID找到initproc并设置进程名
    initproc = find_proc(pid);
    set_proc_name(initproc, "init");

    assert(idleproc != NULL && idleproc->pid == 0);
    assert(initproc != NULL && initproc->pid == 1);
}

// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
// 2310675: idleproc的主循环，不断检查need_resched并调用调度器
void cpu_idle(void)
{
    while (1)  // 2310675: 无限循环，系统空闲时占位
    {
        if (current->need_resched)  // 2310675: 检查是否需要调度
        {
            schedule();  // 2310675: 调用调度器，切换到其他就绪进程
        }
    }
}
