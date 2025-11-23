#include <riscv.h>

.text
# void switch_to(struct proc_struct* from, struct proc_struct* to)
# 2310675: 进程上下文切换核心函数，只保存callee-saved寄存器，利用C调用约定优化
.globl switch_to
switch_to:
    # save from's registers
    # 2310675: a0指向旧进程的context结构（&prev->context），保存被调用者保存寄存器
    # 为什么只保存这些寄存器？因为caller-saved寄存器（t0-t6,a0-a7）已由编译器保存到栈上
    STORE ra, 0*REGBYTES(a0)      # 2310675: 保存返回地址，ret时跳转到这里
    STORE sp, 1*REGBYTES(a0)      # 2310675: 保存栈指针，切换回来时恢复栈
    STORE s0, 2*REGBYTES(a0)      # 2310675: 保存s0-s11寄存器（callee-saved）
    STORE s1, 3*REGBYTES(a0)
    STORE s2, 4*REGBYTES(a0)
    STORE s3, 5*REGBYTES(a0)
    STORE s4, 6*REGBYTES(a0)
    STORE s5, 7*REGBYTES(a0)
    STORE s6, 8*REGBYTES(a0)
    STORE s7, 9*REGBYTES(a0)
    STORE s8, 10*REGBYTES(a0)
    STORE s9, 11*REGBYTES(a0)
    STORE s10, 12*REGBYTES(a0)
    STORE s11, 13*REGBYTES(a0)

    # restore to's registers
    # 2310675: a1指向新进程的context结构（&proc->context），恢复目标进程的寄存器状态
    LOAD ra, 0*REGBYTES(a1)       # 2310675: 恢复ra，ret时将跳转到新进程的"返回地址"
    LOAD sp, 1*REGBYTES(a1)       # 2310675: 切换到新进程的栈
    LOAD s0, 2*REGBYTES(a1)       # 2310675: 恢复s0-s11寄存器
    LOAD s1, 3*REGBYTES(a1)
    LOAD s2, 4*REGBYTES(a1)
    LOAD s3, 5*REGBYTES(a1)
    LOAD s4, 6*REGBYTES(a1)
    LOAD s5, 7*REGBYTES(a1)
    LOAD s6, 8*REGBYTES(a1)
    LOAD s7, 9*REGBYTES(a1)
    LOAD s8, 10*REGBYTES(a1)
    LOAD s9, 11*REGBYTES(a1)
    LOAD s10, 12*REGBYTES(a1)
    LOAD s11, 13*REGBYTES(a1)

    ret                           # 2310675: 跳转到ra指向的地址（新进程的执行点）
