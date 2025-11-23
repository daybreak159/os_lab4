.text
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void)
	# 2310675: 内核线程统一入口点，此时s0/s1已由trapframe恢复为函数指针和参数
	# s0保存线程入口函数指针（如init_main），s1保存参数（如"Hello world!!"）
	move a0, s1             # 2310675: 按RISC-V调用约定，a0传递第一个参数
	# 调用真正的线程函数，执行完返回继续向下
	jalr s0                 # 2310675: 跳转到s0指向的函数（如init_main），执行线程任务

	# 线程函数返回即视为线程结束，统一走内核的do_exit流程
	jal do_exit             # 2310675: 线程正常结束后调用do_exit清理资源
