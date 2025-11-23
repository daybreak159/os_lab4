#include <riscv.h>

    .macro SAVE_ALL
    .align 2

    csrw sscratch, sp

    addi sp, sp, -36 * REGBYTES
    # save gprs
    STORE  x1,1*REGBYTES(sp)
    STORE  x3,3*REGBYTES(sp)
    STORE  x4,4*REGBYTES(sp)
    STORE  x5,5*REGBYTES(sp)
    STORE  x6,6*REGBYTES(sp)
    STORE  x7,7*REGBYTES(sp)
    STORE  x8,8*REGBYTES(sp)
    STORE  x9,9*REGBYTES(sp)
    STORE  x10,10*REGBYTES(sp)
    STORE  x11,11*REGBYTES(sp)
    STORE  x12,12*REGBYTES(sp)
    STORE  x13,13*REGBYTES(sp)
    STORE  x14,14*REGBYTES(sp)
    STORE  x15,15*REGBYTES(sp)
    STORE  x16,16*REGBYTES(sp)
    STORE  x17,17*REGBYTES(sp)
    STORE  x18,18*REGBYTES(sp)
    STORE  x19,19*REGBYTES(sp)
    STORE  x20,20*REGBYTES(sp)
    STORE  x21,21*REGBYTES(sp)
    STORE  x22,22*REGBYTES(sp)
    STORE  x23,23*REGBYTES(sp)
    STORE  x24,24*REGBYTES(sp)
    STORE  x25,25*REGBYTES(sp)
    STORE  x26,26*REGBYTES(sp)
    STORE  x27,27*REGBYTES(sp)
    STORE  x28,28*REGBYTES(sp)
    STORE  x29,29*REGBYTES(sp)
    STORE  x30,30*REGBYTES(sp)
    STORE  x31,31*REGBYTES(sp)

    # get sr, epc, badvaddr, cause
    csrr s0, sscratch
    csrr s1, sstatus
    csrr s2, sepc
    csrr s3, 0x143
    csrr s4, scause

    STORE s0, 2*REGBYTES(sp)
    STORE s1, 32*REGBYTES(sp)
    STORE s2, 33*REGBYTES(sp)
    STORE s3, 34*REGBYTES(sp)
    STORE s4, 35*REGBYTES(sp)
    .endm

    .macro RESTORE_ALL

    LOAD s1, 32*REGBYTES(sp)
    LOAD s2, 33*REGBYTES(sp)

    csrw sstatus, s1
    csrw sepc, s2

    // restore x registers
    LOAD  x1,1*REGBYTES(sp)
    LOAD  x3,3*REGBYTES(sp)
    LOAD  x4,4*REGBYTES(sp)
    LOAD  x5,5*REGBYTES(sp)
    LOAD  x6,6*REGBYTES(sp)
    LOAD  x7,7*REGBYTES(sp)
    LOAD  x8,8*REGBYTES(sp)
    LOAD  x9,9*REGBYTES(sp)
    LOAD  x10,10*REGBYTES(sp)
    LOAD  x11,11*REGBYTES(sp)
    LOAD  x12,12*REGBYTES(sp)
    LOAD  x13,13*REGBYTES(sp)
    LOAD  x14,14*REGBYTES(sp)
    LOAD  x15,15*REGBYTES(sp)
    LOAD  x16,16*REGBYTES(sp)
    LOAD  x17,17*REGBYTES(sp)
    LOAD  x18,18*REGBYTES(sp)
    LOAD  x19,19*REGBYTES(sp)
    LOAD  x20,20*REGBYTES(sp)
    LOAD  x21,21*REGBYTES(sp)
    LOAD  x22,22*REGBYTES(sp)
    LOAD  x23,23*REGBYTES(sp)
    LOAD  x24,24*REGBYTES(sp)
    LOAD  x25,25*REGBYTES(sp)
    LOAD  x26,26*REGBYTES(sp)
    LOAD  x27,27*REGBYTES(sp)
    LOAD  x28,28*REGBYTES(sp)
    LOAD  x29,29*REGBYTES(sp)
    LOAD  x30,30*REGBYTES(sp)
    LOAD  x31,31*REGBYTES(sp)
    # restore sp last
    LOAD  x2,2*REGBYTES(sp)
    .endm

    .globl __alltraps
__alltraps:
    SAVE_ALL

    move  a0, sp
    jal trap
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
    # go back from supervisor call
    sret
 
    .globl forkrets
forkrets:
    # set stack to this new process's trapframe
    # 2310675: 新创建进程首次运行的统一入口，switch_to返回后会跳转到这里
    # a0指向子线程的trapframe（来自copy_thread中设置的context.sp），将其作为当前栈
    move sp, a0                   # 2310675: sp = proc->tf，指向内核栈顶的trapframe
    # 直接复用通用的中断返回路径，完成寄存器恢复与sret
    j __trapret                   # 2310675: 跳转到__trapret，恢复trapframe中所有寄存器并执行sret
