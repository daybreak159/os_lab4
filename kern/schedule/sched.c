#include <list.h>
#include <sync.h>
#include <proc.h>
#include <sched.h>
#include <assert.h>

void
wakeup_proc(struct proc_struct *proc) {
    assert(proc->state != PROC_ZOMBIE && proc->state != PROC_RUNNABLE);
    proc->state = PROC_RUNNABLE; // 从睡眠/新建态切换到就绪态，等待调度
}

void
schedule(void) {
    bool intr_flag;
    list_entry_t *le, *last;
    struct proc_struct *next = NULL;
    local_intr_save(intr_flag); // 调度过程需互斥，先关闭中断
    {
        current->need_resched = 0; // 清除当前线程的调度请求
        // idleproc从链表头开始找，其余线程从自身之后开始，实现简单轮转
        last = (current == idleproc) ? &proc_list : &(current->list_link);
        le = last;
        do {
            if ((le = list_next(le)) != &proc_list) {
                next = le2proc(le, list_link);
                if (next->state == PROC_RUNNABLE) { // 找到就绪线程立即退出循环
                    break;
                }
            }
        } while (le != last);
        if (next == NULL || next->state != PROC_RUNNABLE) {
            next = idleproc; // 没有就绪线程时回退到idleproc占位
        }
        next->runs ++; // 统计线程被调度次数
        if (next != current) {
            proc_run(next); // 执行真正的上下文切换
        }
    }
    local_intr_restore(intr_flag);
}
