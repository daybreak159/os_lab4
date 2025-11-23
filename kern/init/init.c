#include <defs.h>
#include <stdio.h>
#include <string.h>
#include <console.h>
#include <kdebug.h>
#include <picirq.h>
#include <trap.h>
#include <clock.h>
#include <intr.h>
#include <pmm.h>
#include <vmm.h>
#include <proc.h>
#include <kmonitor.h>
#include <dtb.h>

int kern_init(void) __attribute__((noreturn));
void grade_backtrace(void);

int kern_init(void)
{
    extern char edata[], end[];
    // 2310675: 清零BSS段，保证未初始化的全局变量初值为0
    memset(edata, 0, end - edata);
    // 2310675: 读取设备树（Device Tree Blob），记录物理内存等硬件信息
    dtb_init();
    // 2310675: 初始化控制台，使得cprintf等函数可以正常输出
    cons_init();

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);

    // 2310675: 打印内核符号信息，包括代码段、数据段等地址范围
    print_kerninfo();

    // grade_backtrace();

    // 2310675: 初始化物理内存管理器，建立空闲页链表，完成页表映射
    pmm_init();

    // 2310675: 初始化中断控制器（PIC），配置中断路由
    pic_init();
    // 2310675: 初始化中断描述符表（IDT），设置stvec寄存器指向中断入口
    idt_init();

    // 2310675: 初始化虚拟内存管理，建立VMA结构，为进程地址空间管理做准备
    vmm_init();
    // 2310675: 初始化进程管理，创建idleproc（0号进程）和initproc（1号进程）
    proc_init();

    // 2310675: 初始化时钟中断，设置第一次时钟事件，启动周期性时钟中断
    clock_init();
    // 2310675: 使能中断，设置sstatus.SIE=1，允许CPU响应中断
    intr_enable();

    // 2310675: 进入idleproc的主循环，当need_resched=1时调用schedule()进行进程调度
    cpu_idle();
}

static void
lab1_print_cur_status(void)
{
    static int round = 0;
    round++;
}
