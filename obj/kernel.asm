
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	00009297          	auipc	t0,0x9
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0209000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	00009297          	auipc	t0,0x9
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0209008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)
    
    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c02082b7          	lui	t0,0xc0208
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc020001c:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200020:	037a                	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc0200022:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc0200026:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc020002a:	fff0031b          	addiw	t1,zero,-1
ffffffffc020002e:	137e                	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc0200030:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc0200034:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200038:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc020003c:	c0208137          	lui	sp,0xc0208

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200040:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200044:	04a28293          	addi	t0,t0,74 # ffffffffc020004a <kern_init>
    jr t0
ffffffffc0200048:	8282                	jr	t0

ffffffffc020004a <kern_init>:

int kern_init(void)
{
    extern char edata[], end[];
    // 2310675: 清零BSS段，保证未初始化的全局变量初值为0
    memset(edata, 0, end - edata);
ffffffffc020004a:	00009517          	auipc	a0,0x9
ffffffffc020004e:	fe650513          	addi	a0,a0,-26 # ffffffffc0209030 <buf>
ffffffffc0200052:	0000d617          	auipc	a2,0xd
ffffffffc0200056:	49a60613          	addi	a2,a2,1178 # ffffffffc020d4ec <end>
{
ffffffffc020005a:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc020005c:	8e09                	sub	a2,a2,a0
ffffffffc020005e:	4581                	li	a1,0
{
ffffffffc0200060:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc0200062:	631030ef          	jal	ra,ffffffffc0203e92 <memset>
    // 2310675: 读取设备树（Device Tree Blob），记录物理内存等硬件信息
    dtb_init();
ffffffffc0200066:	514000ef          	jal	ra,ffffffffc020057a <dtb_init>
    // 2310675: 初始化控制台，使得cprintf等函数可以正常输出
    cons_init();
ffffffffc020006a:	49e000ef          	jal	ra,ffffffffc0200508 <cons_init>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc020006e:	00004597          	auipc	a1,0x4
ffffffffc0200072:	e7258593          	addi	a1,a1,-398 # ffffffffc0203ee0 <etext>
ffffffffc0200076:	00004517          	auipc	a0,0x4
ffffffffc020007a:	e8a50513          	addi	a0,a0,-374 # ffffffffc0203f00 <etext+0x20>
ffffffffc020007e:	116000ef          	jal	ra,ffffffffc0200194 <cprintf>

    // 2310675: 打印内核符号信息，包括代码段、数据段等地址范围
    print_kerninfo();
ffffffffc0200082:	15a000ef          	jal	ra,ffffffffc02001dc <print_kerninfo>

    // grade_backtrace();

    // 2310675: 初始化物理内存管理器，建立空闲页链表，完成页表映射
    pmm_init();
ffffffffc0200086:	0f4020ef          	jal	ra,ffffffffc020217a <pmm_init>

    // 2310675: 初始化中断控制器（PIC），配置中断路由
    pic_init();
ffffffffc020008a:	0ad000ef          	jal	ra,ffffffffc0200936 <pic_init>
    // 2310675: 初始化中断描述符表（IDT），设置stvec寄存器指向中断入口
    idt_init();
ffffffffc020008e:	0ab000ef          	jal	ra,ffffffffc0200938 <idt_init>

    // 2310675: 初始化虚拟内存管理，建立VMA结构，为进程地址空间管理做准备
    vmm_init();
ffffffffc0200092:	65d020ef          	jal	ra,ffffffffc0202eee <vmm_init>
    // 2310675: 初始化进程管理，创建idleproc（0号进程）和initproc（1号进程）
    proc_init();
ffffffffc0200096:	5bc030ef          	jal	ra,ffffffffc0203652 <proc_init>

    // 2310675: 初始化时钟中断，设置第一次时钟事件，启动周期性时钟中断
    clock_init();
ffffffffc020009a:	41c000ef          	jal	ra,ffffffffc02004b6 <clock_init>
    // 2310675: 使能中断，设置sstatus.SIE=1，允许CPU响应中断
    intr_enable();
ffffffffc020009e:	08d000ef          	jal	ra,ffffffffc020092a <intr_enable>

    // 2310675: 进入idleproc的主循环，当need_resched=1时调用schedule()进行进程调度
    cpu_idle();
ffffffffc02000a2:	7fe030ef          	jal	ra,ffffffffc02038a0 <cpu_idle>

ffffffffc02000a6 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc02000a6:	715d                	addi	sp,sp,-80
ffffffffc02000a8:	e486                	sd	ra,72(sp)
ffffffffc02000aa:	e0a6                	sd	s1,64(sp)
ffffffffc02000ac:	fc4a                	sd	s2,56(sp)
ffffffffc02000ae:	f84e                	sd	s3,48(sp)
ffffffffc02000b0:	f452                	sd	s4,40(sp)
ffffffffc02000b2:	f056                	sd	s5,32(sp)
ffffffffc02000b4:	ec5a                	sd	s6,24(sp)
ffffffffc02000b6:	e85e                	sd	s7,16(sp)
    if (prompt != NULL) {
ffffffffc02000b8:	c901                	beqz	a0,ffffffffc02000c8 <readline+0x22>
ffffffffc02000ba:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc02000bc:	00004517          	auipc	a0,0x4
ffffffffc02000c0:	e4c50513          	addi	a0,a0,-436 # ffffffffc0203f08 <etext+0x28>
ffffffffc02000c4:	0d0000ef          	jal	ra,ffffffffc0200194 <cprintf>
readline(const char *prompt) {
ffffffffc02000c8:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000ca:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc02000cc:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc02000ce:	4aa9                	li	s5,10
ffffffffc02000d0:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc02000d2:	00009b97          	auipc	s7,0x9
ffffffffc02000d6:	f5eb8b93          	addi	s7,s7,-162 # ffffffffc0209030 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000da:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc02000de:	0ee000ef          	jal	ra,ffffffffc02001cc <getchar>
        if (c < 0) {
ffffffffc02000e2:	00054a63          	bltz	a0,ffffffffc02000f6 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000e6:	00a95a63          	bge	s2,a0,ffffffffc02000fa <readline+0x54>
ffffffffc02000ea:	029a5263          	bge	s4,s1,ffffffffc020010e <readline+0x68>
        c = getchar();
ffffffffc02000ee:	0de000ef          	jal	ra,ffffffffc02001cc <getchar>
        if (c < 0) {
ffffffffc02000f2:	fe055ae3          	bgez	a0,ffffffffc02000e6 <readline+0x40>
            return NULL;
ffffffffc02000f6:	4501                	li	a0,0
ffffffffc02000f8:	a091                	j	ffffffffc020013c <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc02000fa:	03351463          	bne	a0,s3,ffffffffc0200122 <readline+0x7c>
ffffffffc02000fe:	e8a9                	bnez	s1,ffffffffc0200150 <readline+0xaa>
        c = getchar();
ffffffffc0200100:	0cc000ef          	jal	ra,ffffffffc02001cc <getchar>
        if (c < 0) {
ffffffffc0200104:	fe0549e3          	bltz	a0,ffffffffc02000f6 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0200108:	fea959e3          	bge	s2,a0,ffffffffc02000fa <readline+0x54>
ffffffffc020010c:	4481                	li	s1,0
            cputchar(c);
ffffffffc020010e:	e42a                	sd	a0,8(sp)
ffffffffc0200110:	0ba000ef          	jal	ra,ffffffffc02001ca <cputchar>
            buf[i ++] = c;
ffffffffc0200114:	6522                	ld	a0,8(sp)
ffffffffc0200116:	009b87b3          	add	a5,s7,s1
ffffffffc020011a:	2485                	addiw	s1,s1,1
ffffffffc020011c:	00a78023          	sb	a0,0(a5)
ffffffffc0200120:	bf7d                	j	ffffffffc02000de <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc0200122:	01550463          	beq	a0,s5,ffffffffc020012a <readline+0x84>
ffffffffc0200126:	fb651ce3          	bne	a0,s6,ffffffffc02000de <readline+0x38>
            cputchar(c);
ffffffffc020012a:	0a0000ef          	jal	ra,ffffffffc02001ca <cputchar>
            buf[i] = '\0';
ffffffffc020012e:	00009517          	auipc	a0,0x9
ffffffffc0200132:	f0250513          	addi	a0,a0,-254 # ffffffffc0209030 <buf>
ffffffffc0200136:	94aa                	add	s1,s1,a0
ffffffffc0200138:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc020013c:	60a6                	ld	ra,72(sp)
ffffffffc020013e:	6486                	ld	s1,64(sp)
ffffffffc0200140:	7962                	ld	s2,56(sp)
ffffffffc0200142:	79c2                	ld	s3,48(sp)
ffffffffc0200144:	7a22                	ld	s4,40(sp)
ffffffffc0200146:	7a82                	ld	s5,32(sp)
ffffffffc0200148:	6b62                	ld	s6,24(sp)
ffffffffc020014a:	6bc2                	ld	s7,16(sp)
ffffffffc020014c:	6161                	addi	sp,sp,80
ffffffffc020014e:	8082                	ret
            cputchar(c);
ffffffffc0200150:	4521                	li	a0,8
ffffffffc0200152:	078000ef          	jal	ra,ffffffffc02001ca <cputchar>
            i --;
ffffffffc0200156:	34fd                	addiw	s1,s1,-1
ffffffffc0200158:	b759                	j	ffffffffc02000de <readline+0x38>

ffffffffc020015a <cputch>:
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt)
{
ffffffffc020015a:	1141                	addi	sp,sp,-16
ffffffffc020015c:	e022                	sd	s0,0(sp)
ffffffffc020015e:	e406                	sd	ra,8(sp)
ffffffffc0200160:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc0200162:	3a8000ef          	jal	ra,ffffffffc020050a <cons_putc>
    (*cnt)++;
ffffffffc0200166:	401c                	lw	a5,0(s0)
}
ffffffffc0200168:	60a2                	ld	ra,8(sp)
    (*cnt)++;
ffffffffc020016a:	2785                	addiw	a5,a5,1
ffffffffc020016c:	c01c                	sw	a5,0(s0)
}
ffffffffc020016e:	6402                	ld	s0,0(sp)
ffffffffc0200170:	0141                	addi	sp,sp,16
ffffffffc0200172:	8082                	ret

ffffffffc0200174 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int vcprintf(const char *fmt, va_list ap)
{
ffffffffc0200174:	1101                	addi	sp,sp,-32
ffffffffc0200176:	862a                	mv	a2,a0
ffffffffc0200178:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc020017a:	00000517          	auipc	a0,0x0
ffffffffc020017e:	fe050513          	addi	a0,a0,-32 # ffffffffc020015a <cputch>
ffffffffc0200182:	006c                	addi	a1,sp,12
{
ffffffffc0200184:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc0200186:	c602                	sw	zero,12(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc0200188:	0e7030ef          	jal	ra,ffffffffc0203a6e <vprintfmt>
    return cnt;
}
ffffffffc020018c:	60e2                	ld	ra,24(sp)
ffffffffc020018e:	4532                	lw	a0,12(sp)
ffffffffc0200190:	6105                	addi	sp,sp,32
ffffffffc0200192:	8082                	ret

ffffffffc0200194 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int cprintf(const char *fmt, ...)
{
ffffffffc0200194:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc0200196:	02810313          	addi	t1,sp,40 # ffffffffc0208028 <boot_page_table_sv39+0x28>
{
ffffffffc020019a:	8e2a                	mv	t3,a0
ffffffffc020019c:	f42e                	sd	a1,40(sp)
ffffffffc020019e:	f832                	sd	a2,48(sp)
ffffffffc02001a0:	fc36                	sd	a3,56(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02001a2:	00000517          	auipc	a0,0x0
ffffffffc02001a6:	fb850513          	addi	a0,a0,-72 # ffffffffc020015a <cputch>
ffffffffc02001aa:	004c                	addi	a1,sp,4
ffffffffc02001ac:	869a                	mv	a3,t1
ffffffffc02001ae:	8672                	mv	a2,t3
{
ffffffffc02001b0:	ec06                	sd	ra,24(sp)
ffffffffc02001b2:	e0ba                	sd	a4,64(sp)
ffffffffc02001b4:	e4be                	sd	a5,72(sp)
ffffffffc02001b6:	e8c2                	sd	a6,80(sp)
ffffffffc02001b8:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02001ba:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc02001bc:	c202                	sw	zero,4(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02001be:	0b1030ef          	jal	ra,ffffffffc0203a6e <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02001c2:	60e2                	ld	ra,24(sp)
ffffffffc02001c4:	4512                	lw	a0,4(sp)
ffffffffc02001c6:	6125                	addi	sp,sp,96
ffffffffc02001c8:	8082                	ret

ffffffffc02001ca <cputchar>:

/* cputchar - writes a single character to stdout */
void cputchar(int c)
{
    cons_putc(c);
ffffffffc02001ca:	a681                	j	ffffffffc020050a <cons_putc>

ffffffffc02001cc <getchar>:
}

/* getchar - reads a single non-zero character from stdin */
int getchar(void)
{
ffffffffc02001cc:	1141                	addi	sp,sp,-16
ffffffffc02001ce:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc02001d0:	36e000ef          	jal	ra,ffffffffc020053e <cons_getc>
ffffffffc02001d4:	dd75                	beqz	a0,ffffffffc02001d0 <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc02001d6:	60a2                	ld	ra,8(sp)
ffffffffc02001d8:	0141                	addi	sp,sp,16
ffffffffc02001da:	8082                	ret

ffffffffc02001dc <print_kerninfo>:
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void)
{
ffffffffc02001dc:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc02001de:	00004517          	auipc	a0,0x4
ffffffffc02001e2:	d3250513          	addi	a0,a0,-718 # ffffffffc0203f10 <etext+0x30>
{
ffffffffc02001e6:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc02001e8:	fadff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc02001ec:	00000597          	auipc	a1,0x0
ffffffffc02001f0:	e5e58593          	addi	a1,a1,-418 # ffffffffc020004a <kern_init>
ffffffffc02001f4:	00004517          	auipc	a0,0x4
ffffffffc02001f8:	d3c50513          	addi	a0,a0,-708 # ffffffffc0203f30 <etext+0x50>
ffffffffc02001fc:	f99ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc0200200:	00004597          	auipc	a1,0x4
ffffffffc0200204:	ce058593          	addi	a1,a1,-800 # ffffffffc0203ee0 <etext>
ffffffffc0200208:	00004517          	auipc	a0,0x4
ffffffffc020020c:	d4850513          	addi	a0,a0,-696 # ffffffffc0203f50 <etext+0x70>
ffffffffc0200210:	f85ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc0200214:	00009597          	auipc	a1,0x9
ffffffffc0200218:	e1c58593          	addi	a1,a1,-484 # ffffffffc0209030 <buf>
ffffffffc020021c:	00004517          	auipc	a0,0x4
ffffffffc0200220:	d5450513          	addi	a0,a0,-684 # ffffffffc0203f70 <etext+0x90>
ffffffffc0200224:	f71ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc0200228:	0000d597          	auipc	a1,0xd
ffffffffc020022c:	2c458593          	addi	a1,a1,708 # ffffffffc020d4ec <end>
ffffffffc0200230:	00004517          	auipc	a0,0x4
ffffffffc0200234:	d6050513          	addi	a0,a0,-672 # ffffffffc0203f90 <etext+0xb0>
ffffffffc0200238:	f5dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc020023c:	0000d597          	auipc	a1,0xd
ffffffffc0200240:	6af58593          	addi	a1,a1,1711 # ffffffffc020d8eb <end+0x3ff>
ffffffffc0200244:	00000797          	auipc	a5,0x0
ffffffffc0200248:	e0678793          	addi	a5,a5,-506 # ffffffffc020004a <kern_init>
ffffffffc020024c:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200250:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc0200254:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200256:	3ff5f593          	andi	a1,a1,1023
ffffffffc020025a:	95be                	add	a1,a1,a5
ffffffffc020025c:	85a9                	srai	a1,a1,0xa
ffffffffc020025e:	00004517          	auipc	a0,0x4
ffffffffc0200262:	d5250513          	addi	a0,a0,-686 # ffffffffc0203fb0 <etext+0xd0>
}
ffffffffc0200266:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200268:	b735                	j	ffffffffc0200194 <cprintf>

ffffffffc020026a <print_stackframe>:
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void)
{
ffffffffc020026a:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc020026c:	00004617          	auipc	a2,0x4
ffffffffc0200270:	d7460613          	addi	a2,a2,-652 # ffffffffc0203fe0 <etext+0x100>
ffffffffc0200274:	04900593          	li	a1,73
ffffffffc0200278:	00004517          	auipc	a0,0x4
ffffffffc020027c:	d8050513          	addi	a0,a0,-640 # ffffffffc0203ff8 <etext+0x118>
{
ffffffffc0200280:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc0200282:	1d8000ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0200286 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200286:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200288:	00004617          	auipc	a2,0x4
ffffffffc020028c:	d8860613          	addi	a2,a2,-632 # ffffffffc0204010 <etext+0x130>
ffffffffc0200290:	00004597          	auipc	a1,0x4
ffffffffc0200294:	da058593          	addi	a1,a1,-608 # ffffffffc0204030 <etext+0x150>
ffffffffc0200298:	00004517          	auipc	a0,0x4
ffffffffc020029c:	da050513          	addi	a0,a0,-608 # ffffffffc0204038 <etext+0x158>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002a0:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002a2:	ef3ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc02002a6:	00004617          	auipc	a2,0x4
ffffffffc02002aa:	da260613          	addi	a2,a2,-606 # ffffffffc0204048 <etext+0x168>
ffffffffc02002ae:	00004597          	auipc	a1,0x4
ffffffffc02002b2:	dc258593          	addi	a1,a1,-574 # ffffffffc0204070 <etext+0x190>
ffffffffc02002b6:	00004517          	auipc	a0,0x4
ffffffffc02002ba:	d8250513          	addi	a0,a0,-638 # ffffffffc0204038 <etext+0x158>
ffffffffc02002be:	ed7ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc02002c2:	00004617          	auipc	a2,0x4
ffffffffc02002c6:	dbe60613          	addi	a2,a2,-578 # ffffffffc0204080 <etext+0x1a0>
ffffffffc02002ca:	00004597          	auipc	a1,0x4
ffffffffc02002ce:	dd658593          	addi	a1,a1,-554 # ffffffffc02040a0 <etext+0x1c0>
ffffffffc02002d2:	00004517          	auipc	a0,0x4
ffffffffc02002d6:	d6650513          	addi	a0,a0,-666 # ffffffffc0204038 <etext+0x158>
ffffffffc02002da:	ebbff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    }
    return 0;
}
ffffffffc02002de:	60a2                	ld	ra,8(sp)
ffffffffc02002e0:	4501                	li	a0,0
ffffffffc02002e2:	0141                	addi	sp,sp,16
ffffffffc02002e4:	8082                	ret

ffffffffc02002e6 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002e6:	1141                	addi	sp,sp,-16
ffffffffc02002e8:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc02002ea:	ef3ff0ef          	jal	ra,ffffffffc02001dc <print_kerninfo>
    return 0;
}
ffffffffc02002ee:	60a2                	ld	ra,8(sp)
ffffffffc02002f0:	4501                	li	a0,0
ffffffffc02002f2:	0141                	addi	sp,sp,16
ffffffffc02002f4:	8082                	ret

ffffffffc02002f6 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002f6:	1141                	addi	sp,sp,-16
ffffffffc02002f8:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc02002fa:	f71ff0ef          	jal	ra,ffffffffc020026a <print_stackframe>
    return 0;
}
ffffffffc02002fe:	60a2                	ld	ra,8(sp)
ffffffffc0200300:	4501                	li	a0,0
ffffffffc0200302:	0141                	addi	sp,sp,16
ffffffffc0200304:	8082                	ret

ffffffffc0200306 <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc0200306:	7115                	addi	sp,sp,-224
ffffffffc0200308:	ed5e                	sd	s7,152(sp)
ffffffffc020030a:	8baa                	mv	s7,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020030c:	00004517          	auipc	a0,0x4
ffffffffc0200310:	da450513          	addi	a0,a0,-604 # ffffffffc02040b0 <etext+0x1d0>
kmonitor(struct trapframe *tf) {
ffffffffc0200314:	ed86                	sd	ra,216(sp)
ffffffffc0200316:	e9a2                	sd	s0,208(sp)
ffffffffc0200318:	e5a6                	sd	s1,200(sp)
ffffffffc020031a:	e1ca                	sd	s2,192(sp)
ffffffffc020031c:	fd4e                	sd	s3,184(sp)
ffffffffc020031e:	f952                	sd	s4,176(sp)
ffffffffc0200320:	f556                	sd	s5,168(sp)
ffffffffc0200322:	f15a                	sd	s6,160(sp)
ffffffffc0200324:	e962                	sd	s8,144(sp)
ffffffffc0200326:	e566                	sd	s9,136(sp)
ffffffffc0200328:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020032a:	e6bff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc020032e:	00004517          	auipc	a0,0x4
ffffffffc0200332:	daa50513          	addi	a0,a0,-598 # ffffffffc02040d8 <etext+0x1f8>
ffffffffc0200336:	e5fff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    if (tf != NULL) {
ffffffffc020033a:	000b8563          	beqz	s7,ffffffffc0200344 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc020033e:	855e                	mv	a0,s7
ffffffffc0200340:	7e0000ef          	jal	ra,ffffffffc0200b20 <print_trapframe>
#endif
}

static inline void sbi_shutdown(void)
{
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc0200344:	4501                	li	a0,0
ffffffffc0200346:	4581                	li	a1,0
ffffffffc0200348:	4601                	li	a2,0
ffffffffc020034a:	48a1                	li	a7,8
ffffffffc020034c:	00000073          	ecall
ffffffffc0200350:	00004c17          	auipc	s8,0x4
ffffffffc0200354:	df8c0c13          	addi	s8,s8,-520 # ffffffffc0204148 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc0200358:	00004917          	auipc	s2,0x4
ffffffffc020035c:	da890913          	addi	s2,s2,-600 # ffffffffc0204100 <etext+0x220>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200360:	00004497          	auipc	s1,0x4
ffffffffc0200364:	da848493          	addi	s1,s1,-600 # ffffffffc0204108 <etext+0x228>
        if (argc == MAXARGS - 1) {
ffffffffc0200368:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc020036a:	00004b17          	auipc	s6,0x4
ffffffffc020036e:	da6b0b13          	addi	s6,s6,-602 # ffffffffc0204110 <etext+0x230>
        argv[argc ++] = buf;
ffffffffc0200372:	00004a17          	auipc	s4,0x4
ffffffffc0200376:	cbea0a13          	addi	s4,s4,-834 # ffffffffc0204030 <etext+0x150>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020037a:	4a8d                	li	s5,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc020037c:	854a                	mv	a0,s2
ffffffffc020037e:	d29ff0ef          	jal	ra,ffffffffc02000a6 <readline>
ffffffffc0200382:	842a                	mv	s0,a0
ffffffffc0200384:	dd65                	beqz	a0,ffffffffc020037c <kmonitor+0x76>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200386:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc020038a:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020038c:	e1bd                	bnez	a1,ffffffffc02003f2 <kmonitor+0xec>
    if (argc == 0) {
ffffffffc020038e:	fe0c87e3          	beqz	s9,ffffffffc020037c <kmonitor+0x76>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200392:	6582                	ld	a1,0(sp)
ffffffffc0200394:	00004d17          	auipc	s10,0x4
ffffffffc0200398:	db4d0d13          	addi	s10,s10,-588 # ffffffffc0204148 <commands>
        argv[argc ++] = buf;
ffffffffc020039c:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020039e:	4401                	li	s0,0
ffffffffc02003a0:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003a2:	297030ef          	jal	ra,ffffffffc0203e38 <strcmp>
ffffffffc02003a6:	c919                	beqz	a0,ffffffffc02003bc <kmonitor+0xb6>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003a8:	2405                	addiw	s0,s0,1
ffffffffc02003aa:	0b540063          	beq	s0,s5,ffffffffc020044a <kmonitor+0x144>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003ae:	000d3503          	ld	a0,0(s10)
ffffffffc02003b2:	6582                	ld	a1,0(sp)
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003b4:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003b6:	283030ef          	jal	ra,ffffffffc0203e38 <strcmp>
ffffffffc02003ba:	f57d                	bnez	a0,ffffffffc02003a8 <kmonitor+0xa2>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc02003bc:	00141793          	slli	a5,s0,0x1
ffffffffc02003c0:	97a2                	add	a5,a5,s0
ffffffffc02003c2:	078e                	slli	a5,a5,0x3
ffffffffc02003c4:	97e2                	add	a5,a5,s8
ffffffffc02003c6:	6b9c                	ld	a5,16(a5)
ffffffffc02003c8:	865e                	mv	a2,s7
ffffffffc02003ca:	002c                	addi	a1,sp,8
ffffffffc02003cc:	fffc851b          	addiw	a0,s9,-1
ffffffffc02003d0:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc02003d2:	fa0555e3          	bgez	a0,ffffffffc020037c <kmonitor+0x76>
}
ffffffffc02003d6:	60ee                	ld	ra,216(sp)
ffffffffc02003d8:	644e                	ld	s0,208(sp)
ffffffffc02003da:	64ae                	ld	s1,200(sp)
ffffffffc02003dc:	690e                	ld	s2,192(sp)
ffffffffc02003de:	79ea                	ld	s3,184(sp)
ffffffffc02003e0:	7a4a                	ld	s4,176(sp)
ffffffffc02003e2:	7aaa                	ld	s5,168(sp)
ffffffffc02003e4:	7b0a                	ld	s6,160(sp)
ffffffffc02003e6:	6bea                	ld	s7,152(sp)
ffffffffc02003e8:	6c4a                	ld	s8,144(sp)
ffffffffc02003ea:	6caa                	ld	s9,136(sp)
ffffffffc02003ec:	6d0a                	ld	s10,128(sp)
ffffffffc02003ee:	612d                	addi	sp,sp,224
ffffffffc02003f0:	8082                	ret
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003f2:	8526                	mv	a0,s1
ffffffffc02003f4:	289030ef          	jal	ra,ffffffffc0203e7c <strchr>
ffffffffc02003f8:	c901                	beqz	a0,ffffffffc0200408 <kmonitor+0x102>
ffffffffc02003fa:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc02003fe:	00040023          	sb	zero,0(s0)
ffffffffc0200402:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200404:	d5c9                	beqz	a1,ffffffffc020038e <kmonitor+0x88>
ffffffffc0200406:	b7f5                	j	ffffffffc02003f2 <kmonitor+0xec>
        if (*buf == '\0') {
ffffffffc0200408:	00044783          	lbu	a5,0(s0)
ffffffffc020040c:	d3c9                	beqz	a5,ffffffffc020038e <kmonitor+0x88>
        if (argc == MAXARGS - 1) {
ffffffffc020040e:	033c8963          	beq	s9,s3,ffffffffc0200440 <kmonitor+0x13a>
        argv[argc ++] = buf;
ffffffffc0200412:	003c9793          	slli	a5,s9,0x3
ffffffffc0200416:	0118                	addi	a4,sp,128
ffffffffc0200418:	97ba                	add	a5,a5,a4
ffffffffc020041a:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020041e:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc0200422:	2c85                	addiw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200424:	e591                	bnez	a1,ffffffffc0200430 <kmonitor+0x12a>
ffffffffc0200426:	b7b5                	j	ffffffffc0200392 <kmonitor+0x8c>
ffffffffc0200428:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc020042c:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020042e:	d1a5                	beqz	a1,ffffffffc020038e <kmonitor+0x88>
ffffffffc0200430:	8526                	mv	a0,s1
ffffffffc0200432:	24b030ef          	jal	ra,ffffffffc0203e7c <strchr>
ffffffffc0200436:	d96d                	beqz	a0,ffffffffc0200428 <kmonitor+0x122>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200438:	00044583          	lbu	a1,0(s0)
ffffffffc020043c:	d9a9                	beqz	a1,ffffffffc020038e <kmonitor+0x88>
ffffffffc020043e:	bf55                	j	ffffffffc02003f2 <kmonitor+0xec>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200440:	45c1                	li	a1,16
ffffffffc0200442:	855a                	mv	a0,s6
ffffffffc0200444:	d51ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc0200448:	b7e9                	j	ffffffffc0200412 <kmonitor+0x10c>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc020044a:	6582                	ld	a1,0(sp)
ffffffffc020044c:	00004517          	auipc	a0,0x4
ffffffffc0200450:	ce450513          	addi	a0,a0,-796 # ffffffffc0204130 <etext+0x250>
ffffffffc0200454:	d41ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    return 0;
ffffffffc0200458:	b715                	j	ffffffffc020037c <kmonitor+0x76>

ffffffffc020045a <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc020045a:	0000d317          	auipc	t1,0xd
ffffffffc020045e:	00e30313          	addi	t1,t1,14 # ffffffffc020d468 <is_panic>
ffffffffc0200462:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc0200466:	715d                	addi	sp,sp,-80
ffffffffc0200468:	ec06                	sd	ra,24(sp)
ffffffffc020046a:	e822                	sd	s0,16(sp)
ffffffffc020046c:	f436                	sd	a3,40(sp)
ffffffffc020046e:	f83a                	sd	a4,48(sp)
ffffffffc0200470:	fc3e                	sd	a5,56(sp)
ffffffffc0200472:	e0c2                	sd	a6,64(sp)
ffffffffc0200474:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc0200476:	020e1a63          	bnez	t3,ffffffffc02004aa <__panic+0x50>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc020047a:	4785                	li	a5,1
ffffffffc020047c:	00f32023          	sw	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc0200480:	8432                	mv	s0,a2
ffffffffc0200482:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200484:	862e                	mv	a2,a1
ffffffffc0200486:	85aa                	mv	a1,a0
ffffffffc0200488:	00004517          	auipc	a0,0x4
ffffffffc020048c:	d0850513          	addi	a0,a0,-760 # ffffffffc0204190 <commands+0x48>
    va_start(ap, fmt);
ffffffffc0200490:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200492:	d03ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200496:	65a2                	ld	a1,8(sp)
ffffffffc0200498:	8522                	mv	a0,s0
ffffffffc020049a:	cdbff0ef          	jal	ra,ffffffffc0200174 <vcprintf>
    cprintf("\n");
ffffffffc020049e:	00005517          	auipc	a0,0x5
ffffffffc02004a2:	dc250513          	addi	a0,a0,-574 # ffffffffc0205260 <default_pmm_manager+0x530>
ffffffffc02004a6:	cefff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc02004aa:	486000ef          	jal	ra,ffffffffc0200930 <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc02004ae:	4501                	li	a0,0
ffffffffc02004b0:	e57ff0ef          	jal	ra,ffffffffc0200306 <kmonitor>
    while (1) {
ffffffffc02004b4:	bfed                	j	ffffffffc02004ae <__panic+0x54>

ffffffffc02004b6 <clock_init>:
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
    // divided by 500 when using Spike(2MHz)
    // divided by 100 when using QEMU(10MHz)
    timebase = 1e7 / 100;
ffffffffc02004b6:	67e1                	lui	a5,0x18
ffffffffc02004b8:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc02004bc:	0000d717          	auipc	a4,0xd
ffffffffc02004c0:	faf73e23          	sd	a5,-68(a4) # ffffffffc020d478 <timebase>
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc02004c4:	c0102573          	rdtime	a0
	SBI_CALL_1(SBI_SET_TIMER, stime_value);
ffffffffc02004c8:	4581                	li	a1,0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc02004ca:	953e                	add	a0,a0,a5
ffffffffc02004cc:	4601                	li	a2,0
ffffffffc02004ce:	4881                	li	a7,0
ffffffffc02004d0:	00000073          	ecall
    set_csr(sie, MIP_STIP);
ffffffffc02004d4:	02000793          	li	a5,32
ffffffffc02004d8:	1047a7f3          	csrrs	a5,sie,a5
    cprintf("++ setup timer interrupts\n");
ffffffffc02004dc:	00004517          	auipc	a0,0x4
ffffffffc02004e0:	cd450513          	addi	a0,a0,-812 # ffffffffc02041b0 <commands+0x68>
    ticks = 0;
ffffffffc02004e4:	0000d797          	auipc	a5,0xd
ffffffffc02004e8:	f807b623          	sd	zero,-116(a5) # ffffffffc020d470 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc02004ec:	b165                	j	ffffffffc0200194 <cprintf>

ffffffffc02004ee <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc02004ee:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc02004f2:	0000d797          	auipc	a5,0xd
ffffffffc02004f6:	f867b783          	ld	a5,-122(a5) # ffffffffc020d478 <timebase>
ffffffffc02004fa:	953e                	add	a0,a0,a5
ffffffffc02004fc:	4581                	li	a1,0
ffffffffc02004fe:	4601                	li	a2,0
ffffffffc0200500:	4881                	li	a7,0
ffffffffc0200502:	00000073          	ecall
ffffffffc0200506:	8082                	ret

ffffffffc0200508 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200508:	8082                	ret

ffffffffc020050a <cons_putc>:
#include <defs.h>
#include <intr.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020050a:	100027f3          	csrr	a5,sstatus
ffffffffc020050e:	8b89                	andi	a5,a5,2
	SBI_CALL_1(SBI_CONSOLE_PUTCHAR, ch);
ffffffffc0200510:	0ff57513          	zext.b	a0,a0
ffffffffc0200514:	e799                	bnez	a5,ffffffffc0200522 <cons_putc+0x18>
ffffffffc0200516:	4581                	li	a1,0
ffffffffc0200518:	4601                	li	a2,0
ffffffffc020051a:	4885                	li	a7,1
ffffffffc020051c:	00000073          	ecall
    }
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
ffffffffc0200520:	8082                	ret

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) {
ffffffffc0200522:	1101                	addi	sp,sp,-32
ffffffffc0200524:	ec06                	sd	ra,24(sp)
ffffffffc0200526:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0200528:	408000ef          	jal	ra,ffffffffc0200930 <intr_disable>
ffffffffc020052c:	6522                	ld	a0,8(sp)
ffffffffc020052e:	4581                	li	a1,0
ffffffffc0200530:	4601                	li	a2,0
ffffffffc0200532:	4885                	li	a7,1
ffffffffc0200534:	00000073          	ecall
    local_intr_save(intr_flag);
    {
        sbi_console_putchar((unsigned char)c);
    }
    local_intr_restore(intr_flag);
}
ffffffffc0200538:	60e2                	ld	ra,24(sp)
ffffffffc020053a:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc020053c:	a6fd                	j	ffffffffc020092a <intr_enable>

ffffffffc020053e <cons_getc>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020053e:	100027f3          	csrr	a5,sstatus
ffffffffc0200542:	8b89                	andi	a5,a5,2
ffffffffc0200544:	eb89                	bnez	a5,ffffffffc0200556 <cons_getc+0x18>
	return SBI_CALL_0(SBI_CONSOLE_GETCHAR);
ffffffffc0200546:	4501                	li	a0,0
ffffffffc0200548:	4581                	li	a1,0
ffffffffc020054a:	4601                	li	a2,0
ffffffffc020054c:	4889                	li	a7,2
ffffffffc020054e:	00000073          	ecall
ffffffffc0200552:	2501                	sext.w	a0,a0
    {
        c = sbi_console_getchar();
    }
    local_intr_restore(intr_flag);
    return c;
}
ffffffffc0200554:	8082                	ret
int cons_getc(void) {
ffffffffc0200556:	1101                	addi	sp,sp,-32
ffffffffc0200558:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc020055a:	3d6000ef          	jal	ra,ffffffffc0200930 <intr_disable>
ffffffffc020055e:	4501                	li	a0,0
ffffffffc0200560:	4581                	li	a1,0
ffffffffc0200562:	4601                	li	a2,0
ffffffffc0200564:	4889                	li	a7,2
ffffffffc0200566:	00000073          	ecall
ffffffffc020056a:	2501                	sext.w	a0,a0
ffffffffc020056c:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc020056e:	3bc000ef          	jal	ra,ffffffffc020092a <intr_enable>
}
ffffffffc0200572:	60e2                	ld	ra,24(sp)
ffffffffc0200574:	6522                	ld	a0,8(sp)
ffffffffc0200576:	6105                	addi	sp,sp,32
ffffffffc0200578:	8082                	ret

ffffffffc020057a <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc020057a:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc020057c:	00004517          	auipc	a0,0x4
ffffffffc0200580:	c5450513          	addi	a0,a0,-940 # ffffffffc02041d0 <commands+0x88>
void dtb_init(void) {
ffffffffc0200584:	fc86                	sd	ra,120(sp)
ffffffffc0200586:	f8a2                	sd	s0,112(sp)
ffffffffc0200588:	e8d2                	sd	s4,80(sp)
ffffffffc020058a:	f4a6                	sd	s1,104(sp)
ffffffffc020058c:	f0ca                	sd	s2,96(sp)
ffffffffc020058e:	ecce                	sd	s3,88(sp)
ffffffffc0200590:	e4d6                	sd	s5,72(sp)
ffffffffc0200592:	e0da                	sd	s6,64(sp)
ffffffffc0200594:	fc5e                	sd	s7,56(sp)
ffffffffc0200596:	f862                	sd	s8,48(sp)
ffffffffc0200598:	f466                	sd	s9,40(sp)
ffffffffc020059a:	f06a                	sd	s10,32(sp)
ffffffffc020059c:	ec6e                	sd	s11,24(sp)
    cprintf("DTB Init\n");
ffffffffc020059e:	bf7ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc02005a2:	00009597          	auipc	a1,0x9
ffffffffc02005a6:	a5e5b583          	ld	a1,-1442(a1) # ffffffffc0209000 <boot_hartid>
ffffffffc02005aa:	00004517          	auipc	a0,0x4
ffffffffc02005ae:	c3650513          	addi	a0,a0,-970 # ffffffffc02041e0 <commands+0x98>
ffffffffc02005b2:	be3ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc02005b6:	00009417          	auipc	s0,0x9
ffffffffc02005ba:	a5240413          	addi	s0,s0,-1454 # ffffffffc0209008 <boot_dtb>
ffffffffc02005be:	600c                	ld	a1,0(s0)
ffffffffc02005c0:	00004517          	auipc	a0,0x4
ffffffffc02005c4:	c3050513          	addi	a0,a0,-976 # ffffffffc02041f0 <commands+0xa8>
ffffffffc02005c8:	bcdff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc02005cc:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc02005d0:	00004517          	auipc	a0,0x4
ffffffffc02005d4:	c3850513          	addi	a0,a0,-968 # ffffffffc0204208 <commands+0xc0>
    if (boot_dtb == 0) {
ffffffffc02005d8:	120a0463          	beqz	s4,ffffffffc0200700 <dtb_init+0x186>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc02005dc:	57f5                	li	a5,-3
ffffffffc02005de:	07fa                	slli	a5,a5,0x1e
ffffffffc02005e0:	00fa0733          	add	a4,s4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc02005e4:	431c                	lw	a5,0(a4)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005e6:	00ff0637          	lui	a2,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005ea:	6b41                	lui	s6,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005ec:	0087d59b          	srliw	a1,a5,0x8
ffffffffc02005f0:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005f4:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005f8:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005fc:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200600:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200602:	8ec9                	or	a3,a3,a0
ffffffffc0200604:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200608:	1b7d                	addi	s6,s6,-1
ffffffffc020060a:	0167f7b3          	and	a5,a5,s6
ffffffffc020060e:	8dd5                	or	a1,a1,a3
ffffffffc0200610:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc0200612:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200616:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc0200618:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfed2a01>
ffffffffc020061c:	10f59163          	bne	a1,a5,ffffffffc020071e <dtb_init+0x1a4>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc0200620:	471c                	lw	a5,8(a4)
ffffffffc0200622:	4754                	lw	a3,12(a4)
    int in_memory_node = 0;
ffffffffc0200624:	4c81                	li	s9,0
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200626:	0087d59b          	srliw	a1,a5,0x8
ffffffffc020062a:	0086d51b          	srliw	a0,a3,0x8
ffffffffc020062e:	0186941b          	slliw	s0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200632:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200636:	01879a1b          	slliw	s4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020063a:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020063e:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200642:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200646:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020064a:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020064e:	8d71                	and	a0,a0,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200650:	01146433          	or	s0,s0,a7
ffffffffc0200654:	0086969b          	slliw	a3,a3,0x8
ffffffffc0200658:	010a6a33          	or	s4,s4,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020065c:	8e6d                	and	a2,a2,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020065e:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200662:	8c49                	or	s0,s0,a0
ffffffffc0200664:	0166f6b3          	and	a3,a3,s6
ffffffffc0200668:	00ca6a33          	or	s4,s4,a2
ffffffffc020066c:	0167f7b3          	and	a5,a5,s6
ffffffffc0200670:	8c55                	or	s0,s0,a3
ffffffffc0200672:	00fa6a33          	or	s4,s4,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200676:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200678:	1a02                	slli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020067a:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020067c:	020a5a13          	srli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200680:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200682:	9a3a                	add	s4,s4,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200684:	00ff0c37          	lui	s8,0xff0
        switch (token) {
ffffffffc0200688:	4b8d                	li	s7,3
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020068a:	00004917          	auipc	s2,0x4
ffffffffc020068e:	bce90913          	addi	s2,s2,-1074 # ffffffffc0204258 <commands+0x110>
ffffffffc0200692:	49bd                	li	s3,15
        switch (token) {
ffffffffc0200694:	4d91                	li	s11,4
ffffffffc0200696:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200698:	00004497          	auipc	s1,0x4
ffffffffc020069c:	bb848493          	addi	s1,s1,-1096 # ffffffffc0204250 <commands+0x108>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc02006a0:	000a2703          	lw	a4,0(s4)
ffffffffc02006a4:	004a0a93          	addi	s5,s4,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006a8:	0087569b          	srliw	a3,a4,0x8
ffffffffc02006ac:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006b0:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006b4:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006b8:	0107571b          	srliw	a4,a4,0x10
ffffffffc02006bc:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006be:	0186f6b3          	and	a3,a3,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006c2:	0087171b          	slliw	a4,a4,0x8
ffffffffc02006c6:	8fd5                	or	a5,a5,a3
ffffffffc02006c8:	00eb7733          	and	a4,s6,a4
ffffffffc02006cc:	8fd9                	or	a5,a5,a4
ffffffffc02006ce:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc02006d0:	09778c63          	beq	a5,s7,ffffffffc0200768 <dtb_init+0x1ee>
ffffffffc02006d4:	00fbea63          	bltu	s7,a5,ffffffffc02006e8 <dtb_init+0x16e>
ffffffffc02006d8:	07a78663          	beq	a5,s10,ffffffffc0200744 <dtb_init+0x1ca>
ffffffffc02006dc:	4709                	li	a4,2
ffffffffc02006de:	00e79763          	bne	a5,a4,ffffffffc02006ec <dtb_init+0x172>
ffffffffc02006e2:	4c81                	li	s9,0
ffffffffc02006e4:	8a56                	mv	s4,s5
ffffffffc02006e6:	bf6d                	j	ffffffffc02006a0 <dtb_init+0x126>
ffffffffc02006e8:	ffb78ee3          	beq	a5,s11,ffffffffc02006e4 <dtb_init+0x16a>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc02006ec:	00004517          	auipc	a0,0x4
ffffffffc02006f0:	be450513          	addi	a0,a0,-1052 # ffffffffc02042d0 <commands+0x188>
ffffffffc02006f4:	aa1ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc02006f8:	00004517          	auipc	a0,0x4
ffffffffc02006fc:	c1050513          	addi	a0,a0,-1008 # ffffffffc0204308 <commands+0x1c0>
}
ffffffffc0200700:	7446                	ld	s0,112(sp)
ffffffffc0200702:	70e6                	ld	ra,120(sp)
ffffffffc0200704:	74a6                	ld	s1,104(sp)
ffffffffc0200706:	7906                	ld	s2,96(sp)
ffffffffc0200708:	69e6                	ld	s3,88(sp)
ffffffffc020070a:	6a46                	ld	s4,80(sp)
ffffffffc020070c:	6aa6                	ld	s5,72(sp)
ffffffffc020070e:	6b06                	ld	s6,64(sp)
ffffffffc0200710:	7be2                	ld	s7,56(sp)
ffffffffc0200712:	7c42                	ld	s8,48(sp)
ffffffffc0200714:	7ca2                	ld	s9,40(sp)
ffffffffc0200716:	7d02                	ld	s10,32(sp)
ffffffffc0200718:	6de2                	ld	s11,24(sp)
ffffffffc020071a:	6109                	addi	sp,sp,128
    cprintf("DTB init completed\n");
ffffffffc020071c:	bca5                	j	ffffffffc0200194 <cprintf>
}
ffffffffc020071e:	7446                	ld	s0,112(sp)
ffffffffc0200720:	70e6                	ld	ra,120(sp)
ffffffffc0200722:	74a6                	ld	s1,104(sp)
ffffffffc0200724:	7906                	ld	s2,96(sp)
ffffffffc0200726:	69e6                	ld	s3,88(sp)
ffffffffc0200728:	6a46                	ld	s4,80(sp)
ffffffffc020072a:	6aa6                	ld	s5,72(sp)
ffffffffc020072c:	6b06                	ld	s6,64(sp)
ffffffffc020072e:	7be2                	ld	s7,56(sp)
ffffffffc0200730:	7c42                	ld	s8,48(sp)
ffffffffc0200732:	7ca2                	ld	s9,40(sp)
ffffffffc0200734:	7d02                	ld	s10,32(sp)
ffffffffc0200736:	6de2                	ld	s11,24(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200738:	00004517          	auipc	a0,0x4
ffffffffc020073c:	af050513          	addi	a0,a0,-1296 # ffffffffc0204228 <commands+0xe0>
}
ffffffffc0200740:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200742:	bc89                	j	ffffffffc0200194 <cprintf>
                int name_len = strlen(name);
ffffffffc0200744:	8556                	mv	a0,s5
ffffffffc0200746:	6aa030ef          	jal	ra,ffffffffc0203df0 <strlen>
ffffffffc020074a:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020074c:	4619                	li	a2,6
ffffffffc020074e:	85a6                	mv	a1,s1
ffffffffc0200750:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc0200752:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200754:	702030ef          	jal	ra,ffffffffc0203e56 <strncmp>
ffffffffc0200758:	e111                	bnez	a0,ffffffffc020075c <dtb_init+0x1e2>
                    in_memory_node = 1;
ffffffffc020075a:	4c85                	li	s9,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc020075c:	0a91                	addi	s5,s5,4
ffffffffc020075e:	9ad2                	add	s5,s5,s4
ffffffffc0200760:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc0200764:	8a56                	mv	s4,s5
ffffffffc0200766:	bf2d                	j	ffffffffc02006a0 <dtb_init+0x126>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200768:	004a2783          	lw	a5,4(s4)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc020076c:	00ca0693          	addi	a3,s4,12
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200770:	0087d71b          	srliw	a4,a5,0x8
ffffffffc0200774:	01879a9b          	slliw	s5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200778:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020077c:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200780:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200784:	00caeab3          	or	s5,s5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200788:	01877733          	and	a4,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020078c:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200790:	00eaeab3          	or	s5,s5,a4
ffffffffc0200794:	00fb77b3          	and	a5,s6,a5
ffffffffc0200798:	00faeab3          	or	s5,s5,a5
ffffffffc020079c:	2a81                	sext.w	s5,s5
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020079e:	000c9c63          	bnez	s9,ffffffffc02007b6 <dtb_init+0x23c>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc02007a2:	1a82                	slli	s5,s5,0x20
ffffffffc02007a4:	00368793          	addi	a5,a3,3
ffffffffc02007a8:	020ada93          	srli	s5,s5,0x20
ffffffffc02007ac:	9abe                	add	s5,s5,a5
ffffffffc02007ae:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc02007b2:	8a56                	mv	s4,s5
ffffffffc02007b4:	b5f5                	j	ffffffffc02006a0 <dtb_init+0x126>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc02007b6:	008a2783          	lw	a5,8(s4)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02007ba:	85ca                	mv	a1,s2
ffffffffc02007bc:	e436                	sd	a3,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007be:	0087d51b          	srliw	a0,a5,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007c2:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007c6:	0187971b          	slliw	a4,a5,0x18
ffffffffc02007ca:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007ce:	0107d79b          	srliw	a5,a5,0x10
ffffffffc02007d2:	8f51                	or	a4,a4,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007d4:	01857533          	and	a0,a0,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007d8:	0087979b          	slliw	a5,a5,0x8
ffffffffc02007dc:	8d59                	or	a0,a0,a4
ffffffffc02007de:	00fb77b3          	and	a5,s6,a5
ffffffffc02007e2:	8d5d                	or	a0,a0,a5
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc02007e4:	1502                	slli	a0,a0,0x20
ffffffffc02007e6:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02007e8:	9522                	add	a0,a0,s0
ffffffffc02007ea:	64e030ef          	jal	ra,ffffffffc0203e38 <strcmp>
ffffffffc02007ee:	66a2                	ld	a3,8(sp)
ffffffffc02007f0:	f94d                	bnez	a0,ffffffffc02007a2 <dtb_init+0x228>
ffffffffc02007f2:	fb59f8e3          	bgeu	s3,s5,ffffffffc02007a2 <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc02007f6:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc02007fa:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc02007fe:	00004517          	auipc	a0,0x4
ffffffffc0200802:	a6250513          	addi	a0,a0,-1438 # ffffffffc0204260 <commands+0x118>
           fdt32_to_cpu(x >> 32);
ffffffffc0200806:	4207d613          	srai	a2,a5,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020080a:	0087d31b          	srliw	t1,a5,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc020080e:	42075593          	srai	a1,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200812:	0187de1b          	srliw	t3,a5,0x18
ffffffffc0200816:	0186581b          	srliw	a6,a2,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020081a:	0187941b          	slliw	s0,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020081e:	0107d89b          	srliw	a7,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200822:	0187d693          	srli	a3,a5,0x18
ffffffffc0200826:	01861f1b          	slliw	t5,a2,0x18
ffffffffc020082a:	0087579b          	srliw	a5,a4,0x8
ffffffffc020082e:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200832:	0106561b          	srliw	a2,a2,0x10
ffffffffc0200836:	010f6f33          	or	t5,t5,a6
ffffffffc020083a:	0187529b          	srliw	t0,a4,0x18
ffffffffc020083e:	0185df9b          	srliw	t6,a1,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200842:	01837333          	and	t1,t1,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200846:	01c46433          	or	s0,s0,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020084a:	0186f6b3          	and	a3,a3,s8
ffffffffc020084e:	01859e1b          	slliw	t3,a1,0x18
ffffffffc0200852:	01871e9b          	slliw	t4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200856:	0107581b          	srliw	a6,a4,0x10
ffffffffc020085a:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020085e:	8361                	srli	a4,a4,0x18
ffffffffc0200860:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200864:	0105d59b          	srliw	a1,a1,0x10
ffffffffc0200868:	01e6e6b3          	or	a3,a3,t5
ffffffffc020086c:	00cb7633          	and	a2,s6,a2
ffffffffc0200870:	0088181b          	slliw	a6,a6,0x8
ffffffffc0200874:	0085959b          	slliw	a1,a1,0x8
ffffffffc0200878:	00646433          	or	s0,s0,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020087c:	0187f7b3          	and	a5,a5,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200880:	01fe6333          	or	t1,t3,t6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200884:	01877c33          	and	s8,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200888:	0088989b          	slliw	a7,a7,0x8
ffffffffc020088c:	011b78b3          	and	a7,s6,a7
ffffffffc0200890:	005eeeb3          	or	t4,t4,t0
ffffffffc0200894:	00c6e733          	or	a4,a3,a2
ffffffffc0200898:	006c6c33          	or	s8,s8,t1
ffffffffc020089c:	010b76b3          	and	a3,s6,a6
ffffffffc02008a0:	00bb7b33          	and	s6,s6,a1
ffffffffc02008a4:	01d7e7b3          	or	a5,a5,t4
ffffffffc02008a8:	016c6b33          	or	s6,s8,s6
ffffffffc02008ac:	01146433          	or	s0,s0,a7
ffffffffc02008b0:	8fd5                	or	a5,a5,a3
           fdt32_to_cpu(x >> 32);
ffffffffc02008b2:	1702                	slli	a4,a4,0x20
ffffffffc02008b4:	1b02                	slli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc02008b6:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc02008b8:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc02008ba:	1402                	slli	s0,s0,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc02008bc:	020b5b13          	srli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc02008c0:	0167eb33          	or	s6,a5,s6
ffffffffc02008c4:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc02008c6:	8cfff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc02008ca:	85a2                	mv	a1,s0
ffffffffc02008cc:	00004517          	auipc	a0,0x4
ffffffffc02008d0:	9b450513          	addi	a0,a0,-1612 # ffffffffc0204280 <commands+0x138>
ffffffffc02008d4:	8c1ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc02008d8:	014b5613          	srli	a2,s6,0x14
ffffffffc02008dc:	85da                	mv	a1,s6
ffffffffc02008de:	00004517          	auipc	a0,0x4
ffffffffc02008e2:	9ba50513          	addi	a0,a0,-1606 # ffffffffc0204298 <commands+0x150>
ffffffffc02008e6:	8afff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc02008ea:	008b05b3          	add	a1,s6,s0
ffffffffc02008ee:	15fd                	addi	a1,a1,-1
ffffffffc02008f0:	00004517          	auipc	a0,0x4
ffffffffc02008f4:	9c850513          	addi	a0,a0,-1592 # ffffffffc02042b8 <commands+0x170>
ffffffffc02008f8:	89dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("DTB init completed\n");
ffffffffc02008fc:	00004517          	auipc	a0,0x4
ffffffffc0200900:	a0c50513          	addi	a0,a0,-1524 # ffffffffc0204308 <commands+0x1c0>
        memory_base = mem_base;
ffffffffc0200904:	0000d797          	auipc	a5,0xd
ffffffffc0200908:	b687be23          	sd	s0,-1156(a5) # ffffffffc020d480 <memory_base>
        memory_size = mem_size;
ffffffffc020090c:	0000d797          	auipc	a5,0xd
ffffffffc0200910:	b767be23          	sd	s6,-1156(a5) # ffffffffc020d488 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc0200914:	b3f5                	j	ffffffffc0200700 <dtb_init+0x186>

ffffffffc0200916 <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc0200916:	0000d517          	auipc	a0,0xd
ffffffffc020091a:	b6a53503          	ld	a0,-1174(a0) # ffffffffc020d480 <memory_base>
ffffffffc020091e:	8082                	ret

ffffffffc0200920 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
ffffffffc0200920:	0000d517          	auipc	a0,0xd
ffffffffc0200924:	b6853503          	ld	a0,-1176(a0) # ffffffffc020d488 <memory_size>
ffffffffc0200928:	8082                	ret

ffffffffc020092a <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc020092a:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc020092e:	8082                	ret

ffffffffc0200930 <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200930:	100177f3          	csrrci	a5,sstatus,2
ffffffffc0200934:	8082                	ret

ffffffffc0200936 <pic_init>:
#include <picirq.h>

void pic_enable(unsigned int irq) {}

/* pic_init - initialize the 8259A interrupt controllers */
void pic_init(void) {}
ffffffffc0200936:	8082                	ret

ffffffffc0200938 <idt_init>:
void idt_init(void)
{
    extern void __alltraps(void);
    /* Set sscratch register to 0, indicating to exception vector that we are
     * presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc0200938:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc020093c:	00000797          	auipc	a5,0x0
ffffffffc0200940:	40478793          	addi	a5,a5,1028 # ffffffffc0200d40 <__alltraps>
ffffffffc0200944:	10579073          	csrw	stvec,a5
    /* Allow kernel to access user memory */
    set_csr(sstatus, SSTATUS_SUM);
ffffffffc0200948:	000407b7          	lui	a5,0x40
ffffffffc020094c:	1007a7f3          	csrrs	a5,sstatus,a5
}
ffffffffc0200950:	8082                	ret

ffffffffc0200952 <print_regs>:
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr)
{
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200952:	610c                	ld	a1,0(a0)
{
ffffffffc0200954:	1141                	addi	sp,sp,-16
ffffffffc0200956:	e022                	sd	s0,0(sp)
ffffffffc0200958:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020095a:	00004517          	auipc	a0,0x4
ffffffffc020095e:	9c650513          	addi	a0,a0,-1594 # ffffffffc0204320 <commands+0x1d8>
{
ffffffffc0200962:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200964:	831ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc0200968:	640c                	ld	a1,8(s0)
ffffffffc020096a:	00004517          	auipc	a0,0x4
ffffffffc020096e:	9ce50513          	addi	a0,a0,-1586 # ffffffffc0204338 <commands+0x1f0>
ffffffffc0200972:	823ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc0200976:	680c                	ld	a1,16(s0)
ffffffffc0200978:	00004517          	auipc	a0,0x4
ffffffffc020097c:	9d850513          	addi	a0,a0,-1576 # ffffffffc0204350 <commands+0x208>
ffffffffc0200980:	815ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc0200984:	6c0c                	ld	a1,24(s0)
ffffffffc0200986:	00004517          	auipc	a0,0x4
ffffffffc020098a:	9e250513          	addi	a0,a0,-1566 # ffffffffc0204368 <commands+0x220>
ffffffffc020098e:	807ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc0200992:	700c                	ld	a1,32(s0)
ffffffffc0200994:	00004517          	auipc	a0,0x4
ffffffffc0200998:	9ec50513          	addi	a0,a0,-1556 # ffffffffc0204380 <commands+0x238>
ffffffffc020099c:	ff8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02009a0:	740c                	ld	a1,40(s0)
ffffffffc02009a2:	00004517          	auipc	a0,0x4
ffffffffc02009a6:	9f650513          	addi	a0,a0,-1546 # ffffffffc0204398 <commands+0x250>
ffffffffc02009aa:	feaff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02009ae:	780c                	ld	a1,48(s0)
ffffffffc02009b0:	00004517          	auipc	a0,0x4
ffffffffc02009b4:	a0050513          	addi	a0,a0,-1536 # ffffffffc02043b0 <commands+0x268>
ffffffffc02009b8:	fdcff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02009bc:	7c0c                	ld	a1,56(s0)
ffffffffc02009be:	00004517          	auipc	a0,0x4
ffffffffc02009c2:	a0a50513          	addi	a0,a0,-1526 # ffffffffc02043c8 <commands+0x280>
ffffffffc02009c6:	fceff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02009ca:	602c                	ld	a1,64(s0)
ffffffffc02009cc:	00004517          	auipc	a0,0x4
ffffffffc02009d0:	a1450513          	addi	a0,a0,-1516 # ffffffffc02043e0 <commands+0x298>
ffffffffc02009d4:	fc0ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc02009d8:	642c                	ld	a1,72(s0)
ffffffffc02009da:	00004517          	auipc	a0,0x4
ffffffffc02009de:	a1e50513          	addi	a0,a0,-1506 # ffffffffc02043f8 <commands+0x2b0>
ffffffffc02009e2:	fb2ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc02009e6:	682c                	ld	a1,80(s0)
ffffffffc02009e8:	00004517          	auipc	a0,0x4
ffffffffc02009ec:	a2850513          	addi	a0,a0,-1496 # ffffffffc0204410 <commands+0x2c8>
ffffffffc02009f0:	fa4ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc02009f4:	6c2c                	ld	a1,88(s0)
ffffffffc02009f6:	00004517          	auipc	a0,0x4
ffffffffc02009fa:	a3250513          	addi	a0,a0,-1486 # ffffffffc0204428 <commands+0x2e0>
ffffffffc02009fe:	f96ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200a02:	702c                	ld	a1,96(s0)
ffffffffc0200a04:	00004517          	auipc	a0,0x4
ffffffffc0200a08:	a3c50513          	addi	a0,a0,-1476 # ffffffffc0204440 <commands+0x2f8>
ffffffffc0200a0c:	f88ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200a10:	742c                	ld	a1,104(s0)
ffffffffc0200a12:	00004517          	auipc	a0,0x4
ffffffffc0200a16:	a4650513          	addi	a0,a0,-1466 # ffffffffc0204458 <commands+0x310>
ffffffffc0200a1a:	f7aff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200a1e:	782c                	ld	a1,112(s0)
ffffffffc0200a20:	00004517          	auipc	a0,0x4
ffffffffc0200a24:	a5050513          	addi	a0,a0,-1456 # ffffffffc0204470 <commands+0x328>
ffffffffc0200a28:	f6cff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200a2c:	7c2c                	ld	a1,120(s0)
ffffffffc0200a2e:	00004517          	auipc	a0,0x4
ffffffffc0200a32:	a5a50513          	addi	a0,a0,-1446 # ffffffffc0204488 <commands+0x340>
ffffffffc0200a36:	f5eff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200a3a:	604c                	ld	a1,128(s0)
ffffffffc0200a3c:	00004517          	auipc	a0,0x4
ffffffffc0200a40:	a6450513          	addi	a0,a0,-1436 # ffffffffc02044a0 <commands+0x358>
ffffffffc0200a44:	f50ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200a48:	644c                	ld	a1,136(s0)
ffffffffc0200a4a:	00004517          	auipc	a0,0x4
ffffffffc0200a4e:	a6e50513          	addi	a0,a0,-1426 # ffffffffc02044b8 <commands+0x370>
ffffffffc0200a52:	f42ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200a56:	684c                	ld	a1,144(s0)
ffffffffc0200a58:	00004517          	auipc	a0,0x4
ffffffffc0200a5c:	a7850513          	addi	a0,a0,-1416 # ffffffffc02044d0 <commands+0x388>
ffffffffc0200a60:	f34ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200a64:	6c4c                	ld	a1,152(s0)
ffffffffc0200a66:	00004517          	auipc	a0,0x4
ffffffffc0200a6a:	a8250513          	addi	a0,a0,-1406 # ffffffffc02044e8 <commands+0x3a0>
ffffffffc0200a6e:	f26ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200a72:	704c                	ld	a1,160(s0)
ffffffffc0200a74:	00004517          	auipc	a0,0x4
ffffffffc0200a78:	a8c50513          	addi	a0,a0,-1396 # ffffffffc0204500 <commands+0x3b8>
ffffffffc0200a7c:	f18ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc0200a80:	744c                	ld	a1,168(s0)
ffffffffc0200a82:	00004517          	auipc	a0,0x4
ffffffffc0200a86:	a9650513          	addi	a0,a0,-1386 # ffffffffc0204518 <commands+0x3d0>
ffffffffc0200a8a:	f0aff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc0200a8e:	784c                	ld	a1,176(s0)
ffffffffc0200a90:	00004517          	auipc	a0,0x4
ffffffffc0200a94:	aa050513          	addi	a0,a0,-1376 # ffffffffc0204530 <commands+0x3e8>
ffffffffc0200a98:	efcff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc0200a9c:	7c4c                	ld	a1,184(s0)
ffffffffc0200a9e:	00004517          	auipc	a0,0x4
ffffffffc0200aa2:	aaa50513          	addi	a0,a0,-1366 # ffffffffc0204548 <commands+0x400>
ffffffffc0200aa6:	eeeff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc0200aaa:	606c                	ld	a1,192(s0)
ffffffffc0200aac:	00004517          	auipc	a0,0x4
ffffffffc0200ab0:	ab450513          	addi	a0,a0,-1356 # ffffffffc0204560 <commands+0x418>
ffffffffc0200ab4:	ee0ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc0200ab8:	646c                	ld	a1,200(s0)
ffffffffc0200aba:	00004517          	auipc	a0,0x4
ffffffffc0200abe:	abe50513          	addi	a0,a0,-1346 # ffffffffc0204578 <commands+0x430>
ffffffffc0200ac2:	ed2ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc0200ac6:	686c                	ld	a1,208(s0)
ffffffffc0200ac8:	00004517          	auipc	a0,0x4
ffffffffc0200acc:	ac850513          	addi	a0,a0,-1336 # ffffffffc0204590 <commands+0x448>
ffffffffc0200ad0:	ec4ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc0200ad4:	6c6c                	ld	a1,216(s0)
ffffffffc0200ad6:	00004517          	auipc	a0,0x4
ffffffffc0200ada:	ad250513          	addi	a0,a0,-1326 # ffffffffc02045a8 <commands+0x460>
ffffffffc0200ade:	eb6ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200ae2:	706c                	ld	a1,224(s0)
ffffffffc0200ae4:	00004517          	auipc	a0,0x4
ffffffffc0200ae8:	adc50513          	addi	a0,a0,-1316 # ffffffffc02045c0 <commands+0x478>
ffffffffc0200aec:	ea8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200af0:	746c                	ld	a1,232(s0)
ffffffffc0200af2:	00004517          	auipc	a0,0x4
ffffffffc0200af6:	ae650513          	addi	a0,a0,-1306 # ffffffffc02045d8 <commands+0x490>
ffffffffc0200afa:	e9aff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200afe:	786c                	ld	a1,240(s0)
ffffffffc0200b00:	00004517          	auipc	a0,0x4
ffffffffc0200b04:	af050513          	addi	a0,a0,-1296 # ffffffffc02045f0 <commands+0x4a8>
ffffffffc0200b08:	e8cff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b0c:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200b0e:	6402                	ld	s0,0(sp)
ffffffffc0200b10:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b12:	00004517          	auipc	a0,0x4
ffffffffc0200b16:	af650513          	addi	a0,a0,-1290 # ffffffffc0204608 <commands+0x4c0>
}
ffffffffc0200b1a:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b1c:	e78ff06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0200b20 <print_trapframe>:
{
ffffffffc0200b20:	1141                	addi	sp,sp,-16
ffffffffc0200b22:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200b24:	85aa                	mv	a1,a0
{
ffffffffc0200b26:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200b28:	00004517          	auipc	a0,0x4
ffffffffc0200b2c:	af850513          	addi	a0,a0,-1288 # ffffffffc0204620 <commands+0x4d8>
{
ffffffffc0200b30:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200b32:	e62ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200b36:	8522                	mv	a0,s0
ffffffffc0200b38:	e1bff0ef          	jal	ra,ffffffffc0200952 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200b3c:	10043583          	ld	a1,256(s0)
ffffffffc0200b40:	00004517          	auipc	a0,0x4
ffffffffc0200b44:	af850513          	addi	a0,a0,-1288 # ffffffffc0204638 <commands+0x4f0>
ffffffffc0200b48:	e4cff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200b4c:	10843583          	ld	a1,264(s0)
ffffffffc0200b50:	00004517          	auipc	a0,0x4
ffffffffc0200b54:	b0050513          	addi	a0,a0,-1280 # ffffffffc0204650 <commands+0x508>
ffffffffc0200b58:	e3cff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc0200b5c:	11043583          	ld	a1,272(s0)
ffffffffc0200b60:	00004517          	auipc	a0,0x4
ffffffffc0200b64:	b0850513          	addi	a0,a0,-1272 # ffffffffc0204668 <commands+0x520>
ffffffffc0200b68:	e2cff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200b6c:	11843583          	ld	a1,280(s0)
}
ffffffffc0200b70:	6402                	ld	s0,0(sp)
ffffffffc0200b72:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200b74:	00004517          	auipc	a0,0x4
ffffffffc0200b78:	b0c50513          	addi	a0,a0,-1268 # ffffffffc0204680 <commands+0x538>
}
ffffffffc0200b7c:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200b7e:	e16ff06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0200b82 <interrupt_handler>:

extern struct mm_struct *check_mm_struct;

void interrupt_handler(struct trapframe *tf)
{
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc0200b82:	11853783          	ld	a5,280(a0)
ffffffffc0200b86:	472d                	li	a4,11
ffffffffc0200b88:	0786                	slli	a5,a5,0x1
ffffffffc0200b8a:	8385                	srli	a5,a5,0x1
ffffffffc0200b8c:	06f76d63          	bltu	a4,a5,ffffffffc0200c06 <interrupt_handler+0x84>
ffffffffc0200b90:	00004717          	auipc	a4,0x4
ffffffffc0200b94:	bb870713          	addi	a4,a4,-1096 # ffffffffc0204748 <commands+0x600>
ffffffffc0200b98:	078a                	slli	a5,a5,0x2
ffffffffc0200b9a:	97ba                	add	a5,a5,a4
ffffffffc0200b9c:	439c                	lw	a5,0(a5)
ffffffffc0200b9e:	97ba                	add	a5,a5,a4
ffffffffc0200ba0:	8782                	jr	a5
        break;
    case IRQ_H_SOFT:
        cprintf("Hypervisor software interrupt\n");
        break;
    case IRQ_M_SOFT:
        cprintf("Machine software interrupt\n");
ffffffffc0200ba2:	00004517          	auipc	a0,0x4
ffffffffc0200ba6:	b5650513          	addi	a0,a0,-1194 # ffffffffc02046f8 <commands+0x5b0>
ffffffffc0200baa:	deaff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Hypervisor software interrupt\n");
ffffffffc0200bae:	00004517          	auipc	a0,0x4
ffffffffc0200bb2:	b2a50513          	addi	a0,a0,-1238 # ffffffffc02046d8 <commands+0x590>
ffffffffc0200bb6:	ddeff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("User software interrupt\n");
ffffffffc0200bba:	00004517          	auipc	a0,0x4
ffffffffc0200bbe:	ade50513          	addi	a0,a0,-1314 # ffffffffc0204698 <commands+0x550>
ffffffffc0200bc2:	dd2ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Supervisor software interrupt\n");
ffffffffc0200bc6:	00004517          	auipc	a0,0x4
ffffffffc0200bca:	af250513          	addi	a0,a0,-1294 # ffffffffc02046b8 <commands+0x570>
ffffffffc0200bce:	dc6ff06f          	j	ffffffffc0200194 <cprintf>
{
ffffffffc0200bd2:	1141                	addi	sp,sp,-16
ffffffffc0200bd4:	e406                	sd	ra,8(sp)
        // In fact, Call sbi_set_timer will clear STIP, or you can clear it
        // directly.
        // clear_csr(sip, SIP_STIP);

        /*LAB3 2310675: 补全时钟中断处理逻辑 */
        clock_set_next_event(); // 2310675: 预约下一次时钟中断
ffffffffc0200bd6:	919ff0ef          	jal	ra,ffffffffc02004ee <clock_set_next_event>
        ticks++;                // 2310675: 全局节拍计数自增
ffffffffc0200bda:	0000d797          	auipc	a5,0xd
ffffffffc0200bde:	89678793          	addi	a5,a5,-1898 # ffffffffc020d470 <ticks>
ffffffffc0200be2:	6398                	ld	a4,0(a5)
ffffffffc0200be4:	0705                	addi	a4,a4,1
ffffffffc0200be6:	e398                	sd	a4,0(a5)
        if (ticks % TICK_NUM == 0)
ffffffffc0200be8:	639c                	ld	a5,0(a5)
ffffffffc0200bea:	06400713          	li	a4,100
ffffffffc0200bee:	02e7f7b3          	remu	a5,a5,a4
ffffffffc0200bf2:	cb99                	beqz	a5,ffffffffc0200c08 <interrupt_handler+0x86>
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200bf4:	60a2                	ld	ra,8(sp)
ffffffffc0200bf6:	0141                	addi	sp,sp,16
ffffffffc0200bf8:	8082                	ret
        cprintf("Supervisor external interrupt\n");
ffffffffc0200bfa:	00004517          	auipc	a0,0x4
ffffffffc0200bfe:	b2e50513          	addi	a0,a0,-1234 # ffffffffc0204728 <commands+0x5e0>
ffffffffc0200c02:	d92ff06f          	j	ffffffffc0200194 <cprintf>
        print_trapframe(tf);
ffffffffc0200c06:	bf29                	j	ffffffffc0200b20 <print_trapframe>
    cprintf("%d ticks\n", TICK_NUM); // 2310675: 每满TICK_NUM次时钟中断输出提示
ffffffffc0200c08:	06400593          	li	a1,100
ffffffffc0200c0c:	00004517          	auipc	a0,0x4
ffffffffc0200c10:	b0c50513          	addi	a0,a0,-1268 # ffffffffc0204718 <commands+0x5d0>
ffffffffc0200c14:	d80ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
            tick_prints++;
ffffffffc0200c18:	0000d717          	auipc	a4,0xd
ffffffffc0200c1c:	87870713          	addi	a4,a4,-1928 # ffffffffc020d490 <tick_prints>
ffffffffc0200c20:	631c                	ld	a5,0(a4)
            if (tick_prints == 10)
ffffffffc0200c22:	46a9                	li	a3,10
            tick_prints++;
ffffffffc0200c24:	0785                	addi	a5,a5,1
ffffffffc0200c26:	e31c                	sd	a5,0(a4)
            if (tick_prints == 10)
ffffffffc0200c28:	fcd796e3          	bne	a5,a3,ffffffffc0200bf4 <interrupt_handler+0x72>
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc0200c2c:	4501                	li	a0,0
ffffffffc0200c2e:	4581                	li	a1,0
ffffffffc0200c30:	4601                	li	a2,0
ffffffffc0200c32:	48a1                	li	a7,8
ffffffffc0200c34:	00000073          	ecall
}
ffffffffc0200c38:	bf75                	j	ffffffffc0200bf4 <interrupt_handler+0x72>

ffffffffc0200c3a <exception_handler>:

void exception_handler(struct trapframe *tf)
{
    switch (tf->cause)
ffffffffc0200c3a:	11853783          	ld	a5,280(a0)
{
ffffffffc0200c3e:	1141                	addi	sp,sp,-16
ffffffffc0200c40:	e022                	sd	s0,0(sp)
ffffffffc0200c42:	e406                	sd	ra,8(sp)
ffffffffc0200c44:	473d                	li	a4,15
ffffffffc0200c46:	842a                	mv	s0,a0
ffffffffc0200c48:	0ef76163          	bltu	a4,a5,ffffffffc0200d2a <exception_handler+0xf0>
ffffffffc0200c4c:	00004717          	auipc	a4,0x4
ffffffffc0200c50:	ce470713          	addi	a4,a4,-796 # ffffffffc0204930 <commands+0x7e8>
ffffffffc0200c54:	078a                	slli	a5,a5,0x2
ffffffffc0200c56:	97ba                	add	a5,a5,a4
ffffffffc0200c58:	439c                	lw	a5,0(a5)
ffffffffc0200c5a:	97ba                	add	a5,a5,a4
ffffffffc0200c5c:	8782                	jr	a5
        break;
    case CAUSE_LOAD_PAGE_FAULT:
        cprintf("Load page fault\n");
        break;
    case CAUSE_STORE_PAGE_FAULT:
        cprintf("Store/AMO page fault\n");
ffffffffc0200c5e:	00004517          	auipc	a0,0x4
ffffffffc0200c62:	cba50513          	addi	a0,a0,-838 # ffffffffc0204918 <commands+0x7d0>
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200c66:	6402                	ld	s0,0(sp)
ffffffffc0200c68:	60a2                	ld	ra,8(sp)
ffffffffc0200c6a:	0141                	addi	sp,sp,16
        cprintf("Instruction access fault\n");
ffffffffc0200c6c:	d28ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Instruction address misaligned\n");
ffffffffc0200c70:	00004517          	auipc	a0,0x4
ffffffffc0200c74:	b0850513          	addi	a0,a0,-1272 # ffffffffc0204778 <commands+0x630>
ffffffffc0200c78:	b7fd                	j	ffffffffc0200c66 <exception_handler+0x2c>
        cprintf("Instruction access fault\n");
ffffffffc0200c7a:	00004517          	auipc	a0,0x4
ffffffffc0200c7e:	b1e50513          	addi	a0,a0,-1250 # ffffffffc0204798 <commands+0x650>
ffffffffc0200c82:	b7d5                	j	ffffffffc0200c66 <exception_handler+0x2c>
        cprintf("Illegal instruction caught at 0x%08x\n", tf->epc); // 2310675: 打印异常地址
ffffffffc0200c84:	10853583          	ld	a1,264(a0)
ffffffffc0200c88:	00004517          	auipc	a0,0x4
ffffffffc0200c8c:	b3050513          	addi	a0,a0,-1232 # ffffffffc02047b8 <commands+0x670>
        cprintf("Breakpoint caught at 0x%08x\n", tf->epc);           // 2310675: 标注断点地址
ffffffffc0200c90:	d04ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        tf->epc = advance_pc(tf->epc);                               // 2310675: 跳过断点指令继续执行
ffffffffc0200c94:	10843703          	ld	a4,264(s0)
    return (inst & 0x3) == 0x3 ? epc + 4 : epc + 2; // 2310675: 兼容32位与压缩指令长度
ffffffffc0200c98:	460d                	li	a2,3
ffffffffc0200c9a:	00075783          	lhu	a5,0(a4)
ffffffffc0200c9e:	00270693          	addi	a3,a4,2
ffffffffc0200ca2:	8b8d                	andi	a5,a5,3
ffffffffc0200ca4:	00c79463          	bne	a5,a2,ffffffffc0200cac <exception_handler+0x72>
ffffffffc0200ca8:	00470693          	addi	a3,a4,4
}
ffffffffc0200cac:	60a2                	ld	ra,8(sp)
        tf->epc = advance_pc(tf->epc);                               // 2310675: 跳过断点指令继续执行
ffffffffc0200cae:	10d43423          	sd	a3,264(s0)
}
ffffffffc0200cb2:	6402                	ld	s0,0(sp)
ffffffffc0200cb4:	0141                	addi	sp,sp,16
ffffffffc0200cb6:	8082                	ret
        cprintf("Breakpoint caught at 0x%08x\n", tf->epc);           // 2310675: 标注断点地址
ffffffffc0200cb8:	10853583          	ld	a1,264(a0)
ffffffffc0200cbc:	00004517          	auipc	a0,0x4
ffffffffc0200cc0:	b2450513          	addi	a0,a0,-1244 # ffffffffc02047e0 <commands+0x698>
ffffffffc0200cc4:	b7f1                	j	ffffffffc0200c90 <exception_handler+0x56>
        cprintf("Load address misaligned\n");
ffffffffc0200cc6:	00004517          	auipc	a0,0x4
ffffffffc0200cca:	b3a50513          	addi	a0,a0,-1222 # ffffffffc0204800 <commands+0x6b8>
ffffffffc0200cce:	bf61                	j	ffffffffc0200c66 <exception_handler+0x2c>
        cprintf("Load access fault\n");
ffffffffc0200cd0:	00004517          	auipc	a0,0x4
ffffffffc0200cd4:	b5050513          	addi	a0,a0,-1200 # ffffffffc0204820 <commands+0x6d8>
ffffffffc0200cd8:	b779                	j	ffffffffc0200c66 <exception_handler+0x2c>
        cprintf("AMO address misaligned\n");
ffffffffc0200cda:	00004517          	auipc	a0,0x4
ffffffffc0200cde:	b5e50513          	addi	a0,a0,-1186 # ffffffffc0204838 <commands+0x6f0>
ffffffffc0200ce2:	b751                	j	ffffffffc0200c66 <exception_handler+0x2c>
        cprintf("Store/AMO access fault\n");
ffffffffc0200ce4:	00004517          	auipc	a0,0x4
ffffffffc0200ce8:	b6c50513          	addi	a0,a0,-1172 # ffffffffc0204850 <commands+0x708>
ffffffffc0200cec:	bfad                	j	ffffffffc0200c66 <exception_handler+0x2c>
        cprintf("Environment call from U-mode\n");
ffffffffc0200cee:	00004517          	auipc	a0,0x4
ffffffffc0200cf2:	b7a50513          	addi	a0,a0,-1158 # ffffffffc0204868 <commands+0x720>
ffffffffc0200cf6:	bf85                	j	ffffffffc0200c66 <exception_handler+0x2c>
        cprintf("Environment call from S-mode\n");
ffffffffc0200cf8:	00004517          	auipc	a0,0x4
ffffffffc0200cfc:	b9050513          	addi	a0,a0,-1136 # ffffffffc0204888 <commands+0x740>
ffffffffc0200d00:	b79d                	j	ffffffffc0200c66 <exception_handler+0x2c>
        cprintf("Environment call from H-mode\n");
ffffffffc0200d02:	00004517          	auipc	a0,0x4
ffffffffc0200d06:	ba650513          	addi	a0,a0,-1114 # ffffffffc02048a8 <commands+0x760>
ffffffffc0200d0a:	bfb1                	j	ffffffffc0200c66 <exception_handler+0x2c>
        cprintf("Environment call from M-mode\n");
ffffffffc0200d0c:	00004517          	auipc	a0,0x4
ffffffffc0200d10:	bbc50513          	addi	a0,a0,-1092 # ffffffffc02048c8 <commands+0x780>
ffffffffc0200d14:	bf89                	j	ffffffffc0200c66 <exception_handler+0x2c>
        cprintf("Instruction page fault\n");
ffffffffc0200d16:	00004517          	auipc	a0,0x4
ffffffffc0200d1a:	bd250513          	addi	a0,a0,-1070 # ffffffffc02048e8 <commands+0x7a0>
ffffffffc0200d1e:	b7a1                	j	ffffffffc0200c66 <exception_handler+0x2c>
        cprintf("Load page fault\n");
ffffffffc0200d20:	00004517          	auipc	a0,0x4
ffffffffc0200d24:	be050513          	addi	a0,a0,-1056 # ffffffffc0204900 <commands+0x7b8>
ffffffffc0200d28:	bf3d                	j	ffffffffc0200c66 <exception_handler+0x2c>
        print_trapframe(tf);
ffffffffc0200d2a:	8522                	mv	a0,s0
}
ffffffffc0200d2c:	6402                	ld	s0,0(sp)
ffffffffc0200d2e:	60a2                	ld	ra,8(sp)
ffffffffc0200d30:	0141                	addi	sp,sp,16
        print_trapframe(tf);
ffffffffc0200d32:	b3fd                	j	ffffffffc0200b20 <print_trapframe>

ffffffffc0200d34 <trap>:
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf)
{
    // dispatch based on what type of trap occurred
    if ((intptr_t)tf->cause < 0)
ffffffffc0200d34:	11853783          	ld	a5,280(a0)
ffffffffc0200d38:	0007c363          	bltz	a5,ffffffffc0200d3e <trap+0xa>
        interrupt_handler(tf);
    }
    else
    {
        // exceptions
        exception_handler(tf);
ffffffffc0200d3c:	bdfd                	j	ffffffffc0200c3a <exception_handler>
        interrupt_handler(tf);
ffffffffc0200d3e:	b591                	j	ffffffffc0200b82 <interrupt_handler>

ffffffffc0200d40 <__alltraps>:
    LOAD  x2,2*REGBYTES(sp)
    .endm

    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc0200d40:	14011073          	csrw	sscratch,sp
ffffffffc0200d44:	712d                	addi	sp,sp,-288
ffffffffc0200d46:	e406                	sd	ra,8(sp)
ffffffffc0200d48:	ec0e                	sd	gp,24(sp)
ffffffffc0200d4a:	f012                	sd	tp,32(sp)
ffffffffc0200d4c:	f416                	sd	t0,40(sp)
ffffffffc0200d4e:	f81a                	sd	t1,48(sp)
ffffffffc0200d50:	fc1e                	sd	t2,56(sp)
ffffffffc0200d52:	e0a2                	sd	s0,64(sp)
ffffffffc0200d54:	e4a6                	sd	s1,72(sp)
ffffffffc0200d56:	e8aa                	sd	a0,80(sp)
ffffffffc0200d58:	ecae                	sd	a1,88(sp)
ffffffffc0200d5a:	f0b2                	sd	a2,96(sp)
ffffffffc0200d5c:	f4b6                	sd	a3,104(sp)
ffffffffc0200d5e:	f8ba                	sd	a4,112(sp)
ffffffffc0200d60:	fcbe                	sd	a5,120(sp)
ffffffffc0200d62:	e142                	sd	a6,128(sp)
ffffffffc0200d64:	e546                	sd	a7,136(sp)
ffffffffc0200d66:	e94a                	sd	s2,144(sp)
ffffffffc0200d68:	ed4e                	sd	s3,152(sp)
ffffffffc0200d6a:	f152                	sd	s4,160(sp)
ffffffffc0200d6c:	f556                	sd	s5,168(sp)
ffffffffc0200d6e:	f95a                	sd	s6,176(sp)
ffffffffc0200d70:	fd5e                	sd	s7,184(sp)
ffffffffc0200d72:	e1e2                	sd	s8,192(sp)
ffffffffc0200d74:	e5e6                	sd	s9,200(sp)
ffffffffc0200d76:	e9ea                	sd	s10,208(sp)
ffffffffc0200d78:	edee                	sd	s11,216(sp)
ffffffffc0200d7a:	f1f2                	sd	t3,224(sp)
ffffffffc0200d7c:	f5f6                	sd	t4,232(sp)
ffffffffc0200d7e:	f9fa                	sd	t5,240(sp)
ffffffffc0200d80:	fdfe                	sd	t6,248(sp)
ffffffffc0200d82:	14002473          	csrr	s0,sscratch
ffffffffc0200d86:	100024f3          	csrr	s1,sstatus
ffffffffc0200d8a:	14102973          	csrr	s2,sepc
ffffffffc0200d8e:	143029f3          	csrr	s3,stval
ffffffffc0200d92:	14202a73          	csrr	s4,scause
ffffffffc0200d96:	e822                	sd	s0,16(sp)
ffffffffc0200d98:	e226                	sd	s1,256(sp)
ffffffffc0200d9a:	e64a                	sd	s2,264(sp)
ffffffffc0200d9c:	ea4e                	sd	s3,272(sp)
ffffffffc0200d9e:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200da0:	850a                	mv	a0,sp
    jal trap
ffffffffc0200da2:	f93ff0ef          	jal	ra,ffffffffc0200d34 <trap>

ffffffffc0200da6 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200da6:	6492                	ld	s1,256(sp)
ffffffffc0200da8:	6932                	ld	s2,264(sp)
ffffffffc0200daa:	10049073          	csrw	sstatus,s1
ffffffffc0200dae:	14191073          	csrw	sepc,s2
ffffffffc0200db2:	60a2                	ld	ra,8(sp)
ffffffffc0200db4:	61e2                	ld	gp,24(sp)
ffffffffc0200db6:	7202                	ld	tp,32(sp)
ffffffffc0200db8:	72a2                	ld	t0,40(sp)
ffffffffc0200dba:	7342                	ld	t1,48(sp)
ffffffffc0200dbc:	73e2                	ld	t2,56(sp)
ffffffffc0200dbe:	6406                	ld	s0,64(sp)
ffffffffc0200dc0:	64a6                	ld	s1,72(sp)
ffffffffc0200dc2:	6546                	ld	a0,80(sp)
ffffffffc0200dc4:	65e6                	ld	a1,88(sp)
ffffffffc0200dc6:	7606                	ld	a2,96(sp)
ffffffffc0200dc8:	76a6                	ld	a3,104(sp)
ffffffffc0200dca:	7746                	ld	a4,112(sp)
ffffffffc0200dcc:	77e6                	ld	a5,120(sp)
ffffffffc0200dce:	680a                	ld	a6,128(sp)
ffffffffc0200dd0:	68aa                	ld	a7,136(sp)
ffffffffc0200dd2:	694a                	ld	s2,144(sp)
ffffffffc0200dd4:	69ea                	ld	s3,152(sp)
ffffffffc0200dd6:	7a0a                	ld	s4,160(sp)
ffffffffc0200dd8:	7aaa                	ld	s5,168(sp)
ffffffffc0200dda:	7b4a                	ld	s6,176(sp)
ffffffffc0200ddc:	7bea                	ld	s7,184(sp)
ffffffffc0200dde:	6c0e                	ld	s8,192(sp)
ffffffffc0200de0:	6cae                	ld	s9,200(sp)
ffffffffc0200de2:	6d4e                	ld	s10,208(sp)
ffffffffc0200de4:	6dee                	ld	s11,216(sp)
ffffffffc0200de6:	7e0e                	ld	t3,224(sp)
ffffffffc0200de8:	7eae                	ld	t4,232(sp)
ffffffffc0200dea:	7f4e                	ld	t5,240(sp)
ffffffffc0200dec:	7fee                	ld	t6,248(sp)
ffffffffc0200dee:	6142                	ld	sp,16(sp)
    # go back from supervisor call
    sret
ffffffffc0200df0:	10200073          	sret

ffffffffc0200df4 <forkrets>:
    .globl forkrets
forkrets:
    # set stack to this new process's trapframe
    # 2310675: 新创建进程首次运行的统一入口，switch_to返回后会跳转到这里
    # a0指向子线程的trapframe（来自copy_thread中设置的context.sp），将其作为当前栈
    move sp, a0                   # 2310675: sp = proc->tf，指向内核栈顶的trapframe
ffffffffc0200df4:	812a                	mv	sp,a0
    # 直接复用通用的中断返回路径，完成寄存器恢复与sret
    j __trapret                   # 2310675: 跳转到__trapret，恢复trapframe中所有寄存器并执行sret
ffffffffc0200df6:	bf45                	j	ffffffffc0200da6 <__trapret>
	...

ffffffffc0200dfa <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200dfa:	00008797          	auipc	a5,0x8
ffffffffc0200dfe:	63678793          	addi	a5,a5,1590 # ffffffffc0209430 <free_area>
ffffffffc0200e02:	e79c                	sd	a5,8(a5)
ffffffffc0200e04:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
default_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200e06:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200e0a:	8082                	ret

ffffffffc0200e0c <default_nr_free_pages>:
}

static size_t
default_nr_free_pages(void) {
    return nr_free;
}
ffffffffc0200e0c:	00008517          	auipc	a0,0x8
ffffffffc0200e10:	63456503          	lwu	a0,1588(a0) # ffffffffc0209440 <free_area+0x10>
ffffffffc0200e14:	8082                	ret

ffffffffc0200e16 <default_check>:
}

// LAB2: below code is used to check the first fit allocation algorithm 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
ffffffffc0200e16:	715d                	addi	sp,sp,-80
ffffffffc0200e18:	e0a2                	sd	s0,64(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200e1a:	00008417          	auipc	s0,0x8
ffffffffc0200e1e:	61640413          	addi	s0,s0,1558 # ffffffffc0209430 <free_area>
ffffffffc0200e22:	641c                	ld	a5,8(s0)
ffffffffc0200e24:	e486                	sd	ra,72(sp)
ffffffffc0200e26:	fc26                	sd	s1,56(sp)
ffffffffc0200e28:	f84a                	sd	s2,48(sp)
ffffffffc0200e2a:	f44e                	sd	s3,40(sp)
ffffffffc0200e2c:	f052                	sd	s4,32(sp)
ffffffffc0200e2e:	ec56                	sd	s5,24(sp)
ffffffffc0200e30:	e85a                	sd	s6,16(sp)
ffffffffc0200e32:	e45e                	sd	s7,8(sp)
ffffffffc0200e34:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200e36:	2a878d63          	beq	a5,s0,ffffffffc02010f0 <default_check+0x2da>
    int count = 0, total = 0;
ffffffffc0200e3a:	4481                	li	s1,0
ffffffffc0200e3c:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200e3e:	ff07b703          	ld	a4,-16(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200e42:	8b09                	andi	a4,a4,2
ffffffffc0200e44:	2a070a63          	beqz	a4,ffffffffc02010f8 <default_check+0x2e2>
        count ++, total += p->property;
ffffffffc0200e48:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200e4c:	679c                	ld	a5,8(a5)
ffffffffc0200e4e:	2905                	addiw	s2,s2,1
ffffffffc0200e50:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200e52:	fe8796e3          	bne	a5,s0,ffffffffc0200e3e <default_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc0200e56:	89a6                	mv	s3,s1
ffffffffc0200e58:	6db000ef          	jal	ra,ffffffffc0201d32 <nr_free_pages>
ffffffffc0200e5c:	6f351e63          	bne	a0,s3,ffffffffc0201558 <default_check+0x742>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200e60:	4505                	li	a0,1
ffffffffc0200e62:	653000ef          	jal	ra,ffffffffc0201cb4 <alloc_pages>
ffffffffc0200e66:	8aaa                	mv	s5,a0
ffffffffc0200e68:	42050863          	beqz	a0,ffffffffc0201298 <default_check+0x482>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200e6c:	4505                	li	a0,1
ffffffffc0200e6e:	647000ef          	jal	ra,ffffffffc0201cb4 <alloc_pages>
ffffffffc0200e72:	89aa                	mv	s3,a0
ffffffffc0200e74:	70050263          	beqz	a0,ffffffffc0201578 <default_check+0x762>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200e78:	4505                	li	a0,1
ffffffffc0200e7a:	63b000ef          	jal	ra,ffffffffc0201cb4 <alloc_pages>
ffffffffc0200e7e:	8a2a                	mv	s4,a0
ffffffffc0200e80:	48050c63          	beqz	a0,ffffffffc0201318 <default_check+0x502>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200e84:	293a8a63          	beq	s5,s3,ffffffffc0201118 <default_check+0x302>
ffffffffc0200e88:	28aa8863          	beq	s5,a0,ffffffffc0201118 <default_check+0x302>
ffffffffc0200e8c:	28a98663          	beq	s3,a0,ffffffffc0201118 <default_check+0x302>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200e90:	000aa783          	lw	a5,0(s5)
ffffffffc0200e94:	2a079263          	bnez	a5,ffffffffc0201138 <default_check+0x322>
ffffffffc0200e98:	0009a783          	lw	a5,0(s3)
ffffffffc0200e9c:	28079e63          	bnez	a5,ffffffffc0201138 <default_check+0x322>
ffffffffc0200ea0:	411c                	lw	a5,0(a0)
ffffffffc0200ea2:	28079b63          	bnez	a5,ffffffffc0201138 <default_check+0x322>
extern uint_t va_pa_offset;

static inline ppn_t
page2ppn(struct Page *page)
{
    return page - pages + nbase;
ffffffffc0200ea6:	0000c797          	auipc	a5,0xc
ffffffffc0200eaa:	6127b783          	ld	a5,1554(a5) # ffffffffc020d4b8 <pages>
ffffffffc0200eae:	40fa8733          	sub	a4,s5,a5
ffffffffc0200eb2:	00005617          	auipc	a2,0x5
ffffffffc0200eb6:	b9663603          	ld	a2,-1130(a2) # ffffffffc0205a48 <nbase>
ffffffffc0200eba:	8719                	srai	a4,a4,0x6
ffffffffc0200ebc:	9732                	add	a4,a4,a2
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200ebe:	0000c697          	auipc	a3,0xc
ffffffffc0200ec2:	5f26b683          	ld	a3,1522(a3) # ffffffffc020d4b0 <npage>
ffffffffc0200ec6:	06b2                	slli	a3,a3,0xc
}

static inline uintptr_t
page2pa(struct Page *page)
{
    return page2ppn(page) << PGSHIFT;
ffffffffc0200ec8:	0732                	slli	a4,a4,0xc
ffffffffc0200eca:	28d77763          	bgeu	a4,a3,ffffffffc0201158 <default_check+0x342>
    return page - pages + nbase;
ffffffffc0200ece:	40f98733          	sub	a4,s3,a5
ffffffffc0200ed2:	8719                	srai	a4,a4,0x6
ffffffffc0200ed4:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200ed6:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200ed8:	4cd77063          	bgeu	a4,a3,ffffffffc0201398 <default_check+0x582>
    return page - pages + nbase;
ffffffffc0200edc:	40f507b3          	sub	a5,a0,a5
ffffffffc0200ee0:	8799                	srai	a5,a5,0x6
ffffffffc0200ee2:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200ee4:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200ee6:	30d7f963          	bgeu	a5,a3,ffffffffc02011f8 <default_check+0x3e2>
    assert(alloc_page() == NULL);
ffffffffc0200eea:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200eec:	00043c03          	ld	s8,0(s0)
ffffffffc0200ef0:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc0200ef4:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc0200ef8:	e400                	sd	s0,8(s0)
ffffffffc0200efa:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc0200efc:	00008797          	auipc	a5,0x8
ffffffffc0200f00:	5407a223          	sw	zero,1348(a5) # ffffffffc0209440 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0200f04:	5b1000ef          	jal	ra,ffffffffc0201cb4 <alloc_pages>
ffffffffc0200f08:	2c051863          	bnez	a0,ffffffffc02011d8 <default_check+0x3c2>
    free_page(p0);
ffffffffc0200f0c:	4585                	li	a1,1
ffffffffc0200f0e:	8556                	mv	a0,s5
ffffffffc0200f10:	5e3000ef          	jal	ra,ffffffffc0201cf2 <free_pages>
    free_page(p1);
ffffffffc0200f14:	4585                	li	a1,1
ffffffffc0200f16:	854e                	mv	a0,s3
ffffffffc0200f18:	5db000ef          	jal	ra,ffffffffc0201cf2 <free_pages>
    free_page(p2);
ffffffffc0200f1c:	4585                	li	a1,1
ffffffffc0200f1e:	8552                	mv	a0,s4
ffffffffc0200f20:	5d3000ef          	jal	ra,ffffffffc0201cf2 <free_pages>
    assert(nr_free == 3);
ffffffffc0200f24:	4818                	lw	a4,16(s0)
ffffffffc0200f26:	478d                	li	a5,3
ffffffffc0200f28:	28f71863          	bne	a4,a5,ffffffffc02011b8 <default_check+0x3a2>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200f2c:	4505                	li	a0,1
ffffffffc0200f2e:	587000ef          	jal	ra,ffffffffc0201cb4 <alloc_pages>
ffffffffc0200f32:	89aa                	mv	s3,a0
ffffffffc0200f34:	26050263          	beqz	a0,ffffffffc0201198 <default_check+0x382>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200f38:	4505                	li	a0,1
ffffffffc0200f3a:	57b000ef          	jal	ra,ffffffffc0201cb4 <alloc_pages>
ffffffffc0200f3e:	8aaa                	mv	s5,a0
ffffffffc0200f40:	3a050c63          	beqz	a0,ffffffffc02012f8 <default_check+0x4e2>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200f44:	4505                	li	a0,1
ffffffffc0200f46:	56f000ef          	jal	ra,ffffffffc0201cb4 <alloc_pages>
ffffffffc0200f4a:	8a2a                	mv	s4,a0
ffffffffc0200f4c:	38050663          	beqz	a0,ffffffffc02012d8 <default_check+0x4c2>
    assert(alloc_page() == NULL);
ffffffffc0200f50:	4505                	li	a0,1
ffffffffc0200f52:	563000ef          	jal	ra,ffffffffc0201cb4 <alloc_pages>
ffffffffc0200f56:	36051163          	bnez	a0,ffffffffc02012b8 <default_check+0x4a2>
    free_page(p0);
ffffffffc0200f5a:	4585                	li	a1,1
ffffffffc0200f5c:	854e                	mv	a0,s3
ffffffffc0200f5e:	595000ef          	jal	ra,ffffffffc0201cf2 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0200f62:	641c                	ld	a5,8(s0)
ffffffffc0200f64:	20878a63          	beq	a5,s0,ffffffffc0201178 <default_check+0x362>
    assert((p = alloc_page()) == p0);
ffffffffc0200f68:	4505                	li	a0,1
ffffffffc0200f6a:	54b000ef          	jal	ra,ffffffffc0201cb4 <alloc_pages>
ffffffffc0200f6e:	30a99563          	bne	s3,a0,ffffffffc0201278 <default_check+0x462>
    assert(alloc_page() == NULL);
ffffffffc0200f72:	4505                	li	a0,1
ffffffffc0200f74:	541000ef          	jal	ra,ffffffffc0201cb4 <alloc_pages>
ffffffffc0200f78:	2e051063          	bnez	a0,ffffffffc0201258 <default_check+0x442>
    assert(nr_free == 0);
ffffffffc0200f7c:	481c                	lw	a5,16(s0)
ffffffffc0200f7e:	2a079d63          	bnez	a5,ffffffffc0201238 <default_check+0x422>
    free_page(p);
ffffffffc0200f82:	854e                	mv	a0,s3
ffffffffc0200f84:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0200f86:	01843023          	sd	s8,0(s0)
ffffffffc0200f8a:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc0200f8e:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc0200f92:	561000ef          	jal	ra,ffffffffc0201cf2 <free_pages>
    free_page(p1);
ffffffffc0200f96:	4585                	li	a1,1
ffffffffc0200f98:	8556                	mv	a0,s5
ffffffffc0200f9a:	559000ef          	jal	ra,ffffffffc0201cf2 <free_pages>
    free_page(p2);
ffffffffc0200f9e:	4585                	li	a1,1
ffffffffc0200fa0:	8552                	mv	a0,s4
ffffffffc0200fa2:	551000ef          	jal	ra,ffffffffc0201cf2 <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0200fa6:	4515                	li	a0,5
ffffffffc0200fa8:	50d000ef          	jal	ra,ffffffffc0201cb4 <alloc_pages>
ffffffffc0200fac:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0200fae:	26050563          	beqz	a0,ffffffffc0201218 <default_check+0x402>
ffffffffc0200fb2:	651c                	ld	a5,8(a0)
ffffffffc0200fb4:	8385                	srli	a5,a5,0x1
    assert(!PageProperty(p0));
ffffffffc0200fb6:	8b85                	andi	a5,a5,1
ffffffffc0200fb8:	54079063          	bnez	a5,ffffffffc02014f8 <default_check+0x6e2>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0200fbc:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200fbe:	00043b03          	ld	s6,0(s0)
ffffffffc0200fc2:	00843a83          	ld	s5,8(s0)
ffffffffc0200fc6:	e000                	sd	s0,0(s0)
ffffffffc0200fc8:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc0200fca:	4eb000ef          	jal	ra,ffffffffc0201cb4 <alloc_pages>
ffffffffc0200fce:	50051563          	bnez	a0,ffffffffc02014d8 <default_check+0x6c2>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc0200fd2:	08098a13          	addi	s4,s3,128
ffffffffc0200fd6:	8552                	mv	a0,s4
ffffffffc0200fd8:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc0200fda:	01042b83          	lw	s7,16(s0)
    nr_free = 0;
ffffffffc0200fde:	00008797          	auipc	a5,0x8
ffffffffc0200fe2:	4607a123          	sw	zero,1122(a5) # ffffffffc0209440 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc0200fe6:	50d000ef          	jal	ra,ffffffffc0201cf2 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0200fea:	4511                	li	a0,4
ffffffffc0200fec:	4c9000ef          	jal	ra,ffffffffc0201cb4 <alloc_pages>
ffffffffc0200ff0:	4c051463          	bnez	a0,ffffffffc02014b8 <default_check+0x6a2>
ffffffffc0200ff4:	0889b783          	ld	a5,136(s3)
ffffffffc0200ff8:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0200ffa:	8b85                	andi	a5,a5,1
ffffffffc0200ffc:	48078e63          	beqz	a5,ffffffffc0201498 <default_check+0x682>
ffffffffc0201000:	0909a703          	lw	a4,144(s3)
ffffffffc0201004:	478d                	li	a5,3
ffffffffc0201006:	48f71963          	bne	a4,a5,ffffffffc0201498 <default_check+0x682>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc020100a:	450d                	li	a0,3
ffffffffc020100c:	4a9000ef          	jal	ra,ffffffffc0201cb4 <alloc_pages>
ffffffffc0201010:	8c2a                	mv	s8,a0
ffffffffc0201012:	46050363          	beqz	a0,ffffffffc0201478 <default_check+0x662>
    assert(alloc_page() == NULL);
ffffffffc0201016:	4505                	li	a0,1
ffffffffc0201018:	49d000ef          	jal	ra,ffffffffc0201cb4 <alloc_pages>
ffffffffc020101c:	42051e63          	bnez	a0,ffffffffc0201458 <default_check+0x642>
    assert(p0 + 2 == p1);
ffffffffc0201020:	418a1c63          	bne	s4,s8,ffffffffc0201438 <default_check+0x622>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc0201024:	4585                	li	a1,1
ffffffffc0201026:	854e                	mv	a0,s3
ffffffffc0201028:	4cb000ef          	jal	ra,ffffffffc0201cf2 <free_pages>
    free_pages(p1, 3);
ffffffffc020102c:	458d                	li	a1,3
ffffffffc020102e:	8552                	mv	a0,s4
ffffffffc0201030:	4c3000ef          	jal	ra,ffffffffc0201cf2 <free_pages>
ffffffffc0201034:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc0201038:	04098c13          	addi	s8,s3,64
ffffffffc020103c:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc020103e:	8b85                	andi	a5,a5,1
ffffffffc0201040:	3c078c63          	beqz	a5,ffffffffc0201418 <default_check+0x602>
ffffffffc0201044:	0109a703          	lw	a4,16(s3)
ffffffffc0201048:	4785                	li	a5,1
ffffffffc020104a:	3cf71763          	bne	a4,a5,ffffffffc0201418 <default_check+0x602>
ffffffffc020104e:	008a3783          	ld	a5,8(s4)
ffffffffc0201052:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0201054:	8b85                	andi	a5,a5,1
ffffffffc0201056:	3a078163          	beqz	a5,ffffffffc02013f8 <default_check+0x5e2>
ffffffffc020105a:	010a2703          	lw	a4,16(s4)
ffffffffc020105e:	478d                	li	a5,3
ffffffffc0201060:	38f71c63          	bne	a4,a5,ffffffffc02013f8 <default_check+0x5e2>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0201064:	4505                	li	a0,1
ffffffffc0201066:	44f000ef          	jal	ra,ffffffffc0201cb4 <alloc_pages>
ffffffffc020106a:	36a99763          	bne	s3,a0,ffffffffc02013d8 <default_check+0x5c2>
    free_page(p0);
ffffffffc020106e:	4585                	li	a1,1
ffffffffc0201070:	483000ef          	jal	ra,ffffffffc0201cf2 <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0201074:	4509                	li	a0,2
ffffffffc0201076:	43f000ef          	jal	ra,ffffffffc0201cb4 <alloc_pages>
ffffffffc020107a:	32aa1f63          	bne	s4,a0,ffffffffc02013b8 <default_check+0x5a2>

    free_pages(p0, 2);
ffffffffc020107e:	4589                	li	a1,2
ffffffffc0201080:	473000ef          	jal	ra,ffffffffc0201cf2 <free_pages>
    free_page(p2);
ffffffffc0201084:	4585                	li	a1,1
ffffffffc0201086:	8562                	mv	a0,s8
ffffffffc0201088:	46b000ef          	jal	ra,ffffffffc0201cf2 <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc020108c:	4515                	li	a0,5
ffffffffc020108e:	427000ef          	jal	ra,ffffffffc0201cb4 <alloc_pages>
ffffffffc0201092:	89aa                	mv	s3,a0
ffffffffc0201094:	48050263          	beqz	a0,ffffffffc0201518 <default_check+0x702>
    assert(alloc_page() == NULL);
ffffffffc0201098:	4505                	li	a0,1
ffffffffc020109a:	41b000ef          	jal	ra,ffffffffc0201cb4 <alloc_pages>
ffffffffc020109e:	2c051d63          	bnez	a0,ffffffffc0201378 <default_check+0x562>

    assert(nr_free == 0);
ffffffffc02010a2:	481c                	lw	a5,16(s0)
ffffffffc02010a4:	2a079a63          	bnez	a5,ffffffffc0201358 <default_check+0x542>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc02010a8:	4595                	li	a1,5
ffffffffc02010aa:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc02010ac:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc02010b0:	01643023          	sd	s6,0(s0)
ffffffffc02010b4:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc02010b8:	43b000ef          	jal	ra,ffffffffc0201cf2 <free_pages>
    return listelm->next;
ffffffffc02010bc:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc02010be:	00878963          	beq	a5,s0,ffffffffc02010d0 <default_check+0x2ba>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc02010c2:	ff87a703          	lw	a4,-8(a5)
ffffffffc02010c6:	679c                	ld	a5,8(a5)
ffffffffc02010c8:	397d                	addiw	s2,s2,-1
ffffffffc02010ca:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc02010cc:	fe879be3          	bne	a5,s0,ffffffffc02010c2 <default_check+0x2ac>
    }
    assert(count == 0);
ffffffffc02010d0:	26091463          	bnez	s2,ffffffffc0201338 <default_check+0x522>
    assert(total == 0);
ffffffffc02010d4:	46049263          	bnez	s1,ffffffffc0201538 <default_check+0x722>
}
ffffffffc02010d8:	60a6                	ld	ra,72(sp)
ffffffffc02010da:	6406                	ld	s0,64(sp)
ffffffffc02010dc:	74e2                	ld	s1,56(sp)
ffffffffc02010de:	7942                	ld	s2,48(sp)
ffffffffc02010e0:	79a2                	ld	s3,40(sp)
ffffffffc02010e2:	7a02                	ld	s4,32(sp)
ffffffffc02010e4:	6ae2                	ld	s5,24(sp)
ffffffffc02010e6:	6b42                	ld	s6,16(sp)
ffffffffc02010e8:	6ba2                	ld	s7,8(sp)
ffffffffc02010ea:	6c02                	ld	s8,0(sp)
ffffffffc02010ec:	6161                	addi	sp,sp,80
ffffffffc02010ee:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc02010f0:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc02010f2:	4481                	li	s1,0
ffffffffc02010f4:	4901                	li	s2,0
ffffffffc02010f6:	b38d                	j	ffffffffc0200e58 <default_check+0x42>
        assert(PageProperty(p));
ffffffffc02010f8:	00004697          	auipc	a3,0x4
ffffffffc02010fc:	87868693          	addi	a3,a3,-1928 # ffffffffc0204970 <commands+0x828>
ffffffffc0201100:	00004617          	auipc	a2,0x4
ffffffffc0201104:	88060613          	addi	a2,a2,-1920 # ffffffffc0204980 <commands+0x838>
ffffffffc0201108:	0f000593          	li	a1,240
ffffffffc020110c:	00004517          	auipc	a0,0x4
ffffffffc0201110:	88c50513          	addi	a0,a0,-1908 # ffffffffc0204998 <commands+0x850>
ffffffffc0201114:	b46ff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0201118:	00004697          	auipc	a3,0x4
ffffffffc020111c:	91868693          	addi	a3,a3,-1768 # ffffffffc0204a30 <commands+0x8e8>
ffffffffc0201120:	00004617          	auipc	a2,0x4
ffffffffc0201124:	86060613          	addi	a2,a2,-1952 # ffffffffc0204980 <commands+0x838>
ffffffffc0201128:	0bd00593          	li	a1,189
ffffffffc020112c:	00004517          	auipc	a0,0x4
ffffffffc0201130:	86c50513          	addi	a0,a0,-1940 # ffffffffc0204998 <commands+0x850>
ffffffffc0201134:	b26ff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0201138:	00004697          	auipc	a3,0x4
ffffffffc020113c:	92068693          	addi	a3,a3,-1760 # ffffffffc0204a58 <commands+0x910>
ffffffffc0201140:	00004617          	auipc	a2,0x4
ffffffffc0201144:	84060613          	addi	a2,a2,-1984 # ffffffffc0204980 <commands+0x838>
ffffffffc0201148:	0be00593          	li	a1,190
ffffffffc020114c:	00004517          	auipc	a0,0x4
ffffffffc0201150:	84c50513          	addi	a0,a0,-1972 # ffffffffc0204998 <commands+0x850>
ffffffffc0201154:	b06ff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0201158:	00004697          	auipc	a3,0x4
ffffffffc020115c:	94068693          	addi	a3,a3,-1728 # ffffffffc0204a98 <commands+0x950>
ffffffffc0201160:	00004617          	auipc	a2,0x4
ffffffffc0201164:	82060613          	addi	a2,a2,-2016 # ffffffffc0204980 <commands+0x838>
ffffffffc0201168:	0c000593          	li	a1,192
ffffffffc020116c:	00004517          	auipc	a0,0x4
ffffffffc0201170:	82c50513          	addi	a0,a0,-2004 # ffffffffc0204998 <commands+0x850>
ffffffffc0201174:	ae6ff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(!list_empty(&free_list));
ffffffffc0201178:	00004697          	auipc	a3,0x4
ffffffffc020117c:	9a868693          	addi	a3,a3,-1624 # ffffffffc0204b20 <commands+0x9d8>
ffffffffc0201180:	00004617          	auipc	a2,0x4
ffffffffc0201184:	80060613          	addi	a2,a2,-2048 # ffffffffc0204980 <commands+0x838>
ffffffffc0201188:	0d900593          	li	a1,217
ffffffffc020118c:	00004517          	auipc	a0,0x4
ffffffffc0201190:	80c50513          	addi	a0,a0,-2036 # ffffffffc0204998 <commands+0x850>
ffffffffc0201194:	ac6ff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201198:	00004697          	auipc	a3,0x4
ffffffffc020119c:	83868693          	addi	a3,a3,-1992 # ffffffffc02049d0 <commands+0x888>
ffffffffc02011a0:	00003617          	auipc	a2,0x3
ffffffffc02011a4:	7e060613          	addi	a2,a2,2016 # ffffffffc0204980 <commands+0x838>
ffffffffc02011a8:	0d200593          	li	a1,210
ffffffffc02011ac:	00003517          	auipc	a0,0x3
ffffffffc02011b0:	7ec50513          	addi	a0,a0,2028 # ffffffffc0204998 <commands+0x850>
ffffffffc02011b4:	aa6ff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(nr_free == 3);
ffffffffc02011b8:	00004697          	auipc	a3,0x4
ffffffffc02011bc:	95868693          	addi	a3,a3,-1704 # ffffffffc0204b10 <commands+0x9c8>
ffffffffc02011c0:	00003617          	auipc	a2,0x3
ffffffffc02011c4:	7c060613          	addi	a2,a2,1984 # ffffffffc0204980 <commands+0x838>
ffffffffc02011c8:	0d000593          	li	a1,208
ffffffffc02011cc:	00003517          	auipc	a0,0x3
ffffffffc02011d0:	7cc50513          	addi	a0,a0,1996 # ffffffffc0204998 <commands+0x850>
ffffffffc02011d4:	a86ff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(alloc_page() == NULL);
ffffffffc02011d8:	00004697          	auipc	a3,0x4
ffffffffc02011dc:	92068693          	addi	a3,a3,-1760 # ffffffffc0204af8 <commands+0x9b0>
ffffffffc02011e0:	00003617          	auipc	a2,0x3
ffffffffc02011e4:	7a060613          	addi	a2,a2,1952 # ffffffffc0204980 <commands+0x838>
ffffffffc02011e8:	0cb00593          	li	a1,203
ffffffffc02011ec:	00003517          	auipc	a0,0x3
ffffffffc02011f0:	7ac50513          	addi	a0,a0,1964 # ffffffffc0204998 <commands+0x850>
ffffffffc02011f4:	a66ff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc02011f8:	00004697          	auipc	a3,0x4
ffffffffc02011fc:	8e068693          	addi	a3,a3,-1824 # ffffffffc0204ad8 <commands+0x990>
ffffffffc0201200:	00003617          	auipc	a2,0x3
ffffffffc0201204:	78060613          	addi	a2,a2,1920 # ffffffffc0204980 <commands+0x838>
ffffffffc0201208:	0c200593          	li	a1,194
ffffffffc020120c:	00003517          	auipc	a0,0x3
ffffffffc0201210:	78c50513          	addi	a0,a0,1932 # ffffffffc0204998 <commands+0x850>
ffffffffc0201214:	a46ff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(p0 != NULL);
ffffffffc0201218:	00004697          	auipc	a3,0x4
ffffffffc020121c:	95068693          	addi	a3,a3,-1712 # ffffffffc0204b68 <commands+0xa20>
ffffffffc0201220:	00003617          	auipc	a2,0x3
ffffffffc0201224:	76060613          	addi	a2,a2,1888 # ffffffffc0204980 <commands+0x838>
ffffffffc0201228:	0f800593          	li	a1,248
ffffffffc020122c:	00003517          	auipc	a0,0x3
ffffffffc0201230:	76c50513          	addi	a0,a0,1900 # ffffffffc0204998 <commands+0x850>
ffffffffc0201234:	a26ff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(nr_free == 0);
ffffffffc0201238:	00004697          	auipc	a3,0x4
ffffffffc020123c:	92068693          	addi	a3,a3,-1760 # ffffffffc0204b58 <commands+0xa10>
ffffffffc0201240:	00003617          	auipc	a2,0x3
ffffffffc0201244:	74060613          	addi	a2,a2,1856 # ffffffffc0204980 <commands+0x838>
ffffffffc0201248:	0df00593          	li	a1,223
ffffffffc020124c:	00003517          	auipc	a0,0x3
ffffffffc0201250:	74c50513          	addi	a0,a0,1868 # ffffffffc0204998 <commands+0x850>
ffffffffc0201254:	a06ff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201258:	00004697          	auipc	a3,0x4
ffffffffc020125c:	8a068693          	addi	a3,a3,-1888 # ffffffffc0204af8 <commands+0x9b0>
ffffffffc0201260:	00003617          	auipc	a2,0x3
ffffffffc0201264:	72060613          	addi	a2,a2,1824 # ffffffffc0204980 <commands+0x838>
ffffffffc0201268:	0dd00593          	li	a1,221
ffffffffc020126c:	00003517          	auipc	a0,0x3
ffffffffc0201270:	72c50513          	addi	a0,a0,1836 # ffffffffc0204998 <commands+0x850>
ffffffffc0201274:	9e6ff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0201278:	00004697          	auipc	a3,0x4
ffffffffc020127c:	8c068693          	addi	a3,a3,-1856 # ffffffffc0204b38 <commands+0x9f0>
ffffffffc0201280:	00003617          	auipc	a2,0x3
ffffffffc0201284:	70060613          	addi	a2,a2,1792 # ffffffffc0204980 <commands+0x838>
ffffffffc0201288:	0dc00593          	li	a1,220
ffffffffc020128c:	00003517          	auipc	a0,0x3
ffffffffc0201290:	70c50513          	addi	a0,a0,1804 # ffffffffc0204998 <commands+0x850>
ffffffffc0201294:	9c6ff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201298:	00003697          	auipc	a3,0x3
ffffffffc020129c:	73868693          	addi	a3,a3,1848 # ffffffffc02049d0 <commands+0x888>
ffffffffc02012a0:	00003617          	auipc	a2,0x3
ffffffffc02012a4:	6e060613          	addi	a2,a2,1760 # ffffffffc0204980 <commands+0x838>
ffffffffc02012a8:	0b900593          	li	a1,185
ffffffffc02012ac:	00003517          	auipc	a0,0x3
ffffffffc02012b0:	6ec50513          	addi	a0,a0,1772 # ffffffffc0204998 <commands+0x850>
ffffffffc02012b4:	9a6ff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(alloc_page() == NULL);
ffffffffc02012b8:	00004697          	auipc	a3,0x4
ffffffffc02012bc:	84068693          	addi	a3,a3,-1984 # ffffffffc0204af8 <commands+0x9b0>
ffffffffc02012c0:	00003617          	auipc	a2,0x3
ffffffffc02012c4:	6c060613          	addi	a2,a2,1728 # ffffffffc0204980 <commands+0x838>
ffffffffc02012c8:	0d600593          	li	a1,214
ffffffffc02012cc:	00003517          	auipc	a0,0x3
ffffffffc02012d0:	6cc50513          	addi	a0,a0,1740 # ffffffffc0204998 <commands+0x850>
ffffffffc02012d4:	986ff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02012d8:	00003697          	auipc	a3,0x3
ffffffffc02012dc:	73868693          	addi	a3,a3,1848 # ffffffffc0204a10 <commands+0x8c8>
ffffffffc02012e0:	00003617          	auipc	a2,0x3
ffffffffc02012e4:	6a060613          	addi	a2,a2,1696 # ffffffffc0204980 <commands+0x838>
ffffffffc02012e8:	0d400593          	li	a1,212
ffffffffc02012ec:	00003517          	auipc	a0,0x3
ffffffffc02012f0:	6ac50513          	addi	a0,a0,1708 # ffffffffc0204998 <commands+0x850>
ffffffffc02012f4:	966ff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02012f8:	00003697          	auipc	a3,0x3
ffffffffc02012fc:	6f868693          	addi	a3,a3,1784 # ffffffffc02049f0 <commands+0x8a8>
ffffffffc0201300:	00003617          	auipc	a2,0x3
ffffffffc0201304:	68060613          	addi	a2,a2,1664 # ffffffffc0204980 <commands+0x838>
ffffffffc0201308:	0d300593          	li	a1,211
ffffffffc020130c:	00003517          	auipc	a0,0x3
ffffffffc0201310:	68c50513          	addi	a0,a0,1676 # ffffffffc0204998 <commands+0x850>
ffffffffc0201314:	946ff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201318:	00003697          	auipc	a3,0x3
ffffffffc020131c:	6f868693          	addi	a3,a3,1784 # ffffffffc0204a10 <commands+0x8c8>
ffffffffc0201320:	00003617          	auipc	a2,0x3
ffffffffc0201324:	66060613          	addi	a2,a2,1632 # ffffffffc0204980 <commands+0x838>
ffffffffc0201328:	0bb00593          	li	a1,187
ffffffffc020132c:	00003517          	auipc	a0,0x3
ffffffffc0201330:	66c50513          	addi	a0,a0,1644 # ffffffffc0204998 <commands+0x850>
ffffffffc0201334:	926ff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(count == 0);
ffffffffc0201338:	00004697          	auipc	a3,0x4
ffffffffc020133c:	98068693          	addi	a3,a3,-1664 # ffffffffc0204cb8 <commands+0xb70>
ffffffffc0201340:	00003617          	auipc	a2,0x3
ffffffffc0201344:	64060613          	addi	a2,a2,1600 # ffffffffc0204980 <commands+0x838>
ffffffffc0201348:	12500593          	li	a1,293
ffffffffc020134c:	00003517          	auipc	a0,0x3
ffffffffc0201350:	64c50513          	addi	a0,a0,1612 # ffffffffc0204998 <commands+0x850>
ffffffffc0201354:	906ff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(nr_free == 0);
ffffffffc0201358:	00004697          	auipc	a3,0x4
ffffffffc020135c:	80068693          	addi	a3,a3,-2048 # ffffffffc0204b58 <commands+0xa10>
ffffffffc0201360:	00003617          	auipc	a2,0x3
ffffffffc0201364:	62060613          	addi	a2,a2,1568 # ffffffffc0204980 <commands+0x838>
ffffffffc0201368:	11a00593          	li	a1,282
ffffffffc020136c:	00003517          	auipc	a0,0x3
ffffffffc0201370:	62c50513          	addi	a0,a0,1580 # ffffffffc0204998 <commands+0x850>
ffffffffc0201374:	8e6ff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201378:	00003697          	auipc	a3,0x3
ffffffffc020137c:	78068693          	addi	a3,a3,1920 # ffffffffc0204af8 <commands+0x9b0>
ffffffffc0201380:	00003617          	auipc	a2,0x3
ffffffffc0201384:	60060613          	addi	a2,a2,1536 # ffffffffc0204980 <commands+0x838>
ffffffffc0201388:	11800593          	li	a1,280
ffffffffc020138c:	00003517          	auipc	a0,0x3
ffffffffc0201390:	60c50513          	addi	a0,a0,1548 # ffffffffc0204998 <commands+0x850>
ffffffffc0201394:	8c6ff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0201398:	00003697          	auipc	a3,0x3
ffffffffc020139c:	72068693          	addi	a3,a3,1824 # ffffffffc0204ab8 <commands+0x970>
ffffffffc02013a0:	00003617          	auipc	a2,0x3
ffffffffc02013a4:	5e060613          	addi	a2,a2,1504 # ffffffffc0204980 <commands+0x838>
ffffffffc02013a8:	0c100593          	li	a1,193
ffffffffc02013ac:	00003517          	auipc	a0,0x3
ffffffffc02013b0:	5ec50513          	addi	a0,a0,1516 # ffffffffc0204998 <commands+0x850>
ffffffffc02013b4:	8a6ff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc02013b8:	00004697          	auipc	a3,0x4
ffffffffc02013bc:	8c068693          	addi	a3,a3,-1856 # ffffffffc0204c78 <commands+0xb30>
ffffffffc02013c0:	00003617          	auipc	a2,0x3
ffffffffc02013c4:	5c060613          	addi	a2,a2,1472 # ffffffffc0204980 <commands+0x838>
ffffffffc02013c8:	11200593          	li	a1,274
ffffffffc02013cc:	00003517          	auipc	a0,0x3
ffffffffc02013d0:	5cc50513          	addi	a0,a0,1484 # ffffffffc0204998 <commands+0x850>
ffffffffc02013d4:	886ff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc02013d8:	00004697          	auipc	a3,0x4
ffffffffc02013dc:	88068693          	addi	a3,a3,-1920 # ffffffffc0204c58 <commands+0xb10>
ffffffffc02013e0:	00003617          	auipc	a2,0x3
ffffffffc02013e4:	5a060613          	addi	a2,a2,1440 # ffffffffc0204980 <commands+0x838>
ffffffffc02013e8:	11000593          	li	a1,272
ffffffffc02013ec:	00003517          	auipc	a0,0x3
ffffffffc02013f0:	5ac50513          	addi	a0,a0,1452 # ffffffffc0204998 <commands+0x850>
ffffffffc02013f4:	866ff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc02013f8:	00004697          	auipc	a3,0x4
ffffffffc02013fc:	83868693          	addi	a3,a3,-1992 # ffffffffc0204c30 <commands+0xae8>
ffffffffc0201400:	00003617          	auipc	a2,0x3
ffffffffc0201404:	58060613          	addi	a2,a2,1408 # ffffffffc0204980 <commands+0x838>
ffffffffc0201408:	10e00593          	li	a1,270
ffffffffc020140c:	00003517          	auipc	a0,0x3
ffffffffc0201410:	58c50513          	addi	a0,a0,1420 # ffffffffc0204998 <commands+0x850>
ffffffffc0201414:	846ff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0201418:	00003697          	auipc	a3,0x3
ffffffffc020141c:	7f068693          	addi	a3,a3,2032 # ffffffffc0204c08 <commands+0xac0>
ffffffffc0201420:	00003617          	auipc	a2,0x3
ffffffffc0201424:	56060613          	addi	a2,a2,1376 # ffffffffc0204980 <commands+0x838>
ffffffffc0201428:	10d00593          	li	a1,269
ffffffffc020142c:	00003517          	auipc	a0,0x3
ffffffffc0201430:	56c50513          	addi	a0,a0,1388 # ffffffffc0204998 <commands+0x850>
ffffffffc0201434:	826ff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(p0 + 2 == p1);
ffffffffc0201438:	00003697          	auipc	a3,0x3
ffffffffc020143c:	7c068693          	addi	a3,a3,1984 # ffffffffc0204bf8 <commands+0xab0>
ffffffffc0201440:	00003617          	auipc	a2,0x3
ffffffffc0201444:	54060613          	addi	a2,a2,1344 # ffffffffc0204980 <commands+0x838>
ffffffffc0201448:	10800593          	li	a1,264
ffffffffc020144c:	00003517          	auipc	a0,0x3
ffffffffc0201450:	54c50513          	addi	a0,a0,1356 # ffffffffc0204998 <commands+0x850>
ffffffffc0201454:	806ff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201458:	00003697          	auipc	a3,0x3
ffffffffc020145c:	6a068693          	addi	a3,a3,1696 # ffffffffc0204af8 <commands+0x9b0>
ffffffffc0201460:	00003617          	auipc	a2,0x3
ffffffffc0201464:	52060613          	addi	a2,a2,1312 # ffffffffc0204980 <commands+0x838>
ffffffffc0201468:	10700593          	li	a1,263
ffffffffc020146c:	00003517          	auipc	a0,0x3
ffffffffc0201470:	52c50513          	addi	a0,a0,1324 # ffffffffc0204998 <commands+0x850>
ffffffffc0201474:	fe7fe0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0201478:	00003697          	auipc	a3,0x3
ffffffffc020147c:	76068693          	addi	a3,a3,1888 # ffffffffc0204bd8 <commands+0xa90>
ffffffffc0201480:	00003617          	auipc	a2,0x3
ffffffffc0201484:	50060613          	addi	a2,a2,1280 # ffffffffc0204980 <commands+0x838>
ffffffffc0201488:	10600593          	li	a1,262
ffffffffc020148c:	00003517          	auipc	a0,0x3
ffffffffc0201490:	50c50513          	addi	a0,a0,1292 # ffffffffc0204998 <commands+0x850>
ffffffffc0201494:	fc7fe0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0201498:	00003697          	auipc	a3,0x3
ffffffffc020149c:	71068693          	addi	a3,a3,1808 # ffffffffc0204ba8 <commands+0xa60>
ffffffffc02014a0:	00003617          	auipc	a2,0x3
ffffffffc02014a4:	4e060613          	addi	a2,a2,1248 # ffffffffc0204980 <commands+0x838>
ffffffffc02014a8:	10500593          	li	a1,261
ffffffffc02014ac:	00003517          	auipc	a0,0x3
ffffffffc02014b0:	4ec50513          	addi	a0,a0,1260 # ffffffffc0204998 <commands+0x850>
ffffffffc02014b4:	fa7fe0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc02014b8:	00003697          	auipc	a3,0x3
ffffffffc02014bc:	6d868693          	addi	a3,a3,1752 # ffffffffc0204b90 <commands+0xa48>
ffffffffc02014c0:	00003617          	auipc	a2,0x3
ffffffffc02014c4:	4c060613          	addi	a2,a2,1216 # ffffffffc0204980 <commands+0x838>
ffffffffc02014c8:	10400593          	li	a1,260
ffffffffc02014cc:	00003517          	auipc	a0,0x3
ffffffffc02014d0:	4cc50513          	addi	a0,a0,1228 # ffffffffc0204998 <commands+0x850>
ffffffffc02014d4:	f87fe0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(alloc_page() == NULL);
ffffffffc02014d8:	00003697          	auipc	a3,0x3
ffffffffc02014dc:	62068693          	addi	a3,a3,1568 # ffffffffc0204af8 <commands+0x9b0>
ffffffffc02014e0:	00003617          	auipc	a2,0x3
ffffffffc02014e4:	4a060613          	addi	a2,a2,1184 # ffffffffc0204980 <commands+0x838>
ffffffffc02014e8:	0fe00593          	li	a1,254
ffffffffc02014ec:	00003517          	auipc	a0,0x3
ffffffffc02014f0:	4ac50513          	addi	a0,a0,1196 # ffffffffc0204998 <commands+0x850>
ffffffffc02014f4:	f67fe0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(!PageProperty(p0));
ffffffffc02014f8:	00003697          	auipc	a3,0x3
ffffffffc02014fc:	68068693          	addi	a3,a3,1664 # ffffffffc0204b78 <commands+0xa30>
ffffffffc0201500:	00003617          	auipc	a2,0x3
ffffffffc0201504:	48060613          	addi	a2,a2,1152 # ffffffffc0204980 <commands+0x838>
ffffffffc0201508:	0f900593          	li	a1,249
ffffffffc020150c:	00003517          	auipc	a0,0x3
ffffffffc0201510:	48c50513          	addi	a0,a0,1164 # ffffffffc0204998 <commands+0x850>
ffffffffc0201514:	f47fe0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0201518:	00003697          	auipc	a3,0x3
ffffffffc020151c:	78068693          	addi	a3,a3,1920 # ffffffffc0204c98 <commands+0xb50>
ffffffffc0201520:	00003617          	auipc	a2,0x3
ffffffffc0201524:	46060613          	addi	a2,a2,1120 # ffffffffc0204980 <commands+0x838>
ffffffffc0201528:	11700593          	li	a1,279
ffffffffc020152c:	00003517          	auipc	a0,0x3
ffffffffc0201530:	46c50513          	addi	a0,a0,1132 # ffffffffc0204998 <commands+0x850>
ffffffffc0201534:	f27fe0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(total == 0);
ffffffffc0201538:	00003697          	auipc	a3,0x3
ffffffffc020153c:	79068693          	addi	a3,a3,1936 # ffffffffc0204cc8 <commands+0xb80>
ffffffffc0201540:	00003617          	auipc	a2,0x3
ffffffffc0201544:	44060613          	addi	a2,a2,1088 # ffffffffc0204980 <commands+0x838>
ffffffffc0201548:	12600593          	li	a1,294
ffffffffc020154c:	00003517          	auipc	a0,0x3
ffffffffc0201550:	44c50513          	addi	a0,a0,1100 # ffffffffc0204998 <commands+0x850>
ffffffffc0201554:	f07fe0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(total == nr_free_pages());
ffffffffc0201558:	00003697          	auipc	a3,0x3
ffffffffc020155c:	45868693          	addi	a3,a3,1112 # ffffffffc02049b0 <commands+0x868>
ffffffffc0201560:	00003617          	auipc	a2,0x3
ffffffffc0201564:	42060613          	addi	a2,a2,1056 # ffffffffc0204980 <commands+0x838>
ffffffffc0201568:	0f300593          	li	a1,243
ffffffffc020156c:	00003517          	auipc	a0,0x3
ffffffffc0201570:	42c50513          	addi	a0,a0,1068 # ffffffffc0204998 <commands+0x850>
ffffffffc0201574:	ee7fe0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201578:	00003697          	auipc	a3,0x3
ffffffffc020157c:	47868693          	addi	a3,a3,1144 # ffffffffc02049f0 <commands+0x8a8>
ffffffffc0201580:	00003617          	auipc	a2,0x3
ffffffffc0201584:	40060613          	addi	a2,a2,1024 # ffffffffc0204980 <commands+0x838>
ffffffffc0201588:	0ba00593          	li	a1,186
ffffffffc020158c:	00003517          	auipc	a0,0x3
ffffffffc0201590:	40c50513          	addi	a0,a0,1036 # ffffffffc0204998 <commands+0x850>
ffffffffc0201594:	ec7fe0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0201598 <default_free_pages>:
default_free_pages(struct Page *base, size_t n) {
ffffffffc0201598:	1141                	addi	sp,sp,-16
ffffffffc020159a:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020159c:	14058463          	beqz	a1,ffffffffc02016e4 <default_free_pages+0x14c>
    for (; p != base + n; p ++) {
ffffffffc02015a0:	00659693          	slli	a3,a1,0x6
ffffffffc02015a4:	96aa                	add	a3,a3,a0
ffffffffc02015a6:	87aa                	mv	a5,a0
ffffffffc02015a8:	02d50263          	beq	a0,a3,ffffffffc02015cc <default_free_pages+0x34>
ffffffffc02015ac:	6798                	ld	a4,8(a5)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02015ae:	8b05                	andi	a4,a4,1
ffffffffc02015b0:	10071a63          	bnez	a4,ffffffffc02016c4 <default_free_pages+0x12c>
ffffffffc02015b4:	6798                	ld	a4,8(a5)
ffffffffc02015b6:	8b09                	andi	a4,a4,2
ffffffffc02015b8:	10071663          	bnez	a4,ffffffffc02016c4 <default_free_pages+0x12c>
        p->flags = 0;
ffffffffc02015bc:	0007b423          	sd	zero,8(a5)
}

static inline void
set_page_ref(struct Page *page, int val)
{
    page->ref = val;
ffffffffc02015c0:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc02015c4:	04078793          	addi	a5,a5,64
ffffffffc02015c8:	fed792e3          	bne	a5,a3,ffffffffc02015ac <default_free_pages+0x14>
    base->property = n;
ffffffffc02015cc:	2581                	sext.w	a1,a1
ffffffffc02015ce:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc02015d0:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02015d4:	4789                	li	a5,2
ffffffffc02015d6:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc02015da:	00008697          	auipc	a3,0x8
ffffffffc02015de:	e5668693          	addi	a3,a3,-426 # ffffffffc0209430 <free_area>
ffffffffc02015e2:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc02015e4:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc02015e6:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc02015ea:	9db9                	addw	a1,a1,a4
ffffffffc02015ec:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc02015ee:	0ad78463          	beq	a5,a3,ffffffffc0201696 <default_free_pages+0xfe>
            struct Page* page = le2page(le, page_link);
ffffffffc02015f2:	fe878713          	addi	a4,a5,-24
ffffffffc02015f6:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc02015fa:	4581                	li	a1,0
            if (base < page) {
ffffffffc02015fc:	00e56a63          	bltu	a0,a4,ffffffffc0201610 <default_free_pages+0x78>
    return listelm->next;
ffffffffc0201600:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0201602:	04d70c63          	beq	a4,a3,ffffffffc020165a <default_free_pages+0xc2>
    for (; p != base + n; p ++) {
ffffffffc0201606:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0201608:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc020160c:	fee57ae3          	bgeu	a0,a4,ffffffffc0201600 <default_free_pages+0x68>
ffffffffc0201610:	c199                	beqz	a1,ffffffffc0201616 <default_free_pages+0x7e>
ffffffffc0201612:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201616:	6398                	ld	a4,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc0201618:	e390                	sd	a2,0(a5)
ffffffffc020161a:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc020161c:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020161e:	ed18                	sd	a4,24(a0)
    if (le != &free_list) {
ffffffffc0201620:	00d70d63          	beq	a4,a3,ffffffffc020163a <default_free_pages+0xa2>
        if (p + p->property == base) {
ffffffffc0201624:	ff872583          	lw	a1,-8(a4)
        p = le2page(le, page_link);
ffffffffc0201628:	fe870613          	addi	a2,a4,-24
        if (p + p->property == base) {
ffffffffc020162c:	02059813          	slli	a6,a1,0x20
ffffffffc0201630:	01a85793          	srli	a5,a6,0x1a
ffffffffc0201634:	97b2                	add	a5,a5,a2
ffffffffc0201636:	02f50c63          	beq	a0,a5,ffffffffc020166e <default_free_pages+0xd6>
    return listelm->next;
ffffffffc020163a:	711c                	ld	a5,32(a0)
    if (le != &free_list) {
ffffffffc020163c:	00d78c63          	beq	a5,a3,ffffffffc0201654 <default_free_pages+0xbc>
        if (base + base->property == p) {
ffffffffc0201640:	4910                	lw	a2,16(a0)
        p = le2page(le, page_link);
ffffffffc0201642:	fe878693          	addi	a3,a5,-24
        if (base + base->property == p) {
ffffffffc0201646:	02061593          	slli	a1,a2,0x20
ffffffffc020164a:	01a5d713          	srli	a4,a1,0x1a
ffffffffc020164e:	972a                	add	a4,a4,a0
ffffffffc0201650:	04e68a63          	beq	a3,a4,ffffffffc02016a4 <default_free_pages+0x10c>
}
ffffffffc0201654:	60a2                	ld	ra,8(sp)
ffffffffc0201656:	0141                	addi	sp,sp,16
ffffffffc0201658:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc020165a:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc020165c:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc020165e:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201660:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc0201662:	02d70763          	beq	a4,a3,ffffffffc0201690 <default_free_pages+0xf8>
    prev->next = next->prev = elm;
ffffffffc0201666:	8832                	mv	a6,a2
ffffffffc0201668:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc020166a:	87ba                	mv	a5,a4
ffffffffc020166c:	bf71                	j	ffffffffc0201608 <default_free_pages+0x70>
            p->property += base->property;
ffffffffc020166e:	491c                	lw	a5,16(a0)
ffffffffc0201670:	9dbd                	addw	a1,a1,a5
ffffffffc0201672:	feb72c23          	sw	a1,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201676:	57f5                	li	a5,-3
ffffffffc0201678:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc020167c:	01853803          	ld	a6,24(a0)
ffffffffc0201680:	710c                	ld	a1,32(a0)
            base = p;
ffffffffc0201682:	8532                	mv	a0,a2
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0201684:	00b83423          	sd	a1,8(a6)
    return listelm->next;
ffffffffc0201688:	671c                	ld	a5,8(a4)
    next->prev = prev;
ffffffffc020168a:	0105b023          	sd	a6,0(a1)
ffffffffc020168e:	b77d                	j	ffffffffc020163c <default_free_pages+0xa4>
ffffffffc0201690:	e290                	sd	a2,0(a3)
        while ((le = list_next(le)) != &free_list) {
ffffffffc0201692:	873e                	mv	a4,a5
ffffffffc0201694:	bf41                	j	ffffffffc0201624 <default_free_pages+0x8c>
}
ffffffffc0201696:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0201698:	e390                	sd	a2,0(a5)
ffffffffc020169a:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc020169c:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020169e:	ed1c                	sd	a5,24(a0)
ffffffffc02016a0:	0141                	addi	sp,sp,16
ffffffffc02016a2:	8082                	ret
            base->property += p->property;
ffffffffc02016a4:	ff87a703          	lw	a4,-8(a5)
ffffffffc02016a8:	ff078693          	addi	a3,a5,-16
ffffffffc02016ac:	9e39                	addw	a2,a2,a4
ffffffffc02016ae:	c910                	sw	a2,16(a0)
ffffffffc02016b0:	5775                	li	a4,-3
ffffffffc02016b2:	60e6b02f          	amoand.d	zero,a4,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc02016b6:	6398                	ld	a4,0(a5)
ffffffffc02016b8:	679c                	ld	a5,8(a5)
}
ffffffffc02016ba:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc02016bc:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc02016be:	e398                	sd	a4,0(a5)
ffffffffc02016c0:	0141                	addi	sp,sp,16
ffffffffc02016c2:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02016c4:	00003697          	auipc	a3,0x3
ffffffffc02016c8:	61c68693          	addi	a3,a3,1564 # ffffffffc0204ce0 <commands+0xb98>
ffffffffc02016cc:	00003617          	auipc	a2,0x3
ffffffffc02016d0:	2b460613          	addi	a2,a2,692 # ffffffffc0204980 <commands+0x838>
ffffffffc02016d4:	08300593          	li	a1,131
ffffffffc02016d8:	00003517          	auipc	a0,0x3
ffffffffc02016dc:	2c050513          	addi	a0,a0,704 # ffffffffc0204998 <commands+0x850>
ffffffffc02016e0:	d7bfe0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(n > 0);
ffffffffc02016e4:	00003697          	auipc	a3,0x3
ffffffffc02016e8:	5f468693          	addi	a3,a3,1524 # ffffffffc0204cd8 <commands+0xb90>
ffffffffc02016ec:	00003617          	auipc	a2,0x3
ffffffffc02016f0:	29460613          	addi	a2,a2,660 # ffffffffc0204980 <commands+0x838>
ffffffffc02016f4:	08000593          	li	a1,128
ffffffffc02016f8:	00003517          	auipc	a0,0x3
ffffffffc02016fc:	2a050513          	addi	a0,a0,672 # ffffffffc0204998 <commands+0x850>
ffffffffc0201700:	d5bfe0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0201704 <default_alloc_pages>:
    assert(n > 0);
ffffffffc0201704:	c941                	beqz	a0,ffffffffc0201794 <default_alloc_pages+0x90>
    if (n > nr_free) {
ffffffffc0201706:	00008597          	auipc	a1,0x8
ffffffffc020170a:	d2a58593          	addi	a1,a1,-726 # ffffffffc0209430 <free_area>
ffffffffc020170e:	0105a803          	lw	a6,16(a1)
ffffffffc0201712:	872a                	mv	a4,a0
ffffffffc0201714:	02081793          	slli	a5,a6,0x20
ffffffffc0201718:	9381                	srli	a5,a5,0x20
ffffffffc020171a:	00a7ee63          	bltu	a5,a0,ffffffffc0201736 <default_alloc_pages+0x32>
    list_entry_t *le = &free_list;
ffffffffc020171e:	87ae                	mv	a5,a1
ffffffffc0201720:	a801                	j	ffffffffc0201730 <default_alloc_pages+0x2c>
        if (p->property >= n) {
ffffffffc0201722:	ff87a683          	lw	a3,-8(a5)
ffffffffc0201726:	02069613          	slli	a2,a3,0x20
ffffffffc020172a:	9201                	srli	a2,a2,0x20
ffffffffc020172c:	00e67763          	bgeu	a2,a4,ffffffffc020173a <default_alloc_pages+0x36>
    return listelm->next;
ffffffffc0201730:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc0201732:	feb798e3          	bne	a5,a1,ffffffffc0201722 <default_alloc_pages+0x1e>
        return NULL;
ffffffffc0201736:	4501                	li	a0,0
}
ffffffffc0201738:	8082                	ret
    return listelm->prev;
ffffffffc020173a:	0007b883          	ld	a7,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc020173e:	0087b303          	ld	t1,8(a5)
        struct Page *p = le2page(le, page_link);
ffffffffc0201742:	fe878513          	addi	a0,a5,-24
            p->property = page->property - n;
ffffffffc0201746:	00070e1b          	sext.w	t3,a4
    prev->next = next;
ffffffffc020174a:	0068b423          	sd	t1,8(a7)
    next->prev = prev;
ffffffffc020174e:	01133023          	sd	a7,0(t1)
        if (page->property > n) {
ffffffffc0201752:	02c77863          	bgeu	a4,a2,ffffffffc0201782 <default_alloc_pages+0x7e>
            struct Page *p = page + n;
ffffffffc0201756:	071a                	slli	a4,a4,0x6
ffffffffc0201758:	972a                	add	a4,a4,a0
            p->property = page->property - n;
ffffffffc020175a:	41c686bb          	subw	a3,a3,t3
ffffffffc020175e:	cb14                	sw	a3,16(a4)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201760:	00870613          	addi	a2,a4,8
ffffffffc0201764:	4689                	li	a3,2
ffffffffc0201766:	40d6302f          	amoor.d	zero,a3,(a2)
    __list_add(elm, listelm, listelm->next);
ffffffffc020176a:	0088b683          	ld	a3,8(a7)
            list_add(prev, &(p->page_link));
ffffffffc020176e:	01870613          	addi	a2,a4,24
        nr_free -= n;
ffffffffc0201772:	0105a803          	lw	a6,16(a1)
    prev->next = next->prev = elm;
ffffffffc0201776:	e290                	sd	a2,0(a3)
ffffffffc0201778:	00c8b423          	sd	a2,8(a7)
    elm->next = next;
ffffffffc020177c:	f314                	sd	a3,32(a4)
    elm->prev = prev;
ffffffffc020177e:	01173c23          	sd	a7,24(a4)
ffffffffc0201782:	41c8083b          	subw	a6,a6,t3
ffffffffc0201786:	0105a823          	sw	a6,16(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc020178a:	5775                	li	a4,-3
ffffffffc020178c:	17c1                	addi	a5,a5,-16
ffffffffc020178e:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc0201792:	8082                	ret
default_alloc_pages(size_t n) {
ffffffffc0201794:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0201796:	00003697          	auipc	a3,0x3
ffffffffc020179a:	54268693          	addi	a3,a3,1346 # ffffffffc0204cd8 <commands+0xb90>
ffffffffc020179e:	00003617          	auipc	a2,0x3
ffffffffc02017a2:	1e260613          	addi	a2,a2,482 # ffffffffc0204980 <commands+0x838>
ffffffffc02017a6:	06200593          	li	a1,98
ffffffffc02017aa:	00003517          	auipc	a0,0x3
ffffffffc02017ae:	1ee50513          	addi	a0,a0,494 # ffffffffc0204998 <commands+0x850>
default_alloc_pages(size_t n) {
ffffffffc02017b2:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02017b4:	ca7fe0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc02017b8 <default_init_memmap>:
default_init_memmap(struct Page *base, size_t n) {
ffffffffc02017b8:	1141                	addi	sp,sp,-16
ffffffffc02017ba:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02017bc:	c5f1                	beqz	a1,ffffffffc0201888 <default_init_memmap+0xd0>
    for (; p != base + n; p ++) {
ffffffffc02017be:	00659693          	slli	a3,a1,0x6
ffffffffc02017c2:	96aa                	add	a3,a3,a0
ffffffffc02017c4:	87aa                	mv	a5,a0
ffffffffc02017c6:	00d50f63          	beq	a0,a3,ffffffffc02017e4 <default_init_memmap+0x2c>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc02017ca:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));
ffffffffc02017cc:	8b05                	andi	a4,a4,1
ffffffffc02017ce:	cf49                	beqz	a4,ffffffffc0201868 <default_init_memmap+0xb0>
        p->flags = p->property = 0;
ffffffffc02017d0:	0007a823          	sw	zero,16(a5)
ffffffffc02017d4:	0007b423          	sd	zero,8(a5)
ffffffffc02017d8:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc02017dc:	04078793          	addi	a5,a5,64
ffffffffc02017e0:	fed795e3          	bne	a5,a3,ffffffffc02017ca <default_init_memmap+0x12>
    base->property = n;
ffffffffc02017e4:	2581                	sext.w	a1,a1
ffffffffc02017e6:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02017e8:	4789                	li	a5,2
ffffffffc02017ea:	00850713          	addi	a4,a0,8
ffffffffc02017ee:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc02017f2:	00008697          	auipc	a3,0x8
ffffffffc02017f6:	c3e68693          	addi	a3,a3,-962 # ffffffffc0209430 <free_area>
ffffffffc02017fa:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc02017fc:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc02017fe:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc0201802:	9db9                	addw	a1,a1,a4
ffffffffc0201804:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc0201806:	04d78a63          	beq	a5,a3,ffffffffc020185a <default_init_memmap+0xa2>
            struct Page* page = le2page(le, page_link);
ffffffffc020180a:	fe878713          	addi	a4,a5,-24
ffffffffc020180e:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc0201812:	4581                	li	a1,0
            if (base < page) {
ffffffffc0201814:	00e56a63          	bltu	a0,a4,ffffffffc0201828 <default_init_memmap+0x70>
    return listelm->next;
ffffffffc0201818:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc020181a:	02d70263          	beq	a4,a3,ffffffffc020183e <default_init_memmap+0x86>
    for (; p != base + n; p ++) {
ffffffffc020181e:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0201820:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0201824:	fee57ae3          	bgeu	a0,a4,ffffffffc0201818 <default_init_memmap+0x60>
ffffffffc0201828:	c199                	beqz	a1,ffffffffc020182e <default_init_memmap+0x76>
ffffffffc020182a:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc020182e:	6398                	ld	a4,0(a5)
}
ffffffffc0201830:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0201832:	e390                	sd	a2,0(a5)
ffffffffc0201834:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0201836:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201838:	ed18                	sd	a4,24(a0)
ffffffffc020183a:	0141                	addi	sp,sp,16
ffffffffc020183c:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc020183e:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201840:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201842:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201844:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc0201846:	00d70663          	beq	a4,a3,ffffffffc0201852 <default_init_memmap+0x9a>
    prev->next = next->prev = elm;
ffffffffc020184a:	8832                	mv	a6,a2
ffffffffc020184c:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc020184e:	87ba                	mv	a5,a4
ffffffffc0201850:	bfc1                	j	ffffffffc0201820 <default_init_memmap+0x68>
}
ffffffffc0201852:	60a2                	ld	ra,8(sp)
ffffffffc0201854:	e290                	sd	a2,0(a3)
ffffffffc0201856:	0141                	addi	sp,sp,16
ffffffffc0201858:	8082                	ret
ffffffffc020185a:	60a2                	ld	ra,8(sp)
ffffffffc020185c:	e390                	sd	a2,0(a5)
ffffffffc020185e:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201860:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201862:	ed1c                	sd	a5,24(a0)
ffffffffc0201864:	0141                	addi	sp,sp,16
ffffffffc0201866:	8082                	ret
        assert(PageReserved(p));
ffffffffc0201868:	00003697          	auipc	a3,0x3
ffffffffc020186c:	4a068693          	addi	a3,a3,1184 # ffffffffc0204d08 <commands+0xbc0>
ffffffffc0201870:	00003617          	auipc	a2,0x3
ffffffffc0201874:	11060613          	addi	a2,a2,272 # ffffffffc0204980 <commands+0x838>
ffffffffc0201878:	04900593          	li	a1,73
ffffffffc020187c:	00003517          	auipc	a0,0x3
ffffffffc0201880:	11c50513          	addi	a0,a0,284 # ffffffffc0204998 <commands+0x850>
ffffffffc0201884:	bd7fe0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(n > 0);
ffffffffc0201888:	00003697          	auipc	a3,0x3
ffffffffc020188c:	45068693          	addi	a3,a3,1104 # ffffffffc0204cd8 <commands+0xb90>
ffffffffc0201890:	00003617          	auipc	a2,0x3
ffffffffc0201894:	0f060613          	addi	a2,a2,240 # ffffffffc0204980 <commands+0x838>
ffffffffc0201898:	04600593          	li	a1,70
ffffffffc020189c:	00003517          	auipc	a0,0x3
ffffffffc02018a0:	0fc50513          	addi	a0,a0,252 # ffffffffc0204998 <commands+0x850>
ffffffffc02018a4:	bb7fe0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc02018a8 <slob_free>:
static void slob_free(void *block, int size)
{
	slob_t *cur, *b = (slob_t *)block;
	unsigned long flags;

	if (!block)
ffffffffc02018a8:	c94d                	beqz	a0,ffffffffc020195a <slob_free+0xb2>
{
ffffffffc02018aa:	1141                	addi	sp,sp,-16
ffffffffc02018ac:	e022                	sd	s0,0(sp)
ffffffffc02018ae:	e406                	sd	ra,8(sp)
ffffffffc02018b0:	842a                	mv	s0,a0
		return;

	if (size)
ffffffffc02018b2:	e9c1                	bnez	a1,ffffffffc0201942 <slob_free+0x9a>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02018b4:	100027f3          	csrr	a5,sstatus
ffffffffc02018b8:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02018ba:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02018bc:	ebd9                	bnez	a5,ffffffffc0201952 <slob_free+0xaa>
		b->units = SLOB_UNITS(size);

	/* Find reinsertion point */
	spin_lock_irqsave(&slob_lock, flags);
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc02018be:	00007617          	auipc	a2,0x7
ffffffffc02018c2:	76260613          	addi	a2,a2,1890 # ffffffffc0209020 <slobfree>
ffffffffc02018c6:	621c                	ld	a5,0(a2)
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc02018c8:	873e                	mv	a4,a5
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc02018ca:	679c                	ld	a5,8(a5)
ffffffffc02018cc:	02877a63          	bgeu	a4,s0,ffffffffc0201900 <slob_free+0x58>
ffffffffc02018d0:	00f46463          	bltu	s0,a5,ffffffffc02018d8 <slob_free+0x30>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc02018d4:	fef76ae3          	bltu	a4,a5,ffffffffc02018c8 <slob_free+0x20>
			break;

	if (b + b->units == cur->next)
ffffffffc02018d8:	400c                	lw	a1,0(s0)
ffffffffc02018da:	00459693          	slli	a3,a1,0x4
ffffffffc02018de:	96a2                	add	a3,a3,s0
ffffffffc02018e0:	02d78a63          	beq	a5,a3,ffffffffc0201914 <slob_free+0x6c>
		b->next = cur->next->next;
	}
	else
		b->next = cur->next;

	if (cur + cur->units == b)
ffffffffc02018e4:	4314                	lw	a3,0(a4)
		b->next = cur->next;
ffffffffc02018e6:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b)
ffffffffc02018e8:	00469793          	slli	a5,a3,0x4
ffffffffc02018ec:	97ba                	add	a5,a5,a4
ffffffffc02018ee:	02f40e63          	beq	s0,a5,ffffffffc020192a <slob_free+0x82>
	{
		cur->units += b->units;
		cur->next = b->next;
	}
	else
		cur->next = b;
ffffffffc02018f2:	e700                	sd	s0,8(a4)

	slobfree = cur;
ffffffffc02018f4:	e218                	sd	a4,0(a2)
    if (flag) {
ffffffffc02018f6:	e129                	bnez	a0,ffffffffc0201938 <slob_free+0x90>

	spin_unlock_irqrestore(&slob_lock, flags);
}
ffffffffc02018f8:	60a2                	ld	ra,8(sp)
ffffffffc02018fa:	6402                	ld	s0,0(sp)
ffffffffc02018fc:	0141                	addi	sp,sp,16
ffffffffc02018fe:	8082                	ret
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201900:	fcf764e3          	bltu	a4,a5,ffffffffc02018c8 <slob_free+0x20>
ffffffffc0201904:	fcf472e3          	bgeu	s0,a5,ffffffffc02018c8 <slob_free+0x20>
	if (b + b->units == cur->next)
ffffffffc0201908:	400c                	lw	a1,0(s0)
ffffffffc020190a:	00459693          	slli	a3,a1,0x4
ffffffffc020190e:	96a2                	add	a3,a3,s0
ffffffffc0201910:	fcd79ae3          	bne	a5,a3,ffffffffc02018e4 <slob_free+0x3c>
		b->units += cur->next->units;
ffffffffc0201914:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc0201916:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc0201918:	9db5                	addw	a1,a1,a3
ffffffffc020191a:	c00c                	sw	a1,0(s0)
	if (cur + cur->units == b)
ffffffffc020191c:	4314                	lw	a3,0(a4)
		b->next = cur->next->next;
ffffffffc020191e:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b)
ffffffffc0201920:	00469793          	slli	a5,a3,0x4
ffffffffc0201924:	97ba                	add	a5,a5,a4
ffffffffc0201926:	fcf416e3          	bne	s0,a5,ffffffffc02018f2 <slob_free+0x4a>
		cur->units += b->units;
ffffffffc020192a:	401c                	lw	a5,0(s0)
		cur->next = b->next;
ffffffffc020192c:	640c                	ld	a1,8(s0)
	slobfree = cur;
ffffffffc020192e:	e218                	sd	a4,0(a2)
		cur->units += b->units;
ffffffffc0201930:	9ebd                	addw	a3,a3,a5
ffffffffc0201932:	c314                	sw	a3,0(a4)
		cur->next = b->next;
ffffffffc0201934:	e70c                	sd	a1,8(a4)
ffffffffc0201936:	d169                	beqz	a0,ffffffffc02018f8 <slob_free+0x50>
}
ffffffffc0201938:	6402                	ld	s0,0(sp)
ffffffffc020193a:	60a2                	ld	ra,8(sp)
ffffffffc020193c:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc020193e:	fedfe06f          	j	ffffffffc020092a <intr_enable>
		b->units = SLOB_UNITS(size);
ffffffffc0201942:	25bd                	addiw	a1,a1,15
ffffffffc0201944:	8191                	srli	a1,a1,0x4
ffffffffc0201946:	c10c                	sw	a1,0(a0)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201948:	100027f3          	csrr	a5,sstatus
ffffffffc020194c:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc020194e:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201950:	d7bd                	beqz	a5,ffffffffc02018be <slob_free+0x16>
        intr_disable();
ffffffffc0201952:	fdffe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        return 1;
ffffffffc0201956:	4505                	li	a0,1
ffffffffc0201958:	b79d                	j	ffffffffc02018be <slob_free+0x16>
ffffffffc020195a:	8082                	ret

ffffffffc020195c <__slob_get_free_pages.constprop.0>:
	struct Page *page = alloc_pages(1 << order);
ffffffffc020195c:	4785                	li	a5,1
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc020195e:	1141                	addi	sp,sp,-16
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201960:	00a7953b          	sllw	a0,a5,a0
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201964:	e406                	sd	ra,8(sp)
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201966:	34e000ef          	jal	ra,ffffffffc0201cb4 <alloc_pages>
	if (!page)
ffffffffc020196a:	c91d                	beqz	a0,ffffffffc02019a0 <__slob_get_free_pages.constprop.0+0x44>
    return page - pages + nbase;
ffffffffc020196c:	0000c697          	auipc	a3,0xc
ffffffffc0201970:	b4c6b683          	ld	a3,-1204(a3) # ffffffffc020d4b8 <pages>
ffffffffc0201974:	8d15                	sub	a0,a0,a3
ffffffffc0201976:	8519                	srai	a0,a0,0x6
ffffffffc0201978:	00004697          	auipc	a3,0x4
ffffffffc020197c:	0d06b683          	ld	a3,208(a3) # ffffffffc0205a48 <nbase>
ffffffffc0201980:	9536                	add	a0,a0,a3
    return KADDR(page2pa(page));
ffffffffc0201982:	00c51793          	slli	a5,a0,0xc
ffffffffc0201986:	83b1                	srli	a5,a5,0xc
ffffffffc0201988:	0000c717          	auipc	a4,0xc
ffffffffc020198c:	b2873703          	ld	a4,-1240(a4) # ffffffffc020d4b0 <npage>
    return page2ppn(page) << PGSHIFT;
ffffffffc0201990:	0532                	slli	a0,a0,0xc
    return KADDR(page2pa(page));
ffffffffc0201992:	00e7fa63          	bgeu	a5,a4,ffffffffc02019a6 <__slob_get_free_pages.constprop.0+0x4a>
ffffffffc0201996:	0000c697          	auipc	a3,0xc
ffffffffc020199a:	b326b683          	ld	a3,-1230(a3) # ffffffffc020d4c8 <va_pa_offset>
ffffffffc020199e:	9536                	add	a0,a0,a3
}
ffffffffc02019a0:	60a2                	ld	ra,8(sp)
ffffffffc02019a2:	0141                	addi	sp,sp,16
ffffffffc02019a4:	8082                	ret
ffffffffc02019a6:	86aa                	mv	a3,a0
ffffffffc02019a8:	00003617          	auipc	a2,0x3
ffffffffc02019ac:	3c060613          	addi	a2,a2,960 # ffffffffc0204d68 <default_pmm_manager+0x38>
ffffffffc02019b0:	07100593          	li	a1,113
ffffffffc02019b4:	00003517          	auipc	a0,0x3
ffffffffc02019b8:	3dc50513          	addi	a0,a0,988 # ffffffffc0204d90 <default_pmm_manager+0x60>
ffffffffc02019bc:	a9ffe0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc02019c0 <slob_alloc.constprop.0>:
static void *slob_alloc(size_t size, gfp_t gfp, int align)
ffffffffc02019c0:	1101                	addi	sp,sp,-32
ffffffffc02019c2:	ec06                	sd	ra,24(sp)
ffffffffc02019c4:	e822                	sd	s0,16(sp)
ffffffffc02019c6:	e426                	sd	s1,8(sp)
ffffffffc02019c8:	e04a                	sd	s2,0(sp)
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc02019ca:	01050713          	addi	a4,a0,16
ffffffffc02019ce:	6785                	lui	a5,0x1
ffffffffc02019d0:	0cf77363          	bgeu	a4,a5,ffffffffc0201a96 <slob_alloc.constprop.0+0xd6>
	int delta = 0, units = SLOB_UNITS(size);
ffffffffc02019d4:	00f50493          	addi	s1,a0,15
ffffffffc02019d8:	8091                	srli	s1,s1,0x4
ffffffffc02019da:	2481                	sext.w	s1,s1
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02019dc:	10002673          	csrr	a2,sstatus
ffffffffc02019e0:	8a09                	andi	a2,a2,2
ffffffffc02019e2:	e25d                	bnez	a2,ffffffffc0201a88 <slob_alloc.constprop.0+0xc8>
	prev = slobfree;
ffffffffc02019e4:	00007917          	auipc	s2,0x7
ffffffffc02019e8:	63c90913          	addi	s2,s2,1596 # ffffffffc0209020 <slobfree>
ffffffffc02019ec:	00093683          	ld	a3,0(s2)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc02019f0:	669c                	ld	a5,8(a3)
		if (cur->units >= units + delta)
ffffffffc02019f2:	4398                	lw	a4,0(a5)
ffffffffc02019f4:	08975e63          	bge	a4,s1,ffffffffc0201a90 <slob_alloc.constprop.0+0xd0>
		if (cur == slobfree)
ffffffffc02019f8:	00d78b63          	beq	a5,a3,ffffffffc0201a0e <slob_alloc.constprop.0+0x4e>
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc02019fc:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta)
ffffffffc02019fe:	4018                	lw	a4,0(s0)
ffffffffc0201a00:	02975a63          	bge	a4,s1,ffffffffc0201a34 <slob_alloc.constprop.0+0x74>
		if (cur == slobfree)
ffffffffc0201a04:	00093683          	ld	a3,0(s2)
ffffffffc0201a08:	87a2                	mv	a5,s0
ffffffffc0201a0a:	fed799e3          	bne	a5,a3,ffffffffc02019fc <slob_alloc.constprop.0+0x3c>
    if (flag) {
ffffffffc0201a0e:	ee31                	bnez	a2,ffffffffc0201a6a <slob_alloc.constprop.0+0xaa>
			cur = (slob_t *)__slob_get_free_page(gfp);
ffffffffc0201a10:	4501                	li	a0,0
ffffffffc0201a12:	f4bff0ef          	jal	ra,ffffffffc020195c <__slob_get_free_pages.constprop.0>
ffffffffc0201a16:	842a                	mv	s0,a0
			if (!cur)
ffffffffc0201a18:	cd05                	beqz	a0,ffffffffc0201a50 <slob_alloc.constprop.0+0x90>
			slob_free(cur, PAGE_SIZE);
ffffffffc0201a1a:	6585                	lui	a1,0x1
ffffffffc0201a1c:	e8dff0ef          	jal	ra,ffffffffc02018a8 <slob_free>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201a20:	10002673          	csrr	a2,sstatus
ffffffffc0201a24:	8a09                	andi	a2,a2,2
ffffffffc0201a26:	ee05                	bnez	a2,ffffffffc0201a5e <slob_alloc.constprop.0+0x9e>
			cur = slobfree;
ffffffffc0201a28:	00093783          	ld	a5,0(s2)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201a2c:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta)
ffffffffc0201a2e:	4018                	lw	a4,0(s0)
ffffffffc0201a30:	fc974ae3          	blt	a4,s1,ffffffffc0201a04 <slob_alloc.constprop.0+0x44>
			if (cur->units == units)	/* exact fit? */
ffffffffc0201a34:	04e48763          	beq	s1,a4,ffffffffc0201a82 <slob_alloc.constprop.0+0xc2>
				prev->next = cur + units;
ffffffffc0201a38:	00449693          	slli	a3,s1,0x4
ffffffffc0201a3c:	96a2                	add	a3,a3,s0
ffffffffc0201a3e:	e794                	sd	a3,8(a5)
				prev->next->next = cur->next;
ffffffffc0201a40:	640c                	ld	a1,8(s0)
				prev->next->units = cur->units - units;
ffffffffc0201a42:	9f05                	subw	a4,a4,s1
ffffffffc0201a44:	c298                	sw	a4,0(a3)
				prev->next->next = cur->next;
ffffffffc0201a46:	e68c                	sd	a1,8(a3)
				cur->units = units;
ffffffffc0201a48:	c004                	sw	s1,0(s0)
			slobfree = prev;
ffffffffc0201a4a:	00f93023          	sd	a5,0(s2)
    if (flag) {
ffffffffc0201a4e:	e20d                	bnez	a2,ffffffffc0201a70 <slob_alloc.constprop.0+0xb0>
}
ffffffffc0201a50:	60e2                	ld	ra,24(sp)
ffffffffc0201a52:	8522                	mv	a0,s0
ffffffffc0201a54:	6442                	ld	s0,16(sp)
ffffffffc0201a56:	64a2                	ld	s1,8(sp)
ffffffffc0201a58:	6902                	ld	s2,0(sp)
ffffffffc0201a5a:	6105                	addi	sp,sp,32
ffffffffc0201a5c:	8082                	ret
        intr_disable();
ffffffffc0201a5e:	ed3fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
			cur = slobfree;
ffffffffc0201a62:	00093783          	ld	a5,0(s2)
        return 1;
ffffffffc0201a66:	4605                	li	a2,1
ffffffffc0201a68:	b7d1                	j	ffffffffc0201a2c <slob_alloc.constprop.0+0x6c>
        intr_enable();
ffffffffc0201a6a:	ec1fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc0201a6e:	b74d                	j	ffffffffc0201a10 <slob_alloc.constprop.0+0x50>
ffffffffc0201a70:	ebbfe0ef          	jal	ra,ffffffffc020092a <intr_enable>
}
ffffffffc0201a74:	60e2                	ld	ra,24(sp)
ffffffffc0201a76:	8522                	mv	a0,s0
ffffffffc0201a78:	6442                	ld	s0,16(sp)
ffffffffc0201a7a:	64a2                	ld	s1,8(sp)
ffffffffc0201a7c:	6902                	ld	s2,0(sp)
ffffffffc0201a7e:	6105                	addi	sp,sp,32
ffffffffc0201a80:	8082                	ret
				prev->next = cur->next; /* unlink */
ffffffffc0201a82:	6418                	ld	a4,8(s0)
ffffffffc0201a84:	e798                	sd	a4,8(a5)
ffffffffc0201a86:	b7d1                	j	ffffffffc0201a4a <slob_alloc.constprop.0+0x8a>
        intr_disable();
ffffffffc0201a88:	ea9fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        return 1;
ffffffffc0201a8c:	4605                	li	a2,1
ffffffffc0201a8e:	bf99                	j	ffffffffc02019e4 <slob_alloc.constprop.0+0x24>
		if (cur->units >= units + delta)
ffffffffc0201a90:	843e                	mv	s0,a5
ffffffffc0201a92:	87b6                	mv	a5,a3
ffffffffc0201a94:	b745                	j	ffffffffc0201a34 <slob_alloc.constprop.0+0x74>
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201a96:	00003697          	auipc	a3,0x3
ffffffffc0201a9a:	30a68693          	addi	a3,a3,778 # ffffffffc0204da0 <default_pmm_manager+0x70>
ffffffffc0201a9e:	00003617          	auipc	a2,0x3
ffffffffc0201aa2:	ee260613          	addi	a2,a2,-286 # ffffffffc0204980 <commands+0x838>
ffffffffc0201aa6:	06300593          	li	a1,99
ffffffffc0201aaa:	00003517          	auipc	a0,0x3
ffffffffc0201aae:	31650513          	addi	a0,a0,790 # ffffffffc0204dc0 <default_pmm_manager+0x90>
ffffffffc0201ab2:	9a9fe0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0201ab6 <kmalloc_init>:
	cprintf("use SLOB allocator\n");
}

inline void
kmalloc_init(void)
{
ffffffffc0201ab6:	1141                	addi	sp,sp,-16
	cprintf("use SLOB allocator\n");
ffffffffc0201ab8:	00003517          	auipc	a0,0x3
ffffffffc0201abc:	32050513          	addi	a0,a0,800 # ffffffffc0204dd8 <default_pmm_manager+0xa8>
{
ffffffffc0201ac0:	e406                	sd	ra,8(sp)
	cprintf("use SLOB allocator\n");
ffffffffc0201ac2:	ed2fe0ef          	jal	ra,ffffffffc0200194 <cprintf>
	slob_init();
	cprintf("kmalloc_init() succeeded!\n");
}
ffffffffc0201ac6:	60a2                	ld	ra,8(sp)
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201ac8:	00003517          	auipc	a0,0x3
ffffffffc0201acc:	32850513          	addi	a0,a0,808 # ffffffffc0204df0 <default_pmm_manager+0xc0>
}
ffffffffc0201ad0:	0141                	addi	sp,sp,16
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201ad2:	ec2fe06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0201ad6 <kmalloc>:
	return 0;
}

void *
kmalloc(size_t size)
{
ffffffffc0201ad6:	1101                	addi	sp,sp,-32
ffffffffc0201ad8:	e04a                	sd	s2,0(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201ada:	6905                	lui	s2,0x1
{
ffffffffc0201adc:	e822                	sd	s0,16(sp)
ffffffffc0201ade:	ec06                	sd	ra,24(sp)
ffffffffc0201ae0:	e426                	sd	s1,8(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201ae2:	fef90793          	addi	a5,s2,-17 # fef <kern_entry-0xffffffffc01ff011>
{
ffffffffc0201ae6:	842a                	mv	s0,a0
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201ae8:	04a7f963          	bgeu	a5,a0,ffffffffc0201b3a <kmalloc+0x64>
	bb = slob_alloc(sizeof(bigblock_t), gfp, 0);
ffffffffc0201aec:	4561                	li	a0,24
ffffffffc0201aee:	ed3ff0ef          	jal	ra,ffffffffc02019c0 <slob_alloc.constprop.0>
ffffffffc0201af2:	84aa                	mv	s1,a0
	if (!bb)
ffffffffc0201af4:	c929                	beqz	a0,ffffffffc0201b46 <kmalloc+0x70>
	bb->order = find_order(size);
ffffffffc0201af6:	0004079b          	sext.w	a5,s0
	int order = 0;
ffffffffc0201afa:	4501                	li	a0,0
	for (; size > 4096; size >>= 1)
ffffffffc0201afc:	00f95763          	bge	s2,a5,ffffffffc0201b0a <kmalloc+0x34>
ffffffffc0201b00:	6705                	lui	a4,0x1
ffffffffc0201b02:	8785                	srai	a5,a5,0x1
		order++;
ffffffffc0201b04:	2505                	addiw	a0,a0,1
	for (; size > 4096; size >>= 1)
ffffffffc0201b06:	fef74ee3          	blt	a4,a5,ffffffffc0201b02 <kmalloc+0x2c>
	bb->order = find_order(size);
ffffffffc0201b0a:	c088                	sw	a0,0(s1)
	bb->pages = (void *)__slob_get_free_pages(gfp, bb->order);
ffffffffc0201b0c:	e51ff0ef          	jal	ra,ffffffffc020195c <__slob_get_free_pages.constprop.0>
ffffffffc0201b10:	e488                	sd	a0,8(s1)
ffffffffc0201b12:	842a                	mv	s0,a0
	if (bb->pages)
ffffffffc0201b14:	c525                	beqz	a0,ffffffffc0201b7c <kmalloc+0xa6>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201b16:	100027f3          	csrr	a5,sstatus
ffffffffc0201b1a:	8b89                	andi	a5,a5,2
ffffffffc0201b1c:	ef8d                	bnez	a5,ffffffffc0201b56 <kmalloc+0x80>
		bb->next = bigblocks;
ffffffffc0201b1e:	0000c797          	auipc	a5,0xc
ffffffffc0201b22:	97a78793          	addi	a5,a5,-1670 # ffffffffc020d498 <bigblocks>
ffffffffc0201b26:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0201b28:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201b2a:	e898                	sd	a4,16(s1)
	return __kmalloc(size, 0);
}
ffffffffc0201b2c:	60e2                	ld	ra,24(sp)
ffffffffc0201b2e:	8522                	mv	a0,s0
ffffffffc0201b30:	6442                	ld	s0,16(sp)
ffffffffc0201b32:	64a2                	ld	s1,8(sp)
ffffffffc0201b34:	6902                	ld	s2,0(sp)
ffffffffc0201b36:	6105                	addi	sp,sp,32
ffffffffc0201b38:	8082                	ret
		m = slob_alloc(size + SLOB_UNIT, gfp, 0);
ffffffffc0201b3a:	0541                	addi	a0,a0,16
ffffffffc0201b3c:	e85ff0ef          	jal	ra,ffffffffc02019c0 <slob_alloc.constprop.0>
		return m ? (void *)(m + 1) : 0;
ffffffffc0201b40:	01050413          	addi	s0,a0,16
ffffffffc0201b44:	f565                	bnez	a0,ffffffffc0201b2c <kmalloc+0x56>
ffffffffc0201b46:	4401                	li	s0,0
}
ffffffffc0201b48:	60e2                	ld	ra,24(sp)
ffffffffc0201b4a:	8522                	mv	a0,s0
ffffffffc0201b4c:	6442                	ld	s0,16(sp)
ffffffffc0201b4e:	64a2                	ld	s1,8(sp)
ffffffffc0201b50:	6902                	ld	s2,0(sp)
ffffffffc0201b52:	6105                	addi	sp,sp,32
ffffffffc0201b54:	8082                	ret
        intr_disable();
ffffffffc0201b56:	ddbfe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
		bb->next = bigblocks;
ffffffffc0201b5a:	0000c797          	auipc	a5,0xc
ffffffffc0201b5e:	93e78793          	addi	a5,a5,-1730 # ffffffffc020d498 <bigblocks>
ffffffffc0201b62:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0201b64:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201b66:	e898                	sd	a4,16(s1)
        intr_enable();
ffffffffc0201b68:	dc3fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
		return bb->pages;
ffffffffc0201b6c:	6480                	ld	s0,8(s1)
}
ffffffffc0201b6e:	60e2                	ld	ra,24(sp)
ffffffffc0201b70:	64a2                	ld	s1,8(sp)
ffffffffc0201b72:	8522                	mv	a0,s0
ffffffffc0201b74:	6442                	ld	s0,16(sp)
ffffffffc0201b76:	6902                	ld	s2,0(sp)
ffffffffc0201b78:	6105                	addi	sp,sp,32
ffffffffc0201b7a:	8082                	ret
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0201b7c:	45e1                	li	a1,24
ffffffffc0201b7e:	8526                	mv	a0,s1
ffffffffc0201b80:	d29ff0ef          	jal	ra,ffffffffc02018a8 <slob_free>
	return __kmalloc(size, 0);
ffffffffc0201b84:	b765                	j	ffffffffc0201b2c <kmalloc+0x56>

ffffffffc0201b86 <kfree>:
void kfree(void *block)
{
	bigblock_t *bb, **last = &bigblocks;
	unsigned long flags;

	if (!block)
ffffffffc0201b86:	c169                	beqz	a0,ffffffffc0201c48 <kfree+0xc2>
{
ffffffffc0201b88:	1101                	addi	sp,sp,-32
ffffffffc0201b8a:	e822                	sd	s0,16(sp)
ffffffffc0201b8c:	ec06                	sd	ra,24(sp)
ffffffffc0201b8e:	e426                	sd	s1,8(sp)
		return;

	if (!((unsigned long)block & (PAGE_SIZE - 1)))
ffffffffc0201b90:	03451793          	slli	a5,a0,0x34
ffffffffc0201b94:	842a                	mv	s0,a0
ffffffffc0201b96:	e3d9                	bnez	a5,ffffffffc0201c1c <kfree+0x96>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201b98:	100027f3          	csrr	a5,sstatus
ffffffffc0201b9c:	8b89                	andi	a5,a5,2
ffffffffc0201b9e:	e7d9                	bnez	a5,ffffffffc0201c2c <kfree+0xa6>
	{
		/* might be on the big block list */
		spin_lock_irqsave(&block_lock, flags);
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201ba0:	0000c797          	auipc	a5,0xc
ffffffffc0201ba4:	8f87b783          	ld	a5,-1800(a5) # ffffffffc020d498 <bigblocks>
    return 0;
ffffffffc0201ba8:	4601                	li	a2,0
ffffffffc0201baa:	cbad                	beqz	a5,ffffffffc0201c1c <kfree+0x96>
	bigblock_t *bb, **last = &bigblocks;
ffffffffc0201bac:	0000c697          	auipc	a3,0xc
ffffffffc0201bb0:	8ec68693          	addi	a3,a3,-1812 # ffffffffc020d498 <bigblocks>
ffffffffc0201bb4:	a021                	j	ffffffffc0201bbc <kfree+0x36>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201bb6:	01048693          	addi	a3,s1,16
ffffffffc0201bba:	c3a5                	beqz	a5,ffffffffc0201c1a <kfree+0x94>
		{
			if (bb->pages == block)
ffffffffc0201bbc:	6798                	ld	a4,8(a5)
ffffffffc0201bbe:	84be                	mv	s1,a5
			{
				*last = bb->next;
ffffffffc0201bc0:	6b9c                	ld	a5,16(a5)
			if (bb->pages == block)
ffffffffc0201bc2:	fe871ae3          	bne	a4,s0,ffffffffc0201bb6 <kfree+0x30>
				*last = bb->next;
ffffffffc0201bc6:	e29c                	sd	a5,0(a3)
    if (flag) {
ffffffffc0201bc8:	ee2d                	bnez	a2,ffffffffc0201c42 <kfree+0xbc>
    return pa2page(PADDR(kva));
ffffffffc0201bca:	c02007b7          	lui	a5,0xc0200
				spin_unlock_irqrestore(&block_lock, flags);
				__slob_free_pages((unsigned long)block, bb->order);
ffffffffc0201bce:	4098                	lw	a4,0(s1)
ffffffffc0201bd0:	08f46963          	bltu	s0,a5,ffffffffc0201c62 <kfree+0xdc>
ffffffffc0201bd4:	0000c697          	auipc	a3,0xc
ffffffffc0201bd8:	8f46b683          	ld	a3,-1804(a3) # ffffffffc020d4c8 <va_pa_offset>
ffffffffc0201bdc:	8c15                	sub	s0,s0,a3
    if (PPN(pa) >= npage)
ffffffffc0201bde:	8031                	srli	s0,s0,0xc
ffffffffc0201be0:	0000c797          	auipc	a5,0xc
ffffffffc0201be4:	8d07b783          	ld	a5,-1840(a5) # ffffffffc020d4b0 <npage>
ffffffffc0201be8:	06f47163          	bgeu	s0,a5,ffffffffc0201c4a <kfree+0xc4>
    return &pages[PPN(pa) - nbase];
ffffffffc0201bec:	00004517          	auipc	a0,0x4
ffffffffc0201bf0:	e5c53503          	ld	a0,-420(a0) # ffffffffc0205a48 <nbase>
ffffffffc0201bf4:	8c09                	sub	s0,s0,a0
ffffffffc0201bf6:	041a                	slli	s0,s0,0x6
	free_pages(kva2page(kva), 1 << order);
ffffffffc0201bf8:	0000c517          	auipc	a0,0xc
ffffffffc0201bfc:	8c053503          	ld	a0,-1856(a0) # ffffffffc020d4b8 <pages>
ffffffffc0201c00:	4585                	li	a1,1
ffffffffc0201c02:	9522                	add	a0,a0,s0
ffffffffc0201c04:	00e595bb          	sllw	a1,a1,a4
ffffffffc0201c08:	0ea000ef          	jal	ra,ffffffffc0201cf2 <free_pages>
		spin_unlock_irqrestore(&block_lock, flags);
	}

	slob_free((slob_t *)block - 1, 0);
	return;
}
ffffffffc0201c0c:	6442                	ld	s0,16(sp)
ffffffffc0201c0e:	60e2                	ld	ra,24(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201c10:	8526                	mv	a0,s1
}
ffffffffc0201c12:	64a2                	ld	s1,8(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201c14:	45e1                	li	a1,24
}
ffffffffc0201c16:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201c18:	b941                	j	ffffffffc02018a8 <slob_free>
ffffffffc0201c1a:	e20d                	bnez	a2,ffffffffc0201c3c <kfree+0xb6>
ffffffffc0201c1c:	ff040513          	addi	a0,s0,-16
}
ffffffffc0201c20:	6442                	ld	s0,16(sp)
ffffffffc0201c22:	60e2                	ld	ra,24(sp)
ffffffffc0201c24:	64a2                	ld	s1,8(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201c26:	4581                	li	a1,0
}
ffffffffc0201c28:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201c2a:	b9bd                	j	ffffffffc02018a8 <slob_free>
        intr_disable();
ffffffffc0201c2c:	d05fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201c30:	0000c797          	auipc	a5,0xc
ffffffffc0201c34:	8687b783          	ld	a5,-1944(a5) # ffffffffc020d498 <bigblocks>
        return 1;
ffffffffc0201c38:	4605                	li	a2,1
ffffffffc0201c3a:	fbad                	bnez	a5,ffffffffc0201bac <kfree+0x26>
        intr_enable();
ffffffffc0201c3c:	ceffe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc0201c40:	bff1                	j	ffffffffc0201c1c <kfree+0x96>
ffffffffc0201c42:	ce9fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc0201c46:	b751                	j	ffffffffc0201bca <kfree+0x44>
ffffffffc0201c48:	8082                	ret
        panic("pa2page called with invalid pa");
ffffffffc0201c4a:	00003617          	auipc	a2,0x3
ffffffffc0201c4e:	1ee60613          	addi	a2,a2,494 # ffffffffc0204e38 <default_pmm_manager+0x108>
ffffffffc0201c52:	06900593          	li	a1,105
ffffffffc0201c56:	00003517          	auipc	a0,0x3
ffffffffc0201c5a:	13a50513          	addi	a0,a0,314 # ffffffffc0204d90 <default_pmm_manager+0x60>
ffffffffc0201c5e:	ffcfe0ef          	jal	ra,ffffffffc020045a <__panic>
    return pa2page(PADDR(kva));
ffffffffc0201c62:	86a2                	mv	a3,s0
ffffffffc0201c64:	00003617          	auipc	a2,0x3
ffffffffc0201c68:	1ac60613          	addi	a2,a2,428 # ffffffffc0204e10 <default_pmm_manager+0xe0>
ffffffffc0201c6c:	07700593          	li	a1,119
ffffffffc0201c70:	00003517          	auipc	a0,0x3
ffffffffc0201c74:	12050513          	addi	a0,a0,288 # ffffffffc0204d90 <default_pmm_manager+0x60>
ffffffffc0201c78:	fe2fe0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0201c7c <pa2page.part.0>:
pa2page(uintptr_t pa)
ffffffffc0201c7c:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc0201c7e:	00003617          	auipc	a2,0x3
ffffffffc0201c82:	1ba60613          	addi	a2,a2,442 # ffffffffc0204e38 <default_pmm_manager+0x108>
ffffffffc0201c86:	06900593          	li	a1,105
ffffffffc0201c8a:	00003517          	auipc	a0,0x3
ffffffffc0201c8e:	10650513          	addi	a0,a0,262 # ffffffffc0204d90 <default_pmm_manager+0x60>
pa2page(uintptr_t pa)
ffffffffc0201c92:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc0201c94:	fc6fe0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0201c98 <pte2page.part.0>:
pte2page(pte_t pte)
ffffffffc0201c98:	1141                	addi	sp,sp,-16
        panic("pte2page called with invalid pte");
ffffffffc0201c9a:	00003617          	auipc	a2,0x3
ffffffffc0201c9e:	1be60613          	addi	a2,a2,446 # ffffffffc0204e58 <default_pmm_manager+0x128>
ffffffffc0201ca2:	07f00593          	li	a1,127
ffffffffc0201ca6:	00003517          	auipc	a0,0x3
ffffffffc0201caa:	0ea50513          	addi	a0,a0,234 # ffffffffc0204d90 <default_pmm_manager+0x60>
pte2page(pte_t pte)
ffffffffc0201cae:	e406                	sd	ra,8(sp)
        panic("pte2page called with invalid pte");
ffffffffc0201cb0:	faafe0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0201cb4 <alloc_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201cb4:	100027f3          	csrr	a5,sstatus
ffffffffc0201cb8:	8b89                	andi	a5,a5,2
ffffffffc0201cba:	e799                	bnez	a5,ffffffffc0201cc8 <alloc_pages+0x14>
{
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0201cbc:	0000c797          	auipc	a5,0xc
ffffffffc0201cc0:	8047b783          	ld	a5,-2044(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc0201cc4:	6f9c                	ld	a5,24(a5)
ffffffffc0201cc6:	8782                	jr	a5
{
ffffffffc0201cc8:	1141                	addi	sp,sp,-16
ffffffffc0201cca:	e406                	sd	ra,8(sp)
ffffffffc0201ccc:	e022                	sd	s0,0(sp)
ffffffffc0201cce:	842a                	mv	s0,a0
        intr_disable();
ffffffffc0201cd0:	c61fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201cd4:	0000b797          	auipc	a5,0xb
ffffffffc0201cd8:	7ec7b783          	ld	a5,2028(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc0201cdc:	6f9c                	ld	a5,24(a5)
ffffffffc0201cde:	8522                	mv	a0,s0
ffffffffc0201ce0:	9782                	jalr	a5
ffffffffc0201ce2:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201ce4:	c47fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc0201ce8:	60a2                	ld	ra,8(sp)
ffffffffc0201cea:	8522                	mv	a0,s0
ffffffffc0201cec:	6402                	ld	s0,0(sp)
ffffffffc0201cee:	0141                	addi	sp,sp,16
ffffffffc0201cf0:	8082                	ret

ffffffffc0201cf2 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201cf2:	100027f3          	csrr	a5,sstatus
ffffffffc0201cf6:	8b89                	andi	a5,a5,2
ffffffffc0201cf8:	e799                	bnez	a5,ffffffffc0201d06 <free_pages+0x14>
void free_pages(struct Page *base, size_t n)
{
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0201cfa:	0000b797          	auipc	a5,0xb
ffffffffc0201cfe:	7c67b783          	ld	a5,1990(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc0201d02:	739c                	ld	a5,32(a5)
ffffffffc0201d04:	8782                	jr	a5
{
ffffffffc0201d06:	1101                	addi	sp,sp,-32
ffffffffc0201d08:	ec06                	sd	ra,24(sp)
ffffffffc0201d0a:	e822                	sd	s0,16(sp)
ffffffffc0201d0c:	e426                	sd	s1,8(sp)
ffffffffc0201d0e:	842a                	mv	s0,a0
ffffffffc0201d10:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0201d12:	c1ffe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201d16:	0000b797          	auipc	a5,0xb
ffffffffc0201d1a:	7aa7b783          	ld	a5,1962(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc0201d1e:	739c                	ld	a5,32(a5)
ffffffffc0201d20:	85a6                	mv	a1,s1
ffffffffc0201d22:	8522                	mv	a0,s0
ffffffffc0201d24:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0201d26:	6442                	ld	s0,16(sp)
ffffffffc0201d28:	60e2                	ld	ra,24(sp)
ffffffffc0201d2a:	64a2                	ld	s1,8(sp)
ffffffffc0201d2c:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201d2e:	bfdfe06f          	j	ffffffffc020092a <intr_enable>

ffffffffc0201d32 <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201d32:	100027f3          	csrr	a5,sstatus
ffffffffc0201d36:	8b89                	andi	a5,a5,2
ffffffffc0201d38:	e799                	bnez	a5,ffffffffc0201d46 <nr_free_pages+0x14>
{
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0201d3a:	0000b797          	auipc	a5,0xb
ffffffffc0201d3e:	7867b783          	ld	a5,1926(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc0201d42:	779c                	ld	a5,40(a5)
ffffffffc0201d44:	8782                	jr	a5
{
ffffffffc0201d46:	1141                	addi	sp,sp,-16
ffffffffc0201d48:	e406                	sd	ra,8(sp)
ffffffffc0201d4a:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc0201d4c:	be5fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201d50:	0000b797          	auipc	a5,0xb
ffffffffc0201d54:	7707b783          	ld	a5,1904(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc0201d58:	779c                	ld	a5,40(a5)
ffffffffc0201d5a:	9782                	jalr	a5
ffffffffc0201d5c:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201d5e:	bcdfe0ef          	jal	ra,ffffffffc020092a <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0201d62:	60a2                	ld	ra,8(sp)
ffffffffc0201d64:	8522                	mv	a0,s0
ffffffffc0201d66:	6402                	ld	s0,0(sp)
ffffffffc0201d68:	0141                	addi	sp,sp,16
ffffffffc0201d6a:	8082                	ret

ffffffffc0201d6c <get_pte>:
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create)
{
    // 2310675: 第一级页表查找（sv39三级页表的顶层）
    pde_t *pdep1 = &pgdir[PDX1(la)];  // 2310675: 通过PDX1(la)索引一级页目录
ffffffffc0201d6c:	01e5d793          	srli	a5,a1,0x1e
ffffffffc0201d70:	1ff7f793          	andi	a5,a5,511
{
ffffffffc0201d74:	7139                	addi	sp,sp,-64
    pde_t *pdep1 = &pgdir[PDX1(la)];  // 2310675: 通过PDX1(la)索引一级页目录
ffffffffc0201d76:	078e                	slli	a5,a5,0x3
{
ffffffffc0201d78:	f426                	sd	s1,40(sp)
    pde_t *pdep1 = &pgdir[PDX1(la)];  // 2310675: 通过PDX1(la)索引一级页目录
ffffffffc0201d7a:	00f504b3          	add	s1,a0,a5
    if (!(*pdep1 & PTE_V))  // 2310675: 检查页表项的Valid位，判断下一级页表是否存在
ffffffffc0201d7e:	6094                	ld	a3,0(s1)
{
ffffffffc0201d80:	f04a                	sd	s2,32(sp)
ffffffffc0201d82:	ec4e                	sd	s3,24(sp)
ffffffffc0201d84:	e852                	sd	s4,16(sp)
ffffffffc0201d86:	fc06                	sd	ra,56(sp)
ffffffffc0201d88:	f822                	sd	s0,48(sp)
ffffffffc0201d8a:	e456                	sd	s5,8(sp)
ffffffffc0201d8c:	e05a                	sd	s6,0(sp)
    if (!(*pdep1 & PTE_V))  // 2310675: 检查页表项的Valid位，判断下一级页表是否存在
ffffffffc0201d8e:	0016f793          	andi	a5,a3,1
{
ffffffffc0201d92:	892e                	mv	s2,a1
ffffffffc0201d94:	8a32                	mv	s4,a2
ffffffffc0201d96:	0000b997          	auipc	s3,0xb
ffffffffc0201d9a:	71a98993          	addi	s3,s3,1818 # ffffffffc020d4b0 <npage>
    if (!(*pdep1 & PTE_V))  // 2310675: 检查页表项的Valid位，判断下一级页表是否存在
ffffffffc0201d9e:	efbd                	bnez	a5,ffffffffc0201e1c <get_pte+0xb0>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)  // 2310675: 如果不允许创建或内存不足，返回NULL
ffffffffc0201da0:	14060c63          	beqz	a2,ffffffffc0201ef8 <get_pte+0x18c>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201da4:	100027f3          	csrr	a5,sstatus
ffffffffc0201da8:	8b89                	andi	a5,a5,2
ffffffffc0201daa:	14079963          	bnez	a5,ffffffffc0201efc <get_pte+0x190>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201dae:	0000b797          	auipc	a5,0xb
ffffffffc0201db2:	7127b783          	ld	a5,1810(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc0201db6:	6f9c                	ld	a5,24(a5)
ffffffffc0201db8:	4505                	li	a0,1
ffffffffc0201dba:	9782                	jalr	a5
ffffffffc0201dbc:	842a                	mv	s0,a0
        if (!create || (page = alloc_page()) == NULL)  // 2310675: 如果不允许创建或内存不足，返回NULL
ffffffffc0201dbe:	12040d63          	beqz	s0,ffffffffc0201ef8 <get_pte+0x18c>
    return page - pages + nbase;
ffffffffc0201dc2:	0000bb17          	auipc	s6,0xb
ffffffffc0201dc6:	6f6b0b13          	addi	s6,s6,1782 # ffffffffc020d4b8 <pages>
ffffffffc0201dca:	000b3503          	ld	a0,0(s6)
ffffffffc0201dce:	00080ab7          	lui	s5,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);  // 2310675: 设置物理页引用计数为1
        uintptr_t pa = page2pa(page);  // 2310675: 获取新分配页面的物理地址
        memset(KADDR(pa), 0, PGSIZE);  // 2310675: 将新页表清零，KADDR将物理地址转为内核虚拟地址
ffffffffc0201dd2:	0000b997          	auipc	s3,0xb
ffffffffc0201dd6:	6de98993          	addi	s3,s3,1758 # ffffffffc020d4b0 <npage>
ffffffffc0201dda:	40a40533          	sub	a0,s0,a0
ffffffffc0201dde:	8519                	srai	a0,a0,0x6
ffffffffc0201de0:	9556                	add	a0,a0,s5
ffffffffc0201de2:	0009b703          	ld	a4,0(s3)
ffffffffc0201de6:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc0201dea:	4685                	li	a3,1
ffffffffc0201dec:	c014                	sw	a3,0(s0)
ffffffffc0201dee:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201df0:	0532                	slli	a0,a0,0xc
ffffffffc0201df2:	16e7f763          	bgeu	a5,a4,ffffffffc0201f60 <get_pte+0x1f4>
ffffffffc0201df6:	0000b797          	auipc	a5,0xb
ffffffffc0201dfa:	6d27b783          	ld	a5,1746(a5) # ffffffffc020d4c8 <va_pa_offset>
ffffffffc0201dfe:	6605                	lui	a2,0x1
ffffffffc0201e00:	4581                	li	a1,0
ffffffffc0201e02:	953e                	add	a0,a0,a5
ffffffffc0201e04:	08e020ef          	jal	ra,ffffffffc0203e92 <memset>
    return page - pages + nbase;
ffffffffc0201e08:	000b3683          	ld	a3,0(s6)
ffffffffc0201e0c:	40d406b3          	sub	a3,s0,a3
ffffffffc0201e10:	8699                	srai	a3,a3,0x6
ffffffffc0201e12:	96d6                	add	a3,a3,s5
}

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type)
{
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201e14:	06aa                	slli	a3,a3,0xa
ffffffffc0201e16:	0116e693          	ori	a3,a3,17
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);  // 2310675: 创建页表项，设置为有效且用户可访问
ffffffffc0201e1a:	e094                	sd	a3,0(s1)
    }

    // 2310675: 第二级页表查找（sv39三级页表的中层）
    pde_t *pdep0 = &((pte_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];  // 2310675: 获取二级页表基址并索引PDX0
ffffffffc0201e1c:	77fd                	lui	a5,0xfffff
ffffffffc0201e1e:	068a                	slli	a3,a3,0x2
ffffffffc0201e20:	0009b703          	ld	a4,0(s3)
ffffffffc0201e24:	8efd                	and	a3,a3,a5
ffffffffc0201e26:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201e2a:	10e7ff63          	bgeu	a5,a4,ffffffffc0201f48 <get_pte+0x1dc>
ffffffffc0201e2e:	0000ba97          	auipc	s5,0xb
ffffffffc0201e32:	69aa8a93          	addi	s5,s5,1690 # ffffffffc020d4c8 <va_pa_offset>
ffffffffc0201e36:	000ab403          	ld	s0,0(s5)
ffffffffc0201e3a:	01595793          	srli	a5,s2,0x15
ffffffffc0201e3e:	1ff7f793          	andi	a5,a5,511
ffffffffc0201e42:	96a2                	add	a3,a3,s0
ffffffffc0201e44:	00379413          	slli	s0,a5,0x3
ffffffffc0201e48:	9436                	add	s0,s0,a3
    if (!(*pdep0 & PTE_V))  // 2310675: 同样检查Valid位
ffffffffc0201e4a:	6014                	ld	a3,0(s0)
ffffffffc0201e4c:	0016f793          	andi	a5,a3,1
ffffffffc0201e50:	ebad                	bnez	a5,ffffffffc0201ec2 <get_pte+0x156>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)  // 2310675: 按需分配第三级页表
ffffffffc0201e52:	0a0a0363          	beqz	s4,ffffffffc0201ef8 <get_pte+0x18c>
ffffffffc0201e56:	100027f3          	csrr	a5,sstatus
ffffffffc0201e5a:	8b89                	andi	a5,a5,2
ffffffffc0201e5c:	efcd                	bnez	a5,ffffffffc0201f16 <get_pte+0x1aa>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201e5e:	0000b797          	auipc	a5,0xb
ffffffffc0201e62:	6627b783          	ld	a5,1634(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc0201e66:	6f9c                	ld	a5,24(a5)
ffffffffc0201e68:	4505                	li	a0,1
ffffffffc0201e6a:	9782                	jalr	a5
ffffffffc0201e6c:	84aa                	mv	s1,a0
        if (!create || (page = alloc_page()) == NULL)  // 2310675: 按需分配第三级页表
ffffffffc0201e6e:	c4c9                	beqz	s1,ffffffffc0201ef8 <get_pte+0x18c>
    return page - pages + nbase;
ffffffffc0201e70:	0000bb17          	auipc	s6,0xb
ffffffffc0201e74:	648b0b13          	addi	s6,s6,1608 # ffffffffc020d4b8 <pages>
ffffffffc0201e78:	000b3503          	ld	a0,0(s6)
ffffffffc0201e7c:	00080a37          	lui	s4,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);  // 2310675: 设置引用计数
        uintptr_t pa = page2pa(page);  // 2310675: 获取物理地址
        memset(KADDR(pa), 0, PGSIZE);  // 2310675: 清零新页表
ffffffffc0201e80:	0009b703          	ld	a4,0(s3)
ffffffffc0201e84:	40a48533          	sub	a0,s1,a0
ffffffffc0201e88:	8519                	srai	a0,a0,0x6
ffffffffc0201e8a:	9552                	add	a0,a0,s4
ffffffffc0201e8c:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc0201e90:	4685                	li	a3,1
ffffffffc0201e92:	c094                	sw	a3,0(s1)
ffffffffc0201e94:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201e96:	0532                	slli	a0,a0,0xc
ffffffffc0201e98:	0ee7f163          	bgeu	a5,a4,ffffffffc0201f7a <get_pte+0x20e>
ffffffffc0201e9c:	000ab783          	ld	a5,0(s5)
ffffffffc0201ea0:	6605                	lui	a2,0x1
ffffffffc0201ea2:	4581                	li	a1,0
ffffffffc0201ea4:	953e                	add	a0,a0,a5
ffffffffc0201ea6:	7ed010ef          	jal	ra,ffffffffc0203e92 <memset>
    return page - pages + nbase;
ffffffffc0201eaa:	000b3683          	ld	a3,0(s6)
ffffffffc0201eae:	40d486b3          	sub	a3,s1,a3
ffffffffc0201eb2:	8699                	srai	a3,a3,0x6
ffffffffc0201eb4:	96d2                	add	a3,a3,s4
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201eb6:	06aa                	slli	a3,a3,0xa
ffffffffc0201eb8:	0116e693          	ori	a3,a3,17
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);  // 2310675: 建立二级页表项
ffffffffc0201ebc:	e014                	sd	a3,0(s0)
    }

    // 2310675: 返回第三级页表（真正的页表）中对应虚拟地址的页表项指针
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];  // 2310675: PTX(la)提取页内索引
ffffffffc0201ebe:	0009b703          	ld	a4,0(s3)
ffffffffc0201ec2:	068a                	slli	a3,a3,0x2
ffffffffc0201ec4:	757d                	lui	a0,0xfffff
ffffffffc0201ec6:	8ee9                	and	a3,a3,a0
ffffffffc0201ec8:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201ecc:	06e7f263          	bgeu	a5,a4,ffffffffc0201f30 <get_pte+0x1c4>
ffffffffc0201ed0:	000ab503          	ld	a0,0(s5)
ffffffffc0201ed4:	00c95913          	srli	s2,s2,0xc
ffffffffc0201ed8:	1ff97913          	andi	s2,s2,511
ffffffffc0201edc:	96aa                	add	a3,a3,a0
ffffffffc0201ede:	00391513          	slli	a0,s2,0x3
ffffffffc0201ee2:	9536                	add	a0,a0,a3
}
ffffffffc0201ee4:	70e2                	ld	ra,56(sp)
ffffffffc0201ee6:	7442                	ld	s0,48(sp)
ffffffffc0201ee8:	74a2                	ld	s1,40(sp)
ffffffffc0201eea:	7902                	ld	s2,32(sp)
ffffffffc0201eec:	69e2                	ld	s3,24(sp)
ffffffffc0201eee:	6a42                	ld	s4,16(sp)
ffffffffc0201ef0:	6aa2                	ld	s5,8(sp)
ffffffffc0201ef2:	6b02                	ld	s6,0(sp)
ffffffffc0201ef4:	6121                	addi	sp,sp,64
ffffffffc0201ef6:	8082                	ret
            return NULL;
ffffffffc0201ef8:	4501                	li	a0,0
ffffffffc0201efa:	b7ed                	j	ffffffffc0201ee4 <get_pte+0x178>
        intr_disable();
ffffffffc0201efc:	a35fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201f00:	0000b797          	auipc	a5,0xb
ffffffffc0201f04:	5c07b783          	ld	a5,1472(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc0201f08:	6f9c                	ld	a5,24(a5)
ffffffffc0201f0a:	4505                	li	a0,1
ffffffffc0201f0c:	9782                	jalr	a5
ffffffffc0201f0e:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201f10:	a1bfe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc0201f14:	b56d                	j	ffffffffc0201dbe <get_pte+0x52>
        intr_disable();
ffffffffc0201f16:	a1bfe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
ffffffffc0201f1a:	0000b797          	auipc	a5,0xb
ffffffffc0201f1e:	5a67b783          	ld	a5,1446(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc0201f22:	6f9c                	ld	a5,24(a5)
ffffffffc0201f24:	4505                	li	a0,1
ffffffffc0201f26:	9782                	jalr	a5
ffffffffc0201f28:	84aa                	mv	s1,a0
        intr_enable();
ffffffffc0201f2a:	a01fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc0201f2e:	b781                	j	ffffffffc0201e6e <get_pte+0x102>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];  // 2310675: PTX(la)提取页内索引
ffffffffc0201f30:	00003617          	auipc	a2,0x3
ffffffffc0201f34:	e3860613          	addi	a2,a2,-456 # ffffffffc0204d68 <default_pmm_manager+0x38>
ffffffffc0201f38:	10000593          	li	a1,256
ffffffffc0201f3c:	00003517          	auipc	a0,0x3
ffffffffc0201f40:	f4450513          	addi	a0,a0,-188 # ffffffffc0204e80 <default_pmm_manager+0x150>
ffffffffc0201f44:	d16fe0ef          	jal	ra,ffffffffc020045a <__panic>
    pde_t *pdep0 = &((pte_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];  // 2310675: 获取二级页表基址并索引PDX0
ffffffffc0201f48:	00003617          	auipc	a2,0x3
ffffffffc0201f4c:	e2060613          	addi	a2,a2,-480 # ffffffffc0204d68 <default_pmm_manager+0x38>
ffffffffc0201f50:	0f100593          	li	a1,241
ffffffffc0201f54:	00003517          	auipc	a0,0x3
ffffffffc0201f58:	f2c50513          	addi	a0,a0,-212 # ffffffffc0204e80 <default_pmm_manager+0x150>
ffffffffc0201f5c:	cfefe0ef          	jal	ra,ffffffffc020045a <__panic>
        memset(KADDR(pa), 0, PGSIZE);  // 2310675: 将新页表清零，KADDR将物理地址转为内核虚拟地址
ffffffffc0201f60:	86aa                	mv	a3,a0
ffffffffc0201f62:	00003617          	auipc	a2,0x3
ffffffffc0201f66:	e0660613          	addi	a2,a2,-506 # ffffffffc0204d68 <default_pmm_manager+0x38>
ffffffffc0201f6a:	0ec00593          	li	a1,236
ffffffffc0201f6e:	00003517          	auipc	a0,0x3
ffffffffc0201f72:	f1250513          	addi	a0,a0,-238 # ffffffffc0204e80 <default_pmm_manager+0x150>
ffffffffc0201f76:	ce4fe0ef          	jal	ra,ffffffffc020045a <__panic>
        memset(KADDR(pa), 0, PGSIZE);  // 2310675: 清零新页表
ffffffffc0201f7a:	86aa                	mv	a3,a0
ffffffffc0201f7c:	00003617          	auipc	a2,0x3
ffffffffc0201f80:	dec60613          	addi	a2,a2,-532 # ffffffffc0204d68 <default_pmm_manager+0x38>
ffffffffc0201f84:	0fb00593          	li	a1,251
ffffffffc0201f88:	00003517          	auipc	a0,0x3
ffffffffc0201f8c:	ef850513          	addi	a0,a0,-264 # ffffffffc0204e80 <default_pmm_manager+0x150>
ffffffffc0201f90:	ccafe0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0201f94 <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store)
{
ffffffffc0201f94:	1141                	addi	sp,sp,-16
ffffffffc0201f96:	e022                	sd	s0,0(sp)
ffffffffc0201f98:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201f9a:	4601                	li	a2,0
{
ffffffffc0201f9c:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201f9e:	dcfff0ef          	jal	ra,ffffffffc0201d6c <get_pte>
    if (ptep_store != NULL)
ffffffffc0201fa2:	c011                	beqz	s0,ffffffffc0201fa6 <get_page+0x12>
    {
        *ptep_store = ptep;
ffffffffc0201fa4:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc0201fa6:	c511                	beqz	a0,ffffffffc0201fb2 <get_page+0x1e>
ffffffffc0201fa8:	611c                	ld	a5,0(a0)
    {
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc0201faa:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc0201fac:	0017f713          	andi	a4,a5,1
ffffffffc0201fb0:	e709                	bnez	a4,ffffffffc0201fba <get_page+0x26>
}
ffffffffc0201fb2:	60a2                	ld	ra,8(sp)
ffffffffc0201fb4:	6402                	ld	s0,0(sp)
ffffffffc0201fb6:	0141                	addi	sp,sp,16
ffffffffc0201fb8:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0201fba:	078a                	slli	a5,a5,0x2
ffffffffc0201fbc:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0201fbe:	0000b717          	auipc	a4,0xb
ffffffffc0201fc2:	4f273703          	ld	a4,1266(a4) # ffffffffc020d4b0 <npage>
ffffffffc0201fc6:	00e7ff63          	bgeu	a5,a4,ffffffffc0201fe4 <get_page+0x50>
ffffffffc0201fca:	60a2                	ld	ra,8(sp)
ffffffffc0201fcc:	6402                	ld	s0,0(sp)
    return &pages[PPN(pa) - nbase];
ffffffffc0201fce:	fff80537          	lui	a0,0xfff80
ffffffffc0201fd2:	97aa                	add	a5,a5,a0
ffffffffc0201fd4:	079a                	slli	a5,a5,0x6
ffffffffc0201fd6:	0000b517          	auipc	a0,0xb
ffffffffc0201fda:	4e253503          	ld	a0,1250(a0) # ffffffffc020d4b8 <pages>
ffffffffc0201fde:	953e                	add	a0,a0,a5
ffffffffc0201fe0:	0141                	addi	sp,sp,16
ffffffffc0201fe2:	8082                	ret
ffffffffc0201fe4:	c99ff0ef          	jal	ra,ffffffffc0201c7c <pa2page.part.0>

ffffffffc0201fe8 <page_remove>:
}

// page_remove - free an Page which is related linear address la and has an
// validated pte
void page_remove(pde_t *pgdir, uintptr_t la)
{
ffffffffc0201fe8:	7179                	addi	sp,sp,-48
    // 2310675: 删除虚拟地址la的映射关系
    pte_t *ptep = get_pte(pgdir, la, 0);  // 2310675: 查找页表项（不创建），0表示只查找不分配
ffffffffc0201fea:	4601                	li	a2,0
{
ffffffffc0201fec:	ec26                	sd	s1,24(sp)
ffffffffc0201fee:	f406                	sd	ra,40(sp)
ffffffffc0201ff0:	f022                	sd	s0,32(sp)
ffffffffc0201ff2:	84ae                	mv	s1,a1
    pte_t *ptep = get_pte(pgdir, la, 0);  // 2310675: 查找页表项（不创建），0表示只查找不分配
ffffffffc0201ff4:	d79ff0ef          	jal	ra,ffffffffc0201d6c <get_pte>
    if (ptep != NULL)  // 2310675: 如果页表项存在
ffffffffc0201ff8:	c511                	beqz	a0,ffffffffc0202004 <page_remove+0x1c>
    if (*ptep & PTE_V)  // 2310675: (1) 检查页表项是否有效
ffffffffc0201ffa:	611c                	ld	a5,0(a0)
ffffffffc0201ffc:	842a                	mv	s0,a0
ffffffffc0201ffe:	0017f713          	andi	a4,a5,1
ffffffffc0202002:	e711                	bnez	a4,ffffffffc020200e <page_remove+0x26>
    {
        page_remove_pte(pgdir, la, ptep);  // 2310675: 调用page_remove_pte删除映射
    }
}
ffffffffc0202004:	70a2                	ld	ra,40(sp)
ffffffffc0202006:	7402                	ld	s0,32(sp)
ffffffffc0202008:	64e2                	ld	s1,24(sp)
ffffffffc020200a:	6145                	addi	sp,sp,48
ffffffffc020200c:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc020200e:	078a                	slli	a5,a5,0x2
ffffffffc0202010:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202012:	0000b717          	auipc	a4,0xb
ffffffffc0202016:	49e73703          	ld	a4,1182(a4) # ffffffffc020d4b0 <npage>
ffffffffc020201a:	06e7f363          	bgeu	a5,a4,ffffffffc0202080 <page_remove+0x98>
    return &pages[PPN(pa) - nbase];
ffffffffc020201e:	fff80537          	lui	a0,0xfff80
ffffffffc0202022:	97aa                	add	a5,a5,a0
ffffffffc0202024:	079a                	slli	a5,a5,0x6
ffffffffc0202026:	0000b517          	auipc	a0,0xb
ffffffffc020202a:	49253503          	ld	a0,1170(a0) # ffffffffc020d4b8 <pages>
ffffffffc020202e:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc0202030:	411c                	lw	a5,0(a0)
ffffffffc0202032:	fff7871b          	addiw	a4,a5,-1
ffffffffc0202036:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc0202038:	cb11                	beqz	a4,ffffffffc020204c <page_remove+0x64>
        *ptep = 0;                 // 2310675: (5) 清空页表项，标记为无效
ffffffffc020203a:	00043023          	sd	zero,0(s0)
// edited are the ones currently in use by the processor.
void tlb_invalidate(pde_t *pgdir, uintptr_t la)
{
    // flush_tlb();
    // The flush_tlb flush the entire TLB, is there any better way?
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020203e:	12048073          	sfence.vma	s1
}
ffffffffc0202042:	70a2                	ld	ra,40(sp)
ffffffffc0202044:	7402                	ld	s0,32(sp)
ffffffffc0202046:	64e2                	ld	s1,24(sp)
ffffffffc0202048:	6145                	addi	sp,sp,48
ffffffffc020204a:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020204c:	100027f3          	csrr	a5,sstatus
ffffffffc0202050:	8b89                	andi	a5,a5,2
ffffffffc0202052:	eb89                	bnez	a5,ffffffffc0202064 <page_remove+0x7c>
        pmm_manager->free_pages(base, n);
ffffffffc0202054:	0000b797          	auipc	a5,0xb
ffffffffc0202058:	46c7b783          	ld	a5,1132(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc020205c:	739c                	ld	a5,32(a5)
ffffffffc020205e:	4585                	li	a1,1
ffffffffc0202060:	9782                	jalr	a5
    if (flag) {
ffffffffc0202062:	bfe1                	j	ffffffffc020203a <page_remove+0x52>
        intr_disable();
ffffffffc0202064:	e42a                	sd	a0,8(sp)
ffffffffc0202066:	8cbfe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
ffffffffc020206a:	0000b797          	auipc	a5,0xb
ffffffffc020206e:	4567b783          	ld	a5,1110(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc0202072:	739c                	ld	a5,32(a5)
ffffffffc0202074:	6522                	ld	a0,8(sp)
ffffffffc0202076:	4585                	li	a1,1
ffffffffc0202078:	9782                	jalr	a5
        intr_enable();
ffffffffc020207a:	8b1fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc020207e:	bf75                	j	ffffffffc020203a <page_remove+0x52>
ffffffffc0202080:	bfdff0ef          	jal	ra,ffffffffc0201c7c <pa2page.part.0>

ffffffffc0202084 <page_insert>:
{
ffffffffc0202084:	7139                	addi	sp,sp,-64
ffffffffc0202086:	e852                	sd	s4,16(sp)
ffffffffc0202088:	8a32                	mv	s4,a2
ffffffffc020208a:	f822                	sd	s0,48(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);  // 2310675: 获取页表项指针，1表示如果不存在就创建
ffffffffc020208c:	4605                	li	a2,1
{
ffffffffc020208e:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);  // 2310675: 获取页表项指针，1表示如果不存在就创建
ffffffffc0202090:	85d2                	mv	a1,s4
{
ffffffffc0202092:	f426                	sd	s1,40(sp)
ffffffffc0202094:	fc06                	sd	ra,56(sp)
ffffffffc0202096:	f04a                	sd	s2,32(sp)
ffffffffc0202098:	ec4e                	sd	s3,24(sp)
ffffffffc020209a:	e456                	sd	s5,8(sp)
ffffffffc020209c:	84b6                	mv	s1,a3
    pte_t *ptep = get_pte(pgdir, la, 1);  // 2310675: 获取页表项指针，1表示如果不存在就创建
ffffffffc020209e:	ccfff0ef          	jal	ra,ffffffffc0201d6c <get_pte>
    if (ptep == NULL)  // 2310675: 如果分配页表失败（内存不足）
ffffffffc02020a2:	c961                	beqz	a0,ffffffffc0202172 <page_insert+0xee>
    page->ref += 1;
ffffffffc02020a4:	4014                	lw	a3,0(s0)
    if (*ptep & PTE_V)   // 2310675: 如果页表项已经有效（原先存在映射）
ffffffffc02020a6:	611c                	ld	a5,0(a0)
ffffffffc02020a8:	89aa                	mv	s3,a0
ffffffffc02020aa:	0016871b          	addiw	a4,a3,1
ffffffffc02020ae:	c018                	sw	a4,0(s0)
ffffffffc02020b0:	0017f713          	andi	a4,a5,1
ffffffffc02020b4:	ef05                	bnez	a4,ffffffffc02020ec <page_insert+0x68>
    return page - pages + nbase;
ffffffffc02020b6:	0000b717          	auipc	a4,0xb
ffffffffc02020ba:	40273703          	ld	a4,1026(a4) # ffffffffc020d4b8 <pages>
ffffffffc02020be:	8c19                	sub	s0,s0,a4
ffffffffc02020c0:	000807b7          	lui	a5,0x80
ffffffffc02020c4:	8419                	srai	s0,s0,0x6
ffffffffc02020c6:	943e                	add	s0,s0,a5
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc02020c8:	042a                	slli	s0,s0,0xa
ffffffffc02020ca:	8cc1                	or	s1,s1,s0
ffffffffc02020cc:	0014e493          	ori	s1,s1,1
    *ptep = pte_create(page2ppn(page), PTE_V | perm);  // 2310675: 创建新页表项，设置物理页号和权限
ffffffffc02020d0:	0099b023          	sd	s1,0(s3)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02020d4:	120a0073          	sfence.vma	s4
    return 0;
ffffffffc02020d8:	4501                	li	a0,0
}
ffffffffc02020da:	70e2                	ld	ra,56(sp)
ffffffffc02020dc:	7442                	ld	s0,48(sp)
ffffffffc02020de:	74a2                	ld	s1,40(sp)
ffffffffc02020e0:	7902                	ld	s2,32(sp)
ffffffffc02020e2:	69e2                	ld	s3,24(sp)
ffffffffc02020e4:	6a42                	ld	s4,16(sp)
ffffffffc02020e6:	6aa2                	ld	s5,8(sp)
ffffffffc02020e8:	6121                	addi	sp,sp,64
ffffffffc02020ea:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc02020ec:	078a                	slli	a5,a5,0x2
ffffffffc02020ee:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02020f0:	0000b717          	auipc	a4,0xb
ffffffffc02020f4:	3c073703          	ld	a4,960(a4) # ffffffffc020d4b0 <npage>
ffffffffc02020f8:	06e7ff63          	bgeu	a5,a4,ffffffffc0202176 <page_insert+0xf2>
    return &pages[PPN(pa) - nbase];
ffffffffc02020fc:	0000ba97          	auipc	s5,0xb
ffffffffc0202100:	3bca8a93          	addi	s5,s5,956 # ffffffffc020d4b8 <pages>
ffffffffc0202104:	000ab703          	ld	a4,0(s5)
ffffffffc0202108:	fff80937          	lui	s2,0xfff80
ffffffffc020210c:	993e                	add	s2,s2,a5
ffffffffc020210e:	091a                	slli	s2,s2,0x6
ffffffffc0202110:	993a                	add	s2,s2,a4
        if (p == page)  // 2310675: 如果原来就映射到同一个物理页
ffffffffc0202112:	01240c63          	beq	s0,s2,ffffffffc020212a <page_insert+0xa6>
    page->ref -= 1;
ffffffffc0202116:	00092783          	lw	a5,0(s2) # fffffffffff80000 <end+0x3fd72b14>
ffffffffc020211a:	fff7869b          	addiw	a3,a5,-1
ffffffffc020211e:	00d92023          	sw	a3,0(s2)
        if (page_ref(page) ==
ffffffffc0202122:	c691                	beqz	a3,ffffffffc020212e <page_insert+0xaa>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202124:	120a0073          	sfence.vma	s4
}
ffffffffc0202128:	bf59                	j	ffffffffc02020be <page_insert+0x3a>
ffffffffc020212a:	c014                	sw	a3,0(s0)
    return page->ref;
ffffffffc020212c:	bf49                	j	ffffffffc02020be <page_insert+0x3a>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020212e:	100027f3          	csrr	a5,sstatus
ffffffffc0202132:	8b89                	andi	a5,a5,2
ffffffffc0202134:	ef91                	bnez	a5,ffffffffc0202150 <page_insert+0xcc>
        pmm_manager->free_pages(base, n);
ffffffffc0202136:	0000b797          	auipc	a5,0xb
ffffffffc020213a:	38a7b783          	ld	a5,906(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc020213e:	739c                	ld	a5,32(a5)
ffffffffc0202140:	4585                	li	a1,1
ffffffffc0202142:	854a                	mv	a0,s2
ffffffffc0202144:	9782                	jalr	a5
    return page - pages + nbase;
ffffffffc0202146:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020214a:	120a0073          	sfence.vma	s4
ffffffffc020214e:	bf85                	j	ffffffffc02020be <page_insert+0x3a>
        intr_disable();
ffffffffc0202150:	fe0fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202154:	0000b797          	auipc	a5,0xb
ffffffffc0202158:	36c7b783          	ld	a5,876(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc020215c:	739c                	ld	a5,32(a5)
ffffffffc020215e:	4585                	li	a1,1
ffffffffc0202160:	854a                	mv	a0,s2
ffffffffc0202162:	9782                	jalr	a5
        intr_enable();
ffffffffc0202164:	fc6fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc0202168:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020216c:	120a0073          	sfence.vma	s4
ffffffffc0202170:	b7b9                	j	ffffffffc02020be <page_insert+0x3a>
        return -E_NO_MEM;
ffffffffc0202172:	5571                	li	a0,-4
ffffffffc0202174:	b79d                	j	ffffffffc02020da <page_insert+0x56>
ffffffffc0202176:	b07ff0ef          	jal	ra,ffffffffc0201c7c <pa2page.part.0>

ffffffffc020217a <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc020217a:	00003797          	auipc	a5,0x3
ffffffffc020217e:	bb678793          	addi	a5,a5,-1098 # ffffffffc0204d30 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202182:	638c                	ld	a1,0(a5)
{
ffffffffc0202184:	7159                	addi	sp,sp,-112
ffffffffc0202186:	f85a                	sd	s6,48(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202188:	00003517          	auipc	a0,0x3
ffffffffc020218c:	d0850513          	addi	a0,a0,-760 # ffffffffc0204e90 <default_pmm_manager+0x160>
    pmm_manager = &default_pmm_manager;
ffffffffc0202190:	0000bb17          	auipc	s6,0xb
ffffffffc0202194:	330b0b13          	addi	s6,s6,816 # ffffffffc020d4c0 <pmm_manager>
{
ffffffffc0202198:	f486                	sd	ra,104(sp)
ffffffffc020219a:	e8ca                	sd	s2,80(sp)
ffffffffc020219c:	e4ce                	sd	s3,72(sp)
ffffffffc020219e:	f0a2                	sd	s0,96(sp)
ffffffffc02021a0:	eca6                	sd	s1,88(sp)
ffffffffc02021a2:	e0d2                	sd	s4,64(sp)
ffffffffc02021a4:	fc56                	sd	s5,56(sp)
ffffffffc02021a6:	f45e                	sd	s7,40(sp)
ffffffffc02021a8:	f062                	sd	s8,32(sp)
ffffffffc02021aa:	ec66                	sd	s9,24(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc02021ac:	00fb3023          	sd	a5,0(s6)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02021b0:	fe5fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    pmm_manager->init();
ffffffffc02021b4:	000b3783          	ld	a5,0(s6)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02021b8:	0000b997          	auipc	s3,0xb
ffffffffc02021bc:	31098993          	addi	s3,s3,784 # ffffffffc020d4c8 <va_pa_offset>
    pmm_manager->init();
ffffffffc02021c0:	679c                	ld	a5,8(a5)
ffffffffc02021c2:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02021c4:	57f5                	li	a5,-3
ffffffffc02021c6:	07fa                	slli	a5,a5,0x1e
ffffffffc02021c8:	00f9b023          	sd	a5,0(s3)
    uint64_t mem_begin = get_memory_base();
ffffffffc02021cc:	f4afe0ef          	jal	ra,ffffffffc0200916 <get_memory_base>
ffffffffc02021d0:	892a                	mv	s2,a0
    uint64_t mem_size  = get_memory_size();
ffffffffc02021d2:	f4efe0ef          	jal	ra,ffffffffc0200920 <get_memory_size>
    if (mem_size == 0) {
ffffffffc02021d6:	200505e3          	beqz	a0,ffffffffc0202be0 <pmm_init+0xa66>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc02021da:	84aa                	mv	s1,a0
    cprintf("physcial memory map:\n");
ffffffffc02021dc:	00003517          	auipc	a0,0x3
ffffffffc02021e0:	cec50513          	addi	a0,a0,-788 # ffffffffc0204ec8 <default_pmm_manager+0x198>
ffffffffc02021e4:	fb1fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc02021e8:	00990433          	add	s0,s2,s1
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc02021ec:	fff40693          	addi	a3,s0,-1
ffffffffc02021f0:	864a                	mv	a2,s2
ffffffffc02021f2:	85a6                	mv	a1,s1
ffffffffc02021f4:	00003517          	auipc	a0,0x3
ffffffffc02021f8:	cec50513          	addi	a0,a0,-788 # ffffffffc0204ee0 <default_pmm_manager+0x1b0>
ffffffffc02021fc:	f99fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc0202200:	c8000737          	lui	a4,0xc8000
ffffffffc0202204:	87a2                	mv	a5,s0
ffffffffc0202206:	54876163          	bltu	a4,s0,ffffffffc0202748 <pmm_init+0x5ce>
ffffffffc020220a:	757d                	lui	a0,0xfffff
ffffffffc020220c:	0000c617          	auipc	a2,0xc
ffffffffc0202210:	2df60613          	addi	a2,a2,735 # ffffffffc020e4eb <end+0xfff>
ffffffffc0202214:	8e69                	and	a2,a2,a0
ffffffffc0202216:	0000b497          	auipc	s1,0xb
ffffffffc020221a:	29a48493          	addi	s1,s1,666 # ffffffffc020d4b0 <npage>
ffffffffc020221e:	00c7d513          	srli	a0,a5,0xc
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202222:	0000bb97          	auipc	s7,0xb
ffffffffc0202226:	296b8b93          	addi	s7,s7,662 # ffffffffc020d4b8 <pages>
    npage = maxpa / PGSIZE;
ffffffffc020222a:	e088                	sd	a0,0(s1)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc020222c:	00cbb023          	sd	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202230:	000807b7          	lui	a5,0x80
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202234:	86b2                	mv	a3,a2
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202236:	02f50863          	beq	a0,a5,ffffffffc0202266 <pmm_init+0xec>
ffffffffc020223a:	4781                	li	a5,0
ffffffffc020223c:	4585                	li	a1,1
ffffffffc020223e:	fff806b7          	lui	a3,0xfff80
        SetPageReserved(pages + i);
ffffffffc0202242:	00679513          	slli	a0,a5,0x6
ffffffffc0202246:	9532                	add	a0,a0,a2
ffffffffc0202248:	00850713          	addi	a4,a0,8 # fffffffffffff008 <end+0x3fdf1b1c>
ffffffffc020224c:	40b7302f          	amoor.d	zero,a1,(a4)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202250:	6088                	ld	a0,0(s1)
ffffffffc0202252:	0785                	addi	a5,a5,1
        SetPageReserved(pages + i);
ffffffffc0202254:	000bb603          	ld	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202258:	00d50733          	add	a4,a0,a3
ffffffffc020225c:	fee7e3e3          	bltu	a5,a4,ffffffffc0202242 <pmm_init+0xc8>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202260:	071a                	slli	a4,a4,0x6
ffffffffc0202262:	00e606b3          	add	a3,a2,a4
ffffffffc0202266:	c02007b7          	lui	a5,0xc0200
ffffffffc020226a:	2ef6ece3          	bltu	a3,a5,ffffffffc0202d62 <pmm_init+0xbe8>
ffffffffc020226e:	0009b583          	ld	a1,0(s3)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc0202272:	77fd                	lui	a5,0xfffff
ffffffffc0202274:	8c7d                	and	s0,s0,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202276:	8e8d                	sub	a3,a3,a1
    if (freemem < mem_end)
ffffffffc0202278:	5086eb63          	bltu	a3,s0,ffffffffc020278e <pmm_init+0x614>
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc020227c:	00003517          	auipc	a0,0x3
ffffffffc0202280:	c8c50513          	addi	a0,a0,-884 # ffffffffc0204f08 <default_pmm_manager+0x1d8>
ffffffffc0202284:	f11fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
}

static void check_alloc_page(void)
{
    pmm_manager->check();
ffffffffc0202288:	000b3783          	ld	a5,0(s6)
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc020228c:	0000b917          	auipc	s2,0xb
ffffffffc0202290:	21c90913          	addi	s2,s2,540 # ffffffffc020d4a8 <boot_pgdir_va>
    pmm_manager->check();
ffffffffc0202294:	7b9c                	ld	a5,48(a5)
ffffffffc0202296:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0202298:	00003517          	auipc	a0,0x3
ffffffffc020229c:	c8850513          	addi	a0,a0,-888 # ffffffffc0204f20 <default_pmm_manager+0x1f0>
ffffffffc02022a0:	ef5fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc02022a4:	00006697          	auipc	a3,0x6
ffffffffc02022a8:	d5c68693          	addi	a3,a3,-676 # ffffffffc0208000 <boot_page_table_sv39>
ffffffffc02022ac:	00d93023          	sd	a3,0(s2)
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc02022b0:	c02007b7          	lui	a5,0xc0200
ffffffffc02022b4:	28f6ebe3          	bltu	a3,a5,ffffffffc0202d4a <pmm_init+0xbd0>
ffffffffc02022b8:	0009b783          	ld	a5,0(s3)
ffffffffc02022bc:	8e9d                	sub	a3,a3,a5
ffffffffc02022be:	0000b797          	auipc	a5,0xb
ffffffffc02022c2:	1ed7b123          	sd	a3,482(a5) # ffffffffc020d4a0 <boot_pgdir_pa>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02022c6:	100027f3          	csrr	a5,sstatus
ffffffffc02022ca:	8b89                	andi	a5,a5,2
ffffffffc02022cc:	4a079763          	bnez	a5,ffffffffc020277a <pmm_init+0x600>
        ret = pmm_manager->nr_free_pages();
ffffffffc02022d0:	000b3783          	ld	a5,0(s6)
ffffffffc02022d4:	779c                	ld	a5,40(a5)
ffffffffc02022d6:	9782                	jalr	a5
ffffffffc02022d8:	842a                	mv	s0,a0
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store = nr_free_pages();

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc02022da:	6098                	ld	a4,0(s1)
ffffffffc02022dc:	c80007b7          	lui	a5,0xc8000
ffffffffc02022e0:	83b1                	srli	a5,a5,0xc
ffffffffc02022e2:	66e7e363          	bltu	a5,a4,ffffffffc0202948 <pmm_init+0x7ce>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc02022e6:	00093503          	ld	a0,0(s2)
ffffffffc02022ea:	62050f63          	beqz	a0,ffffffffc0202928 <pmm_init+0x7ae>
ffffffffc02022ee:	03451793          	slli	a5,a0,0x34
ffffffffc02022f2:	62079b63          	bnez	a5,ffffffffc0202928 <pmm_init+0x7ae>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc02022f6:	4601                	li	a2,0
ffffffffc02022f8:	4581                	li	a1,0
ffffffffc02022fa:	c9bff0ef          	jal	ra,ffffffffc0201f94 <get_page>
ffffffffc02022fe:	60051563          	bnez	a0,ffffffffc0202908 <pmm_init+0x78e>
ffffffffc0202302:	100027f3          	csrr	a5,sstatus
ffffffffc0202306:	8b89                	andi	a5,a5,2
ffffffffc0202308:	44079e63          	bnez	a5,ffffffffc0202764 <pmm_init+0x5ea>
        page = pmm_manager->alloc_pages(n);
ffffffffc020230c:	000b3783          	ld	a5,0(s6)
ffffffffc0202310:	4505                	li	a0,1
ffffffffc0202312:	6f9c                	ld	a5,24(a5)
ffffffffc0202314:	9782                	jalr	a5
ffffffffc0202316:	8a2a                	mv	s4,a0

    struct Page *p1, *p2;
    p1 = alloc_page();
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc0202318:	00093503          	ld	a0,0(s2)
ffffffffc020231c:	4681                	li	a3,0
ffffffffc020231e:	4601                	li	a2,0
ffffffffc0202320:	85d2                	mv	a1,s4
ffffffffc0202322:	d63ff0ef          	jal	ra,ffffffffc0202084 <page_insert>
ffffffffc0202326:	26051ae3          	bnez	a0,ffffffffc0202d9a <pmm_init+0xc20>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc020232a:	00093503          	ld	a0,0(s2)
ffffffffc020232e:	4601                	li	a2,0
ffffffffc0202330:	4581                	li	a1,0
ffffffffc0202332:	a3bff0ef          	jal	ra,ffffffffc0201d6c <get_pte>
ffffffffc0202336:	240502e3          	beqz	a0,ffffffffc0202d7a <pmm_init+0xc00>
    assert(pte2page(*ptep) == p1);
ffffffffc020233a:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V))
ffffffffc020233c:	0017f713          	andi	a4,a5,1
ffffffffc0202340:	5a070263          	beqz	a4,ffffffffc02028e4 <pmm_init+0x76a>
    if (PPN(pa) >= npage)
ffffffffc0202344:	6098                	ld	a4,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202346:	078a                	slli	a5,a5,0x2
ffffffffc0202348:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020234a:	58e7fb63          	bgeu	a5,a4,ffffffffc02028e0 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc020234e:	000bb683          	ld	a3,0(s7)
ffffffffc0202352:	fff80637          	lui	a2,0xfff80
ffffffffc0202356:	97b2                	add	a5,a5,a2
ffffffffc0202358:	079a                	slli	a5,a5,0x6
ffffffffc020235a:	97b6                	add	a5,a5,a3
ffffffffc020235c:	14fa17e3          	bne	s4,a5,ffffffffc0202caa <pmm_init+0xb30>
    assert(page_ref(p1) == 1);
ffffffffc0202360:	000a2683          	lw	a3,0(s4) # 80000 <kern_entry-0xffffffffc0180000>
ffffffffc0202364:	4785                	li	a5,1
ffffffffc0202366:	12f692e3          	bne	a3,a5,ffffffffc0202c8a <pmm_init+0xb10>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc020236a:	00093503          	ld	a0,0(s2)
ffffffffc020236e:	77fd                	lui	a5,0xfffff
ffffffffc0202370:	6114                	ld	a3,0(a0)
ffffffffc0202372:	068a                	slli	a3,a3,0x2
ffffffffc0202374:	8efd                	and	a3,a3,a5
ffffffffc0202376:	00c6d613          	srli	a2,a3,0xc
ffffffffc020237a:	0ee67ce3          	bgeu	a2,a4,ffffffffc0202c72 <pmm_init+0xaf8>
ffffffffc020237e:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202382:	96e2                	add	a3,a3,s8
ffffffffc0202384:	0006ba83          	ld	s5,0(a3)
ffffffffc0202388:	0a8a                	slli	s5,s5,0x2
ffffffffc020238a:	00fafab3          	and	s5,s5,a5
ffffffffc020238e:	00cad793          	srli	a5,s5,0xc
ffffffffc0202392:	0ce7f3e3          	bgeu	a5,a4,ffffffffc0202c58 <pmm_init+0xade>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202396:	4601                	li	a2,0
ffffffffc0202398:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc020239a:	9ae2                	add	s5,s5,s8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc020239c:	9d1ff0ef          	jal	ra,ffffffffc0201d6c <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02023a0:	0aa1                	addi	s5,s5,8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc02023a2:	55551363          	bne	a0,s5,ffffffffc02028e8 <pmm_init+0x76e>
ffffffffc02023a6:	100027f3          	csrr	a5,sstatus
ffffffffc02023aa:	8b89                	andi	a5,a5,2
ffffffffc02023ac:	3a079163          	bnez	a5,ffffffffc020274e <pmm_init+0x5d4>
        page = pmm_manager->alloc_pages(n);
ffffffffc02023b0:	000b3783          	ld	a5,0(s6)
ffffffffc02023b4:	4505                	li	a0,1
ffffffffc02023b6:	6f9c                	ld	a5,24(a5)
ffffffffc02023b8:	9782                	jalr	a5
ffffffffc02023ba:	8c2a                	mv	s8,a0

    p2 = alloc_page();
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc02023bc:	00093503          	ld	a0,0(s2)
ffffffffc02023c0:	46d1                	li	a3,20
ffffffffc02023c2:	6605                	lui	a2,0x1
ffffffffc02023c4:	85e2                	mv	a1,s8
ffffffffc02023c6:	cbfff0ef          	jal	ra,ffffffffc0202084 <page_insert>
ffffffffc02023ca:	060517e3          	bnez	a0,ffffffffc0202c38 <pmm_init+0xabe>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc02023ce:	00093503          	ld	a0,0(s2)
ffffffffc02023d2:	4601                	li	a2,0
ffffffffc02023d4:	6585                	lui	a1,0x1
ffffffffc02023d6:	997ff0ef          	jal	ra,ffffffffc0201d6c <get_pte>
ffffffffc02023da:	02050fe3          	beqz	a0,ffffffffc0202c18 <pmm_init+0xa9e>
    assert(*ptep & PTE_U);
ffffffffc02023de:	611c                	ld	a5,0(a0)
ffffffffc02023e0:	0107f713          	andi	a4,a5,16
ffffffffc02023e4:	7c070e63          	beqz	a4,ffffffffc0202bc0 <pmm_init+0xa46>
    assert(*ptep & PTE_W);
ffffffffc02023e8:	8b91                	andi	a5,a5,4
ffffffffc02023ea:	7a078b63          	beqz	a5,ffffffffc0202ba0 <pmm_init+0xa26>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc02023ee:	00093503          	ld	a0,0(s2)
ffffffffc02023f2:	611c                	ld	a5,0(a0)
ffffffffc02023f4:	8bc1                	andi	a5,a5,16
ffffffffc02023f6:	78078563          	beqz	a5,ffffffffc0202b80 <pmm_init+0xa06>
    assert(page_ref(p2) == 1);
ffffffffc02023fa:	000c2703          	lw	a4,0(s8) # ff0000 <kern_entry-0xffffffffbf210000>
ffffffffc02023fe:	4785                	li	a5,1
ffffffffc0202400:	76f71063          	bne	a4,a5,ffffffffc0202b60 <pmm_init+0x9e6>

    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc0202404:	4681                	li	a3,0
ffffffffc0202406:	6605                	lui	a2,0x1
ffffffffc0202408:	85d2                	mv	a1,s4
ffffffffc020240a:	c7bff0ef          	jal	ra,ffffffffc0202084 <page_insert>
ffffffffc020240e:	72051963          	bnez	a0,ffffffffc0202b40 <pmm_init+0x9c6>
    assert(page_ref(p1) == 2);
ffffffffc0202412:	000a2703          	lw	a4,0(s4)
ffffffffc0202416:	4789                	li	a5,2
ffffffffc0202418:	70f71463          	bne	a4,a5,ffffffffc0202b20 <pmm_init+0x9a6>
    assert(page_ref(p2) == 0);
ffffffffc020241c:	000c2783          	lw	a5,0(s8)
ffffffffc0202420:	6e079063          	bnez	a5,ffffffffc0202b00 <pmm_init+0x986>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202424:	00093503          	ld	a0,0(s2)
ffffffffc0202428:	4601                	li	a2,0
ffffffffc020242a:	6585                	lui	a1,0x1
ffffffffc020242c:	941ff0ef          	jal	ra,ffffffffc0201d6c <get_pte>
ffffffffc0202430:	6a050863          	beqz	a0,ffffffffc0202ae0 <pmm_init+0x966>
    assert(pte2page(*ptep) == p1);
ffffffffc0202434:	6118                	ld	a4,0(a0)
    if (!(pte & PTE_V))
ffffffffc0202436:	00177793          	andi	a5,a4,1
ffffffffc020243a:	4a078563          	beqz	a5,ffffffffc02028e4 <pmm_init+0x76a>
    if (PPN(pa) >= npage)
ffffffffc020243e:	6094                	ld	a3,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202440:	00271793          	slli	a5,a4,0x2
ffffffffc0202444:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202446:	48d7fd63          	bgeu	a5,a3,ffffffffc02028e0 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc020244a:	000bb683          	ld	a3,0(s7)
ffffffffc020244e:	fff80ab7          	lui	s5,0xfff80
ffffffffc0202452:	97d6                	add	a5,a5,s5
ffffffffc0202454:	079a                	slli	a5,a5,0x6
ffffffffc0202456:	97b6                	add	a5,a5,a3
ffffffffc0202458:	66fa1463          	bne	s4,a5,ffffffffc0202ac0 <pmm_init+0x946>
    assert((*ptep & PTE_U) == 0);
ffffffffc020245c:	8b41                	andi	a4,a4,16
ffffffffc020245e:	64071163          	bnez	a4,ffffffffc0202aa0 <pmm_init+0x926>

    page_remove(boot_pgdir_va, 0x0);
ffffffffc0202462:	00093503          	ld	a0,0(s2)
ffffffffc0202466:	4581                	li	a1,0
ffffffffc0202468:	b81ff0ef          	jal	ra,ffffffffc0201fe8 <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc020246c:	000a2c83          	lw	s9,0(s4)
ffffffffc0202470:	4785                	li	a5,1
ffffffffc0202472:	60fc9763          	bne	s9,a5,ffffffffc0202a80 <pmm_init+0x906>
    assert(page_ref(p2) == 0);
ffffffffc0202476:	000c2783          	lw	a5,0(s8)
ffffffffc020247a:	5e079363          	bnez	a5,ffffffffc0202a60 <pmm_init+0x8e6>

    page_remove(boot_pgdir_va, PGSIZE);
ffffffffc020247e:	00093503          	ld	a0,0(s2)
ffffffffc0202482:	6585                	lui	a1,0x1
ffffffffc0202484:	b65ff0ef          	jal	ra,ffffffffc0201fe8 <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc0202488:	000a2783          	lw	a5,0(s4)
ffffffffc020248c:	52079a63          	bnez	a5,ffffffffc02029c0 <pmm_init+0x846>
    assert(page_ref(p2) == 0);
ffffffffc0202490:	000c2783          	lw	a5,0(s8)
ffffffffc0202494:	50079663          	bnez	a5,ffffffffc02029a0 <pmm_init+0x826>

    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202498:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage)
ffffffffc020249c:	608c                	ld	a1,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc020249e:	000a3683          	ld	a3,0(s4)
ffffffffc02024a2:	068a                	slli	a3,a3,0x2
ffffffffc02024a4:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc02024a6:	42b6fd63          	bgeu	a3,a1,ffffffffc02028e0 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc02024aa:	000bb503          	ld	a0,0(s7)
ffffffffc02024ae:	96d6                	add	a3,a3,s5
ffffffffc02024b0:	069a                	slli	a3,a3,0x6
    return page->ref;
ffffffffc02024b2:	00d507b3          	add	a5,a0,a3
ffffffffc02024b6:	439c                	lw	a5,0(a5)
ffffffffc02024b8:	4d979463          	bne	a5,s9,ffffffffc0202980 <pmm_init+0x806>
    return page - pages + nbase;
ffffffffc02024bc:	8699                	srai	a3,a3,0x6
ffffffffc02024be:	00080637          	lui	a2,0x80
ffffffffc02024c2:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc02024c4:	00c69713          	slli	a4,a3,0xc
ffffffffc02024c8:	8331                	srli	a4,a4,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc02024ca:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02024cc:	48b77e63          	bgeu	a4,a1,ffffffffc0202968 <pmm_init+0x7ee>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
    free_page(pde2page(pd0[0]));
ffffffffc02024d0:	0009b703          	ld	a4,0(s3)
ffffffffc02024d4:	96ba                	add	a3,a3,a4
    return pa2page(PDE_ADDR(pde));
ffffffffc02024d6:	629c                	ld	a5,0(a3)
ffffffffc02024d8:	078a                	slli	a5,a5,0x2
ffffffffc02024da:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02024dc:	40b7f263          	bgeu	a5,a1,ffffffffc02028e0 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc02024e0:	8f91                	sub	a5,a5,a2
ffffffffc02024e2:	079a                	slli	a5,a5,0x6
ffffffffc02024e4:	953e                	add	a0,a0,a5
ffffffffc02024e6:	100027f3          	csrr	a5,sstatus
ffffffffc02024ea:	8b89                	andi	a5,a5,2
ffffffffc02024ec:	30079963          	bnez	a5,ffffffffc02027fe <pmm_init+0x684>
        pmm_manager->free_pages(base, n);
ffffffffc02024f0:	000b3783          	ld	a5,0(s6)
ffffffffc02024f4:	4585                	li	a1,1
ffffffffc02024f6:	739c                	ld	a5,32(a5)
ffffffffc02024f8:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc02024fa:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage)
ffffffffc02024fe:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202500:	078a                	slli	a5,a5,0x2
ffffffffc0202502:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202504:	3ce7fe63          	bgeu	a5,a4,ffffffffc02028e0 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202508:	000bb503          	ld	a0,0(s7)
ffffffffc020250c:	fff80737          	lui	a4,0xfff80
ffffffffc0202510:	97ba                	add	a5,a5,a4
ffffffffc0202512:	079a                	slli	a5,a5,0x6
ffffffffc0202514:	953e                	add	a0,a0,a5
ffffffffc0202516:	100027f3          	csrr	a5,sstatus
ffffffffc020251a:	8b89                	andi	a5,a5,2
ffffffffc020251c:	2c079563          	bnez	a5,ffffffffc02027e6 <pmm_init+0x66c>
ffffffffc0202520:	000b3783          	ld	a5,0(s6)
ffffffffc0202524:	4585                	li	a1,1
ffffffffc0202526:	739c                	ld	a5,32(a5)
ffffffffc0202528:	9782                	jalr	a5
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc020252a:	00093783          	ld	a5,0(s2)
ffffffffc020252e:	0007b023          	sd	zero,0(a5) # fffffffffffff000 <end+0x3fdf1b14>
    asm volatile("sfence.vma");
ffffffffc0202532:	12000073          	sfence.vma
ffffffffc0202536:	100027f3          	csrr	a5,sstatus
ffffffffc020253a:	8b89                	andi	a5,a5,2
ffffffffc020253c:	28079b63          	bnez	a5,ffffffffc02027d2 <pmm_init+0x658>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202540:	000b3783          	ld	a5,0(s6)
ffffffffc0202544:	779c                	ld	a5,40(a5)
ffffffffc0202546:	9782                	jalr	a5
ffffffffc0202548:	8a2a                	mv	s4,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc020254a:	4b441b63          	bne	s0,s4,ffffffffc0202a00 <pmm_init+0x886>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc020254e:	00003517          	auipc	a0,0x3
ffffffffc0202552:	cfa50513          	addi	a0,a0,-774 # ffffffffc0205248 <default_pmm_manager+0x518>
ffffffffc0202556:	c3ffd0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc020255a:	100027f3          	csrr	a5,sstatus
ffffffffc020255e:	8b89                	andi	a5,a5,2
ffffffffc0202560:	24079f63          	bnez	a5,ffffffffc02027be <pmm_init+0x644>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202564:	000b3783          	ld	a5,0(s6)
ffffffffc0202568:	779c                	ld	a5,40(a5)
ffffffffc020256a:	9782                	jalr	a5
ffffffffc020256c:	8c2a                	mv	s8,a0
    pte_t *ptep;
    int i;

    nr_free_store = nr_free_pages();

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc020256e:	6098                	ld	a4,0(s1)
ffffffffc0202570:	c0200437          	lui	s0,0xc0200
    {
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202574:	7afd                	lui	s5,0xfffff
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202576:	00c71793          	slli	a5,a4,0xc
ffffffffc020257a:	6a05                	lui	s4,0x1
ffffffffc020257c:	02f47c63          	bgeu	s0,a5,ffffffffc02025b4 <pmm_init+0x43a>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202580:	00c45793          	srli	a5,s0,0xc
ffffffffc0202584:	00093503          	ld	a0,0(s2)
ffffffffc0202588:	2ee7ff63          	bgeu	a5,a4,ffffffffc0202886 <pmm_init+0x70c>
ffffffffc020258c:	0009b583          	ld	a1,0(s3)
ffffffffc0202590:	4601                	li	a2,0
ffffffffc0202592:	95a2                	add	a1,a1,s0
ffffffffc0202594:	fd8ff0ef          	jal	ra,ffffffffc0201d6c <get_pte>
ffffffffc0202598:	32050463          	beqz	a0,ffffffffc02028c0 <pmm_init+0x746>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc020259c:	611c                	ld	a5,0(a0)
ffffffffc020259e:	078a                	slli	a5,a5,0x2
ffffffffc02025a0:	0157f7b3          	and	a5,a5,s5
ffffffffc02025a4:	2e879e63          	bne	a5,s0,ffffffffc02028a0 <pmm_init+0x726>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc02025a8:	6098                	ld	a4,0(s1)
ffffffffc02025aa:	9452                	add	s0,s0,s4
ffffffffc02025ac:	00c71793          	slli	a5,a4,0xc
ffffffffc02025b0:	fcf468e3          	bltu	s0,a5,ffffffffc0202580 <pmm_init+0x406>
    }

    assert(boot_pgdir_va[0] == 0);
ffffffffc02025b4:	00093783          	ld	a5,0(s2)
ffffffffc02025b8:	639c                	ld	a5,0(a5)
ffffffffc02025ba:	42079363          	bnez	a5,ffffffffc02029e0 <pmm_init+0x866>
ffffffffc02025be:	100027f3          	csrr	a5,sstatus
ffffffffc02025c2:	8b89                	andi	a5,a5,2
ffffffffc02025c4:	24079963          	bnez	a5,ffffffffc0202816 <pmm_init+0x69c>
        page = pmm_manager->alloc_pages(n);
ffffffffc02025c8:	000b3783          	ld	a5,0(s6)
ffffffffc02025cc:	4505                	li	a0,1
ffffffffc02025ce:	6f9c                	ld	a5,24(a5)
ffffffffc02025d0:	9782                	jalr	a5
ffffffffc02025d2:	8a2a                	mv	s4,a0

    struct Page *p;
    p = alloc_page();
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc02025d4:	00093503          	ld	a0,0(s2)
ffffffffc02025d8:	4699                	li	a3,6
ffffffffc02025da:	10000613          	li	a2,256
ffffffffc02025de:	85d2                	mv	a1,s4
ffffffffc02025e0:	aa5ff0ef          	jal	ra,ffffffffc0202084 <page_insert>
ffffffffc02025e4:	44051e63          	bnez	a0,ffffffffc0202a40 <pmm_init+0x8c6>
    assert(page_ref(p) == 1);
ffffffffc02025e8:	000a2703          	lw	a4,0(s4) # 1000 <kern_entry-0xffffffffc01ff000>
ffffffffc02025ec:	4785                	li	a5,1
ffffffffc02025ee:	42f71963          	bne	a4,a5,ffffffffc0202a20 <pmm_init+0x8a6>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc02025f2:	00093503          	ld	a0,0(s2)
ffffffffc02025f6:	6405                	lui	s0,0x1
ffffffffc02025f8:	4699                	li	a3,6
ffffffffc02025fa:	10040613          	addi	a2,s0,256 # 1100 <kern_entry-0xffffffffc01fef00>
ffffffffc02025fe:	85d2                	mv	a1,s4
ffffffffc0202600:	a85ff0ef          	jal	ra,ffffffffc0202084 <page_insert>
ffffffffc0202604:	72051363          	bnez	a0,ffffffffc0202d2a <pmm_init+0xbb0>
    assert(page_ref(p) == 2);
ffffffffc0202608:	000a2703          	lw	a4,0(s4)
ffffffffc020260c:	4789                	li	a5,2
ffffffffc020260e:	6ef71e63          	bne	a4,a5,ffffffffc0202d0a <pmm_init+0xb90>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc0202612:	00003597          	auipc	a1,0x3
ffffffffc0202616:	d7e58593          	addi	a1,a1,-642 # ffffffffc0205390 <default_pmm_manager+0x660>
ffffffffc020261a:	10000513          	li	a0,256
ffffffffc020261e:	009010ef          	jal	ra,ffffffffc0203e26 <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0202622:	10040593          	addi	a1,s0,256
ffffffffc0202626:	10000513          	li	a0,256
ffffffffc020262a:	00f010ef          	jal	ra,ffffffffc0203e38 <strcmp>
ffffffffc020262e:	6a051e63          	bnez	a0,ffffffffc0202cea <pmm_init+0xb70>
    return page - pages + nbase;
ffffffffc0202632:	000bb683          	ld	a3,0(s7)
ffffffffc0202636:	00080737          	lui	a4,0x80
    return KADDR(page2pa(page));
ffffffffc020263a:	547d                	li	s0,-1
    return page - pages + nbase;
ffffffffc020263c:	40da06b3          	sub	a3,s4,a3
ffffffffc0202640:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0202642:	609c                	ld	a5,0(s1)
    return page - pages + nbase;
ffffffffc0202644:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc0202646:	8031                	srli	s0,s0,0xc
ffffffffc0202648:	0086f733          	and	a4,a3,s0
    return page2ppn(page) << PGSHIFT;
ffffffffc020264c:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc020264e:	30f77d63          	bgeu	a4,a5,ffffffffc0202968 <pmm_init+0x7ee>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202652:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202656:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc020265a:	96be                	add	a3,a3,a5
ffffffffc020265c:	10068023          	sb	zero,256(a3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202660:	790010ef          	jal	ra,ffffffffc0203df0 <strlen>
ffffffffc0202664:	66051363          	bnez	a0,ffffffffc0202cca <pmm_init+0xb50>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
ffffffffc0202668:	00093a83          	ld	s5,0(s2)
    if (PPN(pa) >= npage)
ffffffffc020266c:	609c                	ld	a5,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc020266e:	000ab683          	ld	a3,0(s5) # fffffffffffff000 <end+0x3fdf1b14>
ffffffffc0202672:	068a                	slli	a3,a3,0x2
ffffffffc0202674:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc0202676:	26f6f563          	bgeu	a3,a5,ffffffffc02028e0 <pmm_init+0x766>
    return KADDR(page2pa(page));
ffffffffc020267a:	8c75                	and	s0,s0,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc020267c:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc020267e:	2ef47563          	bgeu	s0,a5,ffffffffc0202968 <pmm_init+0x7ee>
ffffffffc0202682:	0009b403          	ld	s0,0(s3)
ffffffffc0202686:	9436                	add	s0,s0,a3
ffffffffc0202688:	100027f3          	csrr	a5,sstatus
ffffffffc020268c:	8b89                	andi	a5,a5,2
ffffffffc020268e:	1e079163          	bnez	a5,ffffffffc0202870 <pmm_init+0x6f6>
        pmm_manager->free_pages(base, n);
ffffffffc0202692:	000b3783          	ld	a5,0(s6)
ffffffffc0202696:	4585                	li	a1,1
ffffffffc0202698:	8552                	mv	a0,s4
ffffffffc020269a:	739c                	ld	a5,32(a5)
ffffffffc020269c:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc020269e:	601c                	ld	a5,0(s0)
    if (PPN(pa) >= npage)
ffffffffc02026a0:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc02026a2:	078a                	slli	a5,a5,0x2
ffffffffc02026a4:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02026a6:	22e7fd63          	bgeu	a5,a4,ffffffffc02028e0 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc02026aa:	000bb503          	ld	a0,0(s7)
ffffffffc02026ae:	fff80737          	lui	a4,0xfff80
ffffffffc02026b2:	97ba                	add	a5,a5,a4
ffffffffc02026b4:	079a                	slli	a5,a5,0x6
ffffffffc02026b6:	953e                	add	a0,a0,a5
ffffffffc02026b8:	100027f3          	csrr	a5,sstatus
ffffffffc02026bc:	8b89                	andi	a5,a5,2
ffffffffc02026be:	18079d63          	bnez	a5,ffffffffc0202858 <pmm_init+0x6de>
ffffffffc02026c2:	000b3783          	ld	a5,0(s6)
ffffffffc02026c6:	4585                	li	a1,1
ffffffffc02026c8:	739c                	ld	a5,32(a5)
ffffffffc02026ca:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc02026cc:	000ab783          	ld	a5,0(s5)
    if (PPN(pa) >= npage)
ffffffffc02026d0:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc02026d2:	078a                	slli	a5,a5,0x2
ffffffffc02026d4:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02026d6:	20e7f563          	bgeu	a5,a4,ffffffffc02028e0 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc02026da:	000bb503          	ld	a0,0(s7)
ffffffffc02026de:	fff80737          	lui	a4,0xfff80
ffffffffc02026e2:	97ba                	add	a5,a5,a4
ffffffffc02026e4:	079a                	slli	a5,a5,0x6
ffffffffc02026e6:	953e                	add	a0,a0,a5
ffffffffc02026e8:	100027f3          	csrr	a5,sstatus
ffffffffc02026ec:	8b89                	andi	a5,a5,2
ffffffffc02026ee:	14079963          	bnez	a5,ffffffffc0202840 <pmm_init+0x6c6>
ffffffffc02026f2:	000b3783          	ld	a5,0(s6)
ffffffffc02026f6:	4585                	li	a1,1
ffffffffc02026f8:	739c                	ld	a5,32(a5)
ffffffffc02026fa:	9782                	jalr	a5
    free_page(p);
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc02026fc:	00093783          	ld	a5,0(s2)
ffffffffc0202700:	0007b023          	sd	zero,0(a5)
    asm volatile("sfence.vma");
ffffffffc0202704:	12000073          	sfence.vma
ffffffffc0202708:	100027f3          	csrr	a5,sstatus
ffffffffc020270c:	8b89                	andi	a5,a5,2
ffffffffc020270e:	10079f63          	bnez	a5,ffffffffc020282c <pmm_init+0x6b2>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202712:	000b3783          	ld	a5,0(s6)
ffffffffc0202716:	779c                	ld	a5,40(a5)
ffffffffc0202718:	9782                	jalr	a5
ffffffffc020271a:	842a                	mv	s0,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc020271c:	4c8c1e63          	bne	s8,s0,ffffffffc0202bf8 <pmm_init+0xa7e>

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc0202720:	00003517          	auipc	a0,0x3
ffffffffc0202724:	ce850513          	addi	a0,a0,-792 # ffffffffc0205408 <default_pmm_manager+0x6d8>
ffffffffc0202728:	a6dfd0ef          	jal	ra,ffffffffc0200194 <cprintf>
}
ffffffffc020272c:	7406                	ld	s0,96(sp)
ffffffffc020272e:	70a6                	ld	ra,104(sp)
ffffffffc0202730:	64e6                	ld	s1,88(sp)
ffffffffc0202732:	6946                	ld	s2,80(sp)
ffffffffc0202734:	69a6                	ld	s3,72(sp)
ffffffffc0202736:	6a06                	ld	s4,64(sp)
ffffffffc0202738:	7ae2                	ld	s5,56(sp)
ffffffffc020273a:	7b42                	ld	s6,48(sp)
ffffffffc020273c:	7ba2                	ld	s7,40(sp)
ffffffffc020273e:	7c02                	ld	s8,32(sp)
ffffffffc0202740:	6ce2                	ld	s9,24(sp)
ffffffffc0202742:	6165                	addi	sp,sp,112
    kmalloc_init();
ffffffffc0202744:	b72ff06f          	j	ffffffffc0201ab6 <kmalloc_init>
    npage = maxpa / PGSIZE;
ffffffffc0202748:	c80007b7          	lui	a5,0xc8000
ffffffffc020274c:	bc7d                	j	ffffffffc020220a <pmm_init+0x90>
        intr_disable();
ffffffffc020274e:	9e2fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202752:	000b3783          	ld	a5,0(s6)
ffffffffc0202756:	4505                	li	a0,1
ffffffffc0202758:	6f9c                	ld	a5,24(a5)
ffffffffc020275a:	9782                	jalr	a5
ffffffffc020275c:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc020275e:	9ccfe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc0202762:	b9a9                	j	ffffffffc02023bc <pmm_init+0x242>
        intr_disable();
ffffffffc0202764:	9ccfe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
ffffffffc0202768:	000b3783          	ld	a5,0(s6)
ffffffffc020276c:	4505                	li	a0,1
ffffffffc020276e:	6f9c                	ld	a5,24(a5)
ffffffffc0202770:	9782                	jalr	a5
ffffffffc0202772:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202774:	9b6fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc0202778:	b645                	j	ffffffffc0202318 <pmm_init+0x19e>
        intr_disable();
ffffffffc020277a:	9b6fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc020277e:	000b3783          	ld	a5,0(s6)
ffffffffc0202782:	779c                	ld	a5,40(a5)
ffffffffc0202784:	9782                	jalr	a5
ffffffffc0202786:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202788:	9a2fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc020278c:	b6b9                	j	ffffffffc02022da <pmm_init+0x160>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc020278e:	6705                	lui	a4,0x1
ffffffffc0202790:	177d                	addi	a4,a4,-1
ffffffffc0202792:	96ba                	add	a3,a3,a4
ffffffffc0202794:	8ff5                	and	a5,a5,a3
    if (PPN(pa) >= npage)
ffffffffc0202796:	00c7d713          	srli	a4,a5,0xc
ffffffffc020279a:	14a77363          	bgeu	a4,a0,ffffffffc02028e0 <pmm_init+0x766>
    pmm_manager->init_memmap(base, n);
ffffffffc020279e:	000b3683          	ld	a3,0(s6)
    return &pages[PPN(pa) - nbase];
ffffffffc02027a2:	fff80537          	lui	a0,0xfff80
ffffffffc02027a6:	972a                	add	a4,a4,a0
ffffffffc02027a8:	6a94                	ld	a3,16(a3)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc02027aa:	8c1d                	sub	s0,s0,a5
ffffffffc02027ac:	00671513          	slli	a0,a4,0x6
    pmm_manager->init_memmap(base, n);
ffffffffc02027b0:	00c45593          	srli	a1,s0,0xc
ffffffffc02027b4:	9532                	add	a0,a0,a2
ffffffffc02027b6:	9682                	jalr	a3
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc02027b8:	0009b583          	ld	a1,0(s3)
}
ffffffffc02027bc:	b4c1                	j	ffffffffc020227c <pmm_init+0x102>
        intr_disable();
ffffffffc02027be:	972fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc02027c2:	000b3783          	ld	a5,0(s6)
ffffffffc02027c6:	779c                	ld	a5,40(a5)
ffffffffc02027c8:	9782                	jalr	a5
ffffffffc02027ca:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc02027cc:	95efe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc02027d0:	bb79                	j	ffffffffc020256e <pmm_init+0x3f4>
        intr_disable();
ffffffffc02027d2:	95efe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
ffffffffc02027d6:	000b3783          	ld	a5,0(s6)
ffffffffc02027da:	779c                	ld	a5,40(a5)
ffffffffc02027dc:	9782                	jalr	a5
ffffffffc02027de:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc02027e0:	94afe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc02027e4:	b39d                	j	ffffffffc020254a <pmm_init+0x3d0>
ffffffffc02027e6:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02027e8:	948fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02027ec:	000b3783          	ld	a5,0(s6)
ffffffffc02027f0:	6522                	ld	a0,8(sp)
ffffffffc02027f2:	4585                	li	a1,1
ffffffffc02027f4:	739c                	ld	a5,32(a5)
ffffffffc02027f6:	9782                	jalr	a5
        intr_enable();
ffffffffc02027f8:	932fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc02027fc:	b33d                	j	ffffffffc020252a <pmm_init+0x3b0>
ffffffffc02027fe:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202800:	930fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
ffffffffc0202804:	000b3783          	ld	a5,0(s6)
ffffffffc0202808:	6522                	ld	a0,8(sp)
ffffffffc020280a:	4585                	li	a1,1
ffffffffc020280c:	739c                	ld	a5,32(a5)
ffffffffc020280e:	9782                	jalr	a5
        intr_enable();
ffffffffc0202810:	91afe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc0202814:	b1dd                	j	ffffffffc02024fa <pmm_init+0x380>
        intr_disable();
ffffffffc0202816:	91afe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc020281a:	000b3783          	ld	a5,0(s6)
ffffffffc020281e:	4505                	li	a0,1
ffffffffc0202820:	6f9c                	ld	a5,24(a5)
ffffffffc0202822:	9782                	jalr	a5
ffffffffc0202824:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202826:	904fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc020282a:	b36d                	j	ffffffffc02025d4 <pmm_init+0x45a>
        intr_disable();
ffffffffc020282c:	904fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202830:	000b3783          	ld	a5,0(s6)
ffffffffc0202834:	779c                	ld	a5,40(a5)
ffffffffc0202836:	9782                	jalr	a5
ffffffffc0202838:	842a                	mv	s0,a0
        intr_enable();
ffffffffc020283a:	8f0fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc020283e:	bdf9                	j	ffffffffc020271c <pmm_init+0x5a2>
ffffffffc0202840:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202842:	8eefe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202846:	000b3783          	ld	a5,0(s6)
ffffffffc020284a:	6522                	ld	a0,8(sp)
ffffffffc020284c:	4585                	li	a1,1
ffffffffc020284e:	739c                	ld	a5,32(a5)
ffffffffc0202850:	9782                	jalr	a5
        intr_enable();
ffffffffc0202852:	8d8fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc0202856:	b55d                	j	ffffffffc02026fc <pmm_init+0x582>
ffffffffc0202858:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc020285a:	8d6fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
ffffffffc020285e:	000b3783          	ld	a5,0(s6)
ffffffffc0202862:	6522                	ld	a0,8(sp)
ffffffffc0202864:	4585                	li	a1,1
ffffffffc0202866:	739c                	ld	a5,32(a5)
ffffffffc0202868:	9782                	jalr	a5
        intr_enable();
ffffffffc020286a:	8c0fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc020286e:	bdb9                	j	ffffffffc02026cc <pmm_init+0x552>
        intr_disable();
ffffffffc0202870:	8c0fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
ffffffffc0202874:	000b3783          	ld	a5,0(s6)
ffffffffc0202878:	4585                	li	a1,1
ffffffffc020287a:	8552                	mv	a0,s4
ffffffffc020287c:	739c                	ld	a5,32(a5)
ffffffffc020287e:	9782                	jalr	a5
        intr_enable();
ffffffffc0202880:	8aafe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc0202884:	bd29                	j	ffffffffc020269e <pmm_init+0x524>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202886:	86a2                	mv	a3,s0
ffffffffc0202888:	00002617          	auipc	a2,0x2
ffffffffc020288c:	4e060613          	addi	a2,a2,1248 # ffffffffc0204d68 <default_pmm_manager+0x38>
ffffffffc0202890:	1ac00593          	li	a1,428
ffffffffc0202894:	00002517          	auipc	a0,0x2
ffffffffc0202898:	5ec50513          	addi	a0,a0,1516 # ffffffffc0204e80 <default_pmm_manager+0x150>
ffffffffc020289c:	bbffd0ef          	jal	ra,ffffffffc020045a <__panic>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc02028a0:	00003697          	auipc	a3,0x3
ffffffffc02028a4:	a0868693          	addi	a3,a3,-1528 # ffffffffc02052a8 <default_pmm_manager+0x578>
ffffffffc02028a8:	00002617          	auipc	a2,0x2
ffffffffc02028ac:	0d860613          	addi	a2,a2,216 # ffffffffc0204980 <commands+0x838>
ffffffffc02028b0:	1ad00593          	li	a1,429
ffffffffc02028b4:	00002517          	auipc	a0,0x2
ffffffffc02028b8:	5cc50513          	addi	a0,a0,1484 # ffffffffc0204e80 <default_pmm_manager+0x150>
ffffffffc02028bc:	b9ffd0ef          	jal	ra,ffffffffc020045a <__panic>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc02028c0:	00003697          	auipc	a3,0x3
ffffffffc02028c4:	9a868693          	addi	a3,a3,-1624 # ffffffffc0205268 <default_pmm_manager+0x538>
ffffffffc02028c8:	00002617          	auipc	a2,0x2
ffffffffc02028cc:	0b860613          	addi	a2,a2,184 # ffffffffc0204980 <commands+0x838>
ffffffffc02028d0:	1ac00593          	li	a1,428
ffffffffc02028d4:	00002517          	auipc	a0,0x2
ffffffffc02028d8:	5ac50513          	addi	a0,a0,1452 # ffffffffc0204e80 <default_pmm_manager+0x150>
ffffffffc02028dc:	b7ffd0ef          	jal	ra,ffffffffc020045a <__panic>
ffffffffc02028e0:	b9cff0ef          	jal	ra,ffffffffc0201c7c <pa2page.part.0>
ffffffffc02028e4:	bb4ff0ef          	jal	ra,ffffffffc0201c98 <pte2page.part.0>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc02028e8:	00002697          	auipc	a3,0x2
ffffffffc02028ec:	77868693          	addi	a3,a3,1912 # ffffffffc0205060 <default_pmm_manager+0x330>
ffffffffc02028f0:	00002617          	auipc	a2,0x2
ffffffffc02028f4:	09060613          	addi	a2,a2,144 # ffffffffc0204980 <commands+0x838>
ffffffffc02028f8:	17c00593          	li	a1,380
ffffffffc02028fc:	00002517          	auipc	a0,0x2
ffffffffc0202900:	58450513          	addi	a0,a0,1412 # ffffffffc0204e80 <default_pmm_manager+0x150>
ffffffffc0202904:	b57fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc0202908:	00002697          	auipc	a3,0x2
ffffffffc020290c:	69868693          	addi	a3,a3,1688 # ffffffffc0204fa0 <default_pmm_manager+0x270>
ffffffffc0202910:	00002617          	auipc	a2,0x2
ffffffffc0202914:	07060613          	addi	a2,a2,112 # ffffffffc0204980 <commands+0x838>
ffffffffc0202918:	16f00593          	li	a1,367
ffffffffc020291c:	00002517          	auipc	a0,0x2
ffffffffc0202920:	56450513          	addi	a0,a0,1380 # ffffffffc0204e80 <default_pmm_manager+0x150>
ffffffffc0202924:	b37fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc0202928:	00002697          	auipc	a3,0x2
ffffffffc020292c:	63868693          	addi	a3,a3,1592 # ffffffffc0204f60 <default_pmm_manager+0x230>
ffffffffc0202930:	00002617          	auipc	a2,0x2
ffffffffc0202934:	05060613          	addi	a2,a2,80 # ffffffffc0204980 <commands+0x838>
ffffffffc0202938:	16e00593          	li	a1,366
ffffffffc020293c:	00002517          	auipc	a0,0x2
ffffffffc0202940:	54450513          	addi	a0,a0,1348 # ffffffffc0204e80 <default_pmm_manager+0x150>
ffffffffc0202944:	b17fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0202948:	00002697          	auipc	a3,0x2
ffffffffc020294c:	5f868693          	addi	a3,a3,1528 # ffffffffc0204f40 <default_pmm_manager+0x210>
ffffffffc0202950:	00002617          	auipc	a2,0x2
ffffffffc0202954:	03060613          	addi	a2,a2,48 # ffffffffc0204980 <commands+0x838>
ffffffffc0202958:	16d00593          	li	a1,365
ffffffffc020295c:	00002517          	auipc	a0,0x2
ffffffffc0202960:	52450513          	addi	a0,a0,1316 # ffffffffc0204e80 <default_pmm_manager+0x150>
ffffffffc0202964:	af7fd0ef          	jal	ra,ffffffffc020045a <__panic>
    return KADDR(page2pa(page));
ffffffffc0202968:	00002617          	auipc	a2,0x2
ffffffffc020296c:	40060613          	addi	a2,a2,1024 # ffffffffc0204d68 <default_pmm_manager+0x38>
ffffffffc0202970:	07100593          	li	a1,113
ffffffffc0202974:	00002517          	auipc	a0,0x2
ffffffffc0202978:	41c50513          	addi	a0,a0,1052 # ffffffffc0204d90 <default_pmm_manager+0x60>
ffffffffc020297c:	adffd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202980:	00003697          	auipc	a3,0x3
ffffffffc0202984:	87068693          	addi	a3,a3,-1936 # ffffffffc02051f0 <default_pmm_manager+0x4c0>
ffffffffc0202988:	00002617          	auipc	a2,0x2
ffffffffc020298c:	ff860613          	addi	a2,a2,-8 # ffffffffc0204980 <commands+0x838>
ffffffffc0202990:	19500593          	li	a1,405
ffffffffc0202994:	00002517          	auipc	a0,0x2
ffffffffc0202998:	4ec50513          	addi	a0,a0,1260 # ffffffffc0204e80 <default_pmm_manager+0x150>
ffffffffc020299c:	abffd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p2) == 0);
ffffffffc02029a0:	00003697          	auipc	a3,0x3
ffffffffc02029a4:	80868693          	addi	a3,a3,-2040 # ffffffffc02051a8 <default_pmm_manager+0x478>
ffffffffc02029a8:	00002617          	auipc	a2,0x2
ffffffffc02029ac:	fd860613          	addi	a2,a2,-40 # ffffffffc0204980 <commands+0x838>
ffffffffc02029b0:	19300593          	li	a1,403
ffffffffc02029b4:	00002517          	auipc	a0,0x2
ffffffffc02029b8:	4cc50513          	addi	a0,a0,1228 # ffffffffc0204e80 <default_pmm_manager+0x150>
ffffffffc02029bc:	a9ffd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p1) == 0);
ffffffffc02029c0:	00003697          	auipc	a3,0x3
ffffffffc02029c4:	81868693          	addi	a3,a3,-2024 # ffffffffc02051d8 <default_pmm_manager+0x4a8>
ffffffffc02029c8:	00002617          	auipc	a2,0x2
ffffffffc02029cc:	fb860613          	addi	a2,a2,-72 # ffffffffc0204980 <commands+0x838>
ffffffffc02029d0:	19200593          	li	a1,402
ffffffffc02029d4:	00002517          	auipc	a0,0x2
ffffffffc02029d8:	4ac50513          	addi	a0,a0,1196 # ffffffffc0204e80 <default_pmm_manager+0x150>
ffffffffc02029dc:	a7ffd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(boot_pgdir_va[0] == 0);
ffffffffc02029e0:	00003697          	auipc	a3,0x3
ffffffffc02029e4:	8e068693          	addi	a3,a3,-1824 # ffffffffc02052c0 <default_pmm_manager+0x590>
ffffffffc02029e8:	00002617          	auipc	a2,0x2
ffffffffc02029ec:	f9860613          	addi	a2,a2,-104 # ffffffffc0204980 <commands+0x838>
ffffffffc02029f0:	1b000593          	li	a1,432
ffffffffc02029f4:	00002517          	auipc	a0,0x2
ffffffffc02029f8:	48c50513          	addi	a0,a0,1164 # ffffffffc0204e80 <default_pmm_manager+0x150>
ffffffffc02029fc:	a5ffd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc0202a00:	00003697          	auipc	a3,0x3
ffffffffc0202a04:	82068693          	addi	a3,a3,-2016 # ffffffffc0205220 <default_pmm_manager+0x4f0>
ffffffffc0202a08:	00002617          	auipc	a2,0x2
ffffffffc0202a0c:	f7860613          	addi	a2,a2,-136 # ffffffffc0204980 <commands+0x838>
ffffffffc0202a10:	19d00593          	li	a1,413
ffffffffc0202a14:	00002517          	auipc	a0,0x2
ffffffffc0202a18:	46c50513          	addi	a0,a0,1132 # ffffffffc0204e80 <default_pmm_manager+0x150>
ffffffffc0202a1c:	a3ffd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p) == 1);
ffffffffc0202a20:	00003697          	auipc	a3,0x3
ffffffffc0202a24:	8f868693          	addi	a3,a3,-1800 # ffffffffc0205318 <default_pmm_manager+0x5e8>
ffffffffc0202a28:	00002617          	auipc	a2,0x2
ffffffffc0202a2c:	f5860613          	addi	a2,a2,-168 # ffffffffc0204980 <commands+0x838>
ffffffffc0202a30:	1b500593          	li	a1,437
ffffffffc0202a34:	00002517          	auipc	a0,0x2
ffffffffc0202a38:	44c50513          	addi	a0,a0,1100 # ffffffffc0204e80 <default_pmm_manager+0x150>
ffffffffc0202a3c:	a1ffd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202a40:	00003697          	auipc	a3,0x3
ffffffffc0202a44:	89868693          	addi	a3,a3,-1896 # ffffffffc02052d8 <default_pmm_manager+0x5a8>
ffffffffc0202a48:	00002617          	auipc	a2,0x2
ffffffffc0202a4c:	f3860613          	addi	a2,a2,-200 # ffffffffc0204980 <commands+0x838>
ffffffffc0202a50:	1b400593          	li	a1,436
ffffffffc0202a54:	00002517          	auipc	a0,0x2
ffffffffc0202a58:	42c50513          	addi	a0,a0,1068 # ffffffffc0204e80 <default_pmm_manager+0x150>
ffffffffc0202a5c:	9fffd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202a60:	00002697          	auipc	a3,0x2
ffffffffc0202a64:	74868693          	addi	a3,a3,1864 # ffffffffc02051a8 <default_pmm_manager+0x478>
ffffffffc0202a68:	00002617          	auipc	a2,0x2
ffffffffc0202a6c:	f1860613          	addi	a2,a2,-232 # ffffffffc0204980 <commands+0x838>
ffffffffc0202a70:	18f00593          	li	a1,399
ffffffffc0202a74:	00002517          	auipc	a0,0x2
ffffffffc0202a78:	40c50513          	addi	a0,a0,1036 # ffffffffc0204e80 <default_pmm_manager+0x150>
ffffffffc0202a7c:	9dffd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0202a80:	00002697          	auipc	a3,0x2
ffffffffc0202a84:	5c868693          	addi	a3,a3,1480 # ffffffffc0205048 <default_pmm_manager+0x318>
ffffffffc0202a88:	00002617          	auipc	a2,0x2
ffffffffc0202a8c:	ef860613          	addi	a2,a2,-264 # ffffffffc0204980 <commands+0x838>
ffffffffc0202a90:	18e00593          	li	a1,398
ffffffffc0202a94:	00002517          	auipc	a0,0x2
ffffffffc0202a98:	3ec50513          	addi	a0,a0,1004 # ffffffffc0204e80 <default_pmm_manager+0x150>
ffffffffc0202a9c:	9bffd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc0202aa0:	00002697          	auipc	a3,0x2
ffffffffc0202aa4:	72068693          	addi	a3,a3,1824 # ffffffffc02051c0 <default_pmm_manager+0x490>
ffffffffc0202aa8:	00002617          	auipc	a2,0x2
ffffffffc0202aac:	ed860613          	addi	a2,a2,-296 # ffffffffc0204980 <commands+0x838>
ffffffffc0202ab0:	18b00593          	li	a1,395
ffffffffc0202ab4:	00002517          	auipc	a0,0x2
ffffffffc0202ab8:	3cc50513          	addi	a0,a0,972 # ffffffffc0204e80 <default_pmm_manager+0x150>
ffffffffc0202abc:	99ffd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0202ac0:	00002697          	auipc	a3,0x2
ffffffffc0202ac4:	57068693          	addi	a3,a3,1392 # ffffffffc0205030 <default_pmm_manager+0x300>
ffffffffc0202ac8:	00002617          	auipc	a2,0x2
ffffffffc0202acc:	eb860613          	addi	a2,a2,-328 # ffffffffc0204980 <commands+0x838>
ffffffffc0202ad0:	18a00593          	li	a1,394
ffffffffc0202ad4:	00002517          	auipc	a0,0x2
ffffffffc0202ad8:	3ac50513          	addi	a0,a0,940 # ffffffffc0204e80 <default_pmm_manager+0x150>
ffffffffc0202adc:	97ffd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202ae0:	00002697          	auipc	a3,0x2
ffffffffc0202ae4:	5f068693          	addi	a3,a3,1520 # ffffffffc02050d0 <default_pmm_manager+0x3a0>
ffffffffc0202ae8:	00002617          	auipc	a2,0x2
ffffffffc0202aec:	e9860613          	addi	a2,a2,-360 # ffffffffc0204980 <commands+0x838>
ffffffffc0202af0:	18900593          	li	a1,393
ffffffffc0202af4:	00002517          	auipc	a0,0x2
ffffffffc0202af8:	38c50513          	addi	a0,a0,908 # ffffffffc0204e80 <default_pmm_manager+0x150>
ffffffffc0202afc:	95ffd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202b00:	00002697          	auipc	a3,0x2
ffffffffc0202b04:	6a868693          	addi	a3,a3,1704 # ffffffffc02051a8 <default_pmm_manager+0x478>
ffffffffc0202b08:	00002617          	auipc	a2,0x2
ffffffffc0202b0c:	e7860613          	addi	a2,a2,-392 # ffffffffc0204980 <commands+0x838>
ffffffffc0202b10:	18800593          	li	a1,392
ffffffffc0202b14:	00002517          	auipc	a0,0x2
ffffffffc0202b18:	36c50513          	addi	a0,a0,876 # ffffffffc0204e80 <default_pmm_manager+0x150>
ffffffffc0202b1c:	93ffd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p1) == 2);
ffffffffc0202b20:	00002697          	auipc	a3,0x2
ffffffffc0202b24:	67068693          	addi	a3,a3,1648 # ffffffffc0205190 <default_pmm_manager+0x460>
ffffffffc0202b28:	00002617          	auipc	a2,0x2
ffffffffc0202b2c:	e5860613          	addi	a2,a2,-424 # ffffffffc0204980 <commands+0x838>
ffffffffc0202b30:	18700593          	li	a1,391
ffffffffc0202b34:	00002517          	auipc	a0,0x2
ffffffffc0202b38:	34c50513          	addi	a0,a0,844 # ffffffffc0204e80 <default_pmm_manager+0x150>
ffffffffc0202b3c:	91ffd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc0202b40:	00002697          	auipc	a3,0x2
ffffffffc0202b44:	62068693          	addi	a3,a3,1568 # ffffffffc0205160 <default_pmm_manager+0x430>
ffffffffc0202b48:	00002617          	auipc	a2,0x2
ffffffffc0202b4c:	e3860613          	addi	a2,a2,-456 # ffffffffc0204980 <commands+0x838>
ffffffffc0202b50:	18600593          	li	a1,390
ffffffffc0202b54:	00002517          	auipc	a0,0x2
ffffffffc0202b58:	32c50513          	addi	a0,a0,812 # ffffffffc0204e80 <default_pmm_manager+0x150>
ffffffffc0202b5c:	8fffd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p2) == 1);
ffffffffc0202b60:	00002697          	auipc	a3,0x2
ffffffffc0202b64:	5e868693          	addi	a3,a3,1512 # ffffffffc0205148 <default_pmm_manager+0x418>
ffffffffc0202b68:	00002617          	auipc	a2,0x2
ffffffffc0202b6c:	e1860613          	addi	a2,a2,-488 # ffffffffc0204980 <commands+0x838>
ffffffffc0202b70:	18400593          	li	a1,388
ffffffffc0202b74:	00002517          	auipc	a0,0x2
ffffffffc0202b78:	30c50513          	addi	a0,a0,780 # ffffffffc0204e80 <default_pmm_manager+0x150>
ffffffffc0202b7c:	8dffd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc0202b80:	00002697          	auipc	a3,0x2
ffffffffc0202b84:	5a868693          	addi	a3,a3,1448 # ffffffffc0205128 <default_pmm_manager+0x3f8>
ffffffffc0202b88:	00002617          	auipc	a2,0x2
ffffffffc0202b8c:	df860613          	addi	a2,a2,-520 # ffffffffc0204980 <commands+0x838>
ffffffffc0202b90:	18300593          	li	a1,387
ffffffffc0202b94:	00002517          	auipc	a0,0x2
ffffffffc0202b98:	2ec50513          	addi	a0,a0,748 # ffffffffc0204e80 <default_pmm_manager+0x150>
ffffffffc0202b9c:	8bffd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(*ptep & PTE_W);
ffffffffc0202ba0:	00002697          	auipc	a3,0x2
ffffffffc0202ba4:	57868693          	addi	a3,a3,1400 # ffffffffc0205118 <default_pmm_manager+0x3e8>
ffffffffc0202ba8:	00002617          	auipc	a2,0x2
ffffffffc0202bac:	dd860613          	addi	a2,a2,-552 # ffffffffc0204980 <commands+0x838>
ffffffffc0202bb0:	18200593          	li	a1,386
ffffffffc0202bb4:	00002517          	auipc	a0,0x2
ffffffffc0202bb8:	2cc50513          	addi	a0,a0,716 # ffffffffc0204e80 <default_pmm_manager+0x150>
ffffffffc0202bbc:	89ffd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(*ptep & PTE_U);
ffffffffc0202bc0:	00002697          	auipc	a3,0x2
ffffffffc0202bc4:	54868693          	addi	a3,a3,1352 # ffffffffc0205108 <default_pmm_manager+0x3d8>
ffffffffc0202bc8:	00002617          	auipc	a2,0x2
ffffffffc0202bcc:	db860613          	addi	a2,a2,-584 # ffffffffc0204980 <commands+0x838>
ffffffffc0202bd0:	18100593          	li	a1,385
ffffffffc0202bd4:	00002517          	auipc	a0,0x2
ffffffffc0202bd8:	2ac50513          	addi	a0,a0,684 # ffffffffc0204e80 <default_pmm_manager+0x150>
ffffffffc0202bdc:	87ffd0ef          	jal	ra,ffffffffc020045a <__panic>
        panic("DTB memory info not available");
ffffffffc0202be0:	00002617          	auipc	a2,0x2
ffffffffc0202be4:	2c860613          	addi	a2,a2,712 # ffffffffc0204ea8 <default_pmm_manager+0x178>
ffffffffc0202be8:	06400593          	li	a1,100
ffffffffc0202bec:	00002517          	auipc	a0,0x2
ffffffffc0202bf0:	29450513          	addi	a0,a0,660 # ffffffffc0204e80 <default_pmm_manager+0x150>
ffffffffc0202bf4:	867fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc0202bf8:	00002697          	auipc	a3,0x2
ffffffffc0202bfc:	62868693          	addi	a3,a3,1576 # ffffffffc0205220 <default_pmm_manager+0x4f0>
ffffffffc0202c00:	00002617          	auipc	a2,0x2
ffffffffc0202c04:	d8060613          	addi	a2,a2,-640 # ffffffffc0204980 <commands+0x838>
ffffffffc0202c08:	1c700593          	li	a1,455
ffffffffc0202c0c:	00002517          	auipc	a0,0x2
ffffffffc0202c10:	27450513          	addi	a0,a0,628 # ffffffffc0204e80 <default_pmm_manager+0x150>
ffffffffc0202c14:	847fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202c18:	00002697          	auipc	a3,0x2
ffffffffc0202c1c:	4b868693          	addi	a3,a3,1208 # ffffffffc02050d0 <default_pmm_manager+0x3a0>
ffffffffc0202c20:	00002617          	auipc	a2,0x2
ffffffffc0202c24:	d6060613          	addi	a2,a2,-672 # ffffffffc0204980 <commands+0x838>
ffffffffc0202c28:	18000593          	li	a1,384
ffffffffc0202c2c:	00002517          	auipc	a0,0x2
ffffffffc0202c30:	25450513          	addi	a0,a0,596 # ffffffffc0204e80 <default_pmm_manager+0x150>
ffffffffc0202c34:	827fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0202c38:	00002697          	auipc	a3,0x2
ffffffffc0202c3c:	45868693          	addi	a3,a3,1112 # ffffffffc0205090 <default_pmm_manager+0x360>
ffffffffc0202c40:	00002617          	auipc	a2,0x2
ffffffffc0202c44:	d4060613          	addi	a2,a2,-704 # ffffffffc0204980 <commands+0x838>
ffffffffc0202c48:	17f00593          	li	a1,383
ffffffffc0202c4c:	00002517          	auipc	a0,0x2
ffffffffc0202c50:	23450513          	addi	a0,a0,564 # ffffffffc0204e80 <default_pmm_manager+0x150>
ffffffffc0202c54:	807fd0ef          	jal	ra,ffffffffc020045a <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202c58:	86d6                	mv	a3,s5
ffffffffc0202c5a:	00002617          	auipc	a2,0x2
ffffffffc0202c5e:	10e60613          	addi	a2,a2,270 # ffffffffc0204d68 <default_pmm_manager+0x38>
ffffffffc0202c62:	17b00593          	li	a1,379
ffffffffc0202c66:	00002517          	auipc	a0,0x2
ffffffffc0202c6a:	21a50513          	addi	a0,a0,538 # ffffffffc0204e80 <default_pmm_manager+0x150>
ffffffffc0202c6e:	fecfd0ef          	jal	ra,ffffffffc020045a <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc0202c72:	00002617          	auipc	a2,0x2
ffffffffc0202c76:	0f660613          	addi	a2,a2,246 # ffffffffc0204d68 <default_pmm_manager+0x38>
ffffffffc0202c7a:	17a00593          	li	a1,378
ffffffffc0202c7e:	00002517          	auipc	a0,0x2
ffffffffc0202c82:	20250513          	addi	a0,a0,514 # ffffffffc0204e80 <default_pmm_manager+0x150>
ffffffffc0202c86:	fd4fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0202c8a:	00002697          	auipc	a3,0x2
ffffffffc0202c8e:	3be68693          	addi	a3,a3,958 # ffffffffc0205048 <default_pmm_manager+0x318>
ffffffffc0202c92:	00002617          	auipc	a2,0x2
ffffffffc0202c96:	cee60613          	addi	a2,a2,-786 # ffffffffc0204980 <commands+0x838>
ffffffffc0202c9a:	17800593          	li	a1,376
ffffffffc0202c9e:	00002517          	auipc	a0,0x2
ffffffffc0202ca2:	1e250513          	addi	a0,a0,482 # ffffffffc0204e80 <default_pmm_manager+0x150>
ffffffffc0202ca6:	fb4fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0202caa:	00002697          	auipc	a3,0x2
ffffffffc0202cae:	38668693          	addi	a3,a3,902 # ffffffffc0205030 <default_pmm_manager+0x300>
ffffffffc0202cb2:	00002617          	auipc	a2,0x2
ffffffffc0202cb6:	cce60613          	addi	a2,a2,-818 # ffffffffc0204980 <commands+0x838>
ffffffffc0202cba:	17700593          	li	a1,375
ffffffffc0202cbe:	00002517          	auipc	a0,0x2
ffffffffc0202cc2:	1c250513          	addi	a0,a0,450 # ffffffffc0204e80 <default_pmm_manager+0x150>
ffffffffc0202cc6:	f94fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202cca:	00002697          	auipc	a3,0x2
ffffffffc0202cce:	71668693          	addi	a3,a3,1814 # ffffffffc02053e0 <default_pmm_manager+0x6b0>
ffffffffc0202cd2:	00002617          	auipc	a2,0x2
ffffffffc0202cd6:	cae60613          	addi	a2,a2,-850 # ffffffffc0204980 <commands+0x838>
ffffffffc0202cda:	1be00593          	li	a1,446
ffffffffc0202cde:	00002517          	auipc	a0,0x2
ffffffffc0202ce2:	1a250513          	addi	a0,a0,418 # ffffffffc0204e80 <default_pmm_manager+0x150>
ffffffffc0202ce6:	f74fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0202cea:	00002697          	auipc	a3,0x2
ffffffffc0202cee:	6be68693          	addi	a3,a3,1726 # ffffffffc02053a8 <default_pmm_manager+0x678>
ffffffffc0202cf2:	00002617          	auipc	a2,0x2
ffffffffc0202cf6:	c8e60613          	addi	a2,a2,-882 # ffffffffc0204980 <commands+0x838>
ffffffffc0202cfa:	1bb00593          	li	a1,443
ffffffffc0202cfe:	00002517          	auipc	a0,0x2
ffffffffc0202d02:	18250513          	addi	a0,a0,386 # ffffffffc0204e80 <default_pmm_manager+0x150>
ffffffffc0202d06:	f54fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p) == 2);
ffffffffc0202d0a:	00002697          	auipc	a3,0x2
ffffffffc0202d0e:	66e68693          	addi	a3,a3,1646 # ffffffffc0205378 <default_pmm_manager+0x648>
ffffffffc0202d12:	00002617          	auipc	a2,0x2
ffffffffc0202d16:	c6e60613          	addi	a2,a2,-914 # ffffffffc0204980 <commands+0x838>
ffffffffc0202d1a:	1b700593          	li	a1,439
ffffffffc0202d1e:	00002517          	auipc	a0,0x2
ffffffffc0202d22:	16250513          	addi	a0,a0,354 # ffffffffc0204e80 <default_pmm_manager+0x150>
ffffffffc0202d26:	f34fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0202d2a:	00002697          	auipc	a3,0x2
ffffffffc0202d2e:	60668693          	addi	a3,a3,1542 # ffffffffc0205330 <default_pmm_manager+0x600>
ffffffffc0202d32:	00002617          	auipc	a2,0x2
ffffffffc0202d36:	c4e60613          	addi	a2,a2,-946 # ffffffffc0204980 <commands+0x838>
ffffffffc0202d3a:	1b600593          	li	a1,438
ffffffffc0202d3e:	00002517          	auipc	a0,0x2
ffffffffc0202d42:	14250513          	addi	a0,a0,322 # ffffffffc0204e80 <default_pmm_manager+0x150>
ffffffffc0202d46:	f14fd0ef          	jal	ra,ffffffffc020045a <__panic>
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc0202d4a:	00002617          	auipc	a2,0x2
ffffffffc0202d4e:	0c660613          	addi	a2,a2,198 # ffffffffc0204e10 <default_pmm_manager+0xe0>
ffffffffc0202d52:	0cb00593          	li	a1,203
ffffffffc0202d56:	00002517          	auipc	a0,0x2
ffffffffc0202d5a:	12a50513          	addi	a0,a0,298 # ffffffffc0204e80 <default_pmm_manager+0x150>
ffffffffc0202d5e:	efcfd0ef          	jal	ra,ffffffffc020045a <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202d62:	00002617          	auipc	a2,0x2
ffffffffc0202d66:	0ae60613          	addi	a2,a2,174 # ffffffffc0204e10 <default_pmm_manager+0xe0>
ffffffffc0202d6a:	08000593          	li	a1,128
ffffffffc0202d6e:	00002517          	auipc	a0,0x2
ffffffffc0202d72:	11250513          	addi	a0,a0,274 # ffffffffc0204e80 <default_pmm_manager+0x150>
ffffffffc0202d76:	ee4fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc0202d7a:	00002697          	auipc	a3,0x2
ffffffffc0202d7e:	28668693          	addi	a3,a3,646 # ffffffffc0205000 <default_pmm_manager+0x2d0>
ffffffffc0202d82:	00002617          	auipc	a2,0x2
ffffffffc0202d86:	bfe60613          	addi	a2,a2,-1026 # ffffffffc0204980 <commands+0x838>
ffffffffc0202d8a:	17600593          	li	a1,374
ffffffffc0202d8e:	00002517          	auipc	a0,0x2
ffffffffc0202d92:	0f250513          	addi	a0,a0,242 # ffffffffc0204e80 <default_pmm_manager+0x150>
ffffffffc0202d96:	ec4fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc0202d9a:	00002697          	auipc	a3,0x2
ffffffffc0202d9e:	23668693          	addi	a3,a3,566 # ffffffffc0204fd0 <default_pmm_manager+0x2a0>
ffffffffc0202da2:	00002617          	auipc	a2,0x2
ffffffffc0202da6:	bde60613          	addi	a2,a2,-1058 # ffffffffc0204980 <commands+0x838>
ffffffffc0202daa:	17300593          	li	a1,371
ffffffffc0202dae:	00002517          	auipc	a0,0x2
ffffffffc0202db2:	0d250513          	addi	a0,a0,210 # ffffffffc0204e80 <default_pmm_manager+0x150>
ffffffffc0202db6:	ea4fd0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0202dba <check_vma_overlap.part.0>:
    return vma;
}

// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc0202dba:	1141                	addi	sp,sp,-16
{
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc0202dbc:	00002697          	auipc	a3,0x2
ffffffffc0202dc0:	66c68693          	addi	a3,a3,1644 # ffffffffc0205428 <default_pmm_manager+0x6f8>
ffffffffc0202dc4:	00002617          	auipc	a2,0x2
ffffffffc0202dc8:	bbc60613          	addi	a2,a2,-1092 # ffffffffc0204980 <commands+0x838>
ffffffffc0202dcc:	08800593          	li	a1,136
ffffffffc0202dd0:	00002517          	auipc	a0,0x2
ffffffffc0202dd4:	67850513          	addi	a0,a0,1656 # ffffffffc0205448 <default_pmm_manager+0x718>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc0202dd8:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc0202dda:	e80fd0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0202dde <find_vma>:
{
ffffffffc0202dde:	86aa                	mv	a3,a0
    if (mm != NULL)
ffffffffc0202de0:	c505                	beqz	a0,ffffffffc0202e08 <find_vma+0x2a>
        vma = mm->mmap_cache;
ffffffffc0202de2:	6908                	ld	a0,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc0202de4:	c501                	beqz	a0,ffffffffc0202dec <find_vma+0xe>
ffffffffc0202de6:	651c                	ld	a5,8(a0)
ffffffffc0202de8:	02f5f263          	bgeu	a1,a5,ffffffffc0202e0c <find_vma+0x2e>
    return listelm->next;
ffffffffc0202dec:	669c                	ld	a5,8(a3)
            while ((le = list_next(le)) != list)
ffffffffc0202dee:	00f68d63          	beq	a3,a5,ffffffffc0202e08 <find_vma+0x2a>
                if (vma->vm_start <= addr && addr < vma->vm_end)
ffffffffc0202df2:	fe87b703          	ld	a4,-24(a5) # ffffffffc7ffffe8 <end+0x7df2afc>
ffffffffc0202df6:	00e5e663          	bltu	a1,a4,ffffffffc0202e02 <find_vma+0x24>
ffffffffc0202dfa:	ff07b703          	ld	a4,-16(a5)
ffffffffc0202dfe:	00e5ec63          	bltu	a1,a4,ffffffffc0202e16 <find_vma+0x38>
ffffffffc0202e02:	679c                	ld	a5,8(a5)
            while ((le = list_next(le)) != list)
ffffffffc0202e04:	fef697e3          	bne	a3,a5,ffffffffc0202df2 <find_vma+0x14>
    struct vma_struct *vma = NULL;
ffffffffc0202e08:	4501                	li	a0,0
}
ffffffffc0202e0a:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc0202e0c:	691c                	ld	a5,16(a0)
ffffffffc0202e0e:	fcf5ffe3          	bgeu	a1,a5,ffffffffc0202dec <find_vma+0xe>
            mm->mmap_cache = vma;
ffffffffc0202e12:	ea88                	sd	a0,16(a3)
ffffffffc0202e14:	8082                	ret
                vma = le2vma(le, list_link);
ffffffffc0202e16:	fe078513          	addi	a0,a5,-32
            mm->mmap_cache = vma;
ffffffffc0202e1a:	ea88                	sd	a0,16(a3)
ffffffffc0202e1c:	8082                	ret

ffffffffc0202e1e <insert_vma_struct>:
}

// insert_vma_struct -insert vma in mm's list link
void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma)
{
    assert(vma->vm_start < vma->vm_end);
ffffffffc0202e1e:	6590                	ld	a2,8(a1)
ffffffffc0202e20:	0105b803          	ld	a6,16(a1)
{
ffffffffc0202e24:	1141                	addi	sp,sp,-16
ffffffffc0202e26:	e406                	sd	ra,8(sp)
ffffffffc0202e28:	87aa                	mv	a5,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc0202e2a:	01066763          	bltu	a2,a6,ffffffffc0202e38 <insert_vma_struct+0x1a>
ffffffffc0202e2e:	a085                	j	ffffffffc0202e8e <insert_vma_struct+0x70>

    list_entry_t *le = list;
    while ((le = list_next(le)) != list)
    {
        struct vma_struct *mmap_prev = le2vma(le, list_link);
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc0202e30:	fe87b703          	ld	a4,-24(a5)
ffffffffc0202e34:	04e66863          	bltu	a2,a4,ffffffffc0202e84 <insert_vma_struct+0x66>
ffffffffc0202e38:	86be                	mv	a3,a5
ffffffffc0202e3a:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != list)
ffffffffc0202e3c:	fef51ae3          	bne	a0,a5,ffffffffc0202e30 <insert_vma_struct+0x12>
    }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list)
ffffffffc0202e40:	02a68463          	beq	a3,a0,ffffffffc0202e68 <insert_vma_struct+0x4a>
    {
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc0202e44:	ff06b703          	ld	a4,-16(a3)
    assert(prev->vm_start < prev->vm_end);
ffffffffc0202e48:	fe86b883          	ld	a7,-24(a3)
ffffffffc0202e4c:	08e8f163          	bgeu	a7,a4,ffffffffc0202ece <insert_vma_struct+0xb0>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0202e50:	04e66f63          	bltu	a2,a4,ffffffffc0202eae <insert_vma_struct+0x90>
    }
    if (le_next != list)
ffffffffc0202e54:	00f50a63          	beq	a0,a5,ffffffffc0202e68 <insert_vma_struct+0x4a>
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc0202e58:	fe87b703          	ld	a4,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc0202e5c:	05076963          	bltu	a4,a6,ffffffffc0202eae <insert_vma_struct+0x90>
    assert(next->vm_start < next->vm_end);
ffffffffc0202e60:	ff07b603          	ld	a2,-16(a5)
ffffffffc0202e64:	02c77363          	bgeu	a4,a2,ffffffffc0202e8a <insert_vma_struct+0x6c>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count++;
ffffffffc0202e68:	5118                	lw	a4,32(a0)
    vma->vm_mm = mm;
ffffffffc0202e6a:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc0202e6c:	02058613          	addi	a2,a1,32
    prev->next = next->prev = elm;
ffffffffc0202e70:	e390                	sd	a2,0(a5)
ffffffffc0202e72:	e690                	sd	a2,8(a3)
}
ffffffffc0202e74:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc0202e76:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc0202e78:	f194                	sd	a3,32(a1)
    mm->map_count++;
ffffffffc0202e7a:	0017079b          	addiw	a5,a4,1
ffffffffc0202e7e:	d11c                	sw	a5,32(a0)
}
ffffffffc0202e80:	0141                	addi	sp,sp,16
ffffffffc0202e82:	8082                	ret
    if (le_prev != list)
ffffffffc0202e84:	fca690e3          	bne	a3,a0,ffffffffc0202e44 <insert_vma_struct+0x26>
ffffffffc0202e88:	bfd1                	j	ffffffffc0202e5c <insert_vma_struct+0x3e>
ffffffffc0202e8a:	f31ff0ef          	jal	ra,ffffffffc0202dba <check_vma_overlap.part.0>
    assert(vma->vm_start < vma->vm_end);
ffffffffc0202e8e:	00002697          	auipc	a3,0x2
ffffffffc0202e92:	5ca68693          	addi	a3,a3,1482 # ffffffffc0205458 <default_pmm_manager+0x728>
ffffffffc0202e96:	00002617          	auipc	a2,0x2
ffffffffc0202e9a:	aea60613          	addi	a2,a2,-1302 # ffffffffc0204980 <commands+0x838>
ffffffffc0202e9e:	08e00593          	li	a1,142
ffffffffc0202ea2:	00002517          	auipc	a0,0x2
ffffffffc0202ea6:	5a650513          	addi	a0,a0,1446 # ffffffffc0205448 <default_pmm_manager+0x718>
ffffffffc0202eaa:	db0fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0202eae:	00002697          	auipc	a3,0x2
ffffffffc0202eb2:	5ea68693          	addi	a3,a3,1514 # ffffffffc0205498 <default_pmm_manager+0x768>
ffffffffc0202eb6:	00002617          	auipc	a2,0x2
ffffffffc0202eba:	aca60613          	addi	a2,a2,-1334 # ffffffffc0204980 <commands+0x838>
ffffffffc0202ebe:	08700593          	li	a1,135
ffffffffc0202ec2:	00002517          	auipc	a0,0x2
ffffffffc0202ec6:	58650513          	addi	a0,a0,1414 # ffffffffc0205448 <default_pmm_manager+0x718>
ffffffffc0202eca:	d90fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc0202ece:	00002697          	auipc	a3,0x2
ffffffffc0202ed2:	5aa68693          	addi	a3,a3,1450 # ffffffffc0205478 <default_pmm_manager+0x748>
ffffffffc0202ed6:	00002617          	auipc	a2,0x2
ffffffffc0202eda:	aaa60613          	addi	a2,a2,-1366 # ffffffffc0204980 <commands+0x838>
ffffffffc0202ede:	08600593          	li	a1,134
ffffffffc0202ee2:	00002517          	auipc	a0,0x2
ffffffffc0202ee6:	56650513          	addi	a0,a0,1382 # ffffffffc0205448 <default_pmm_manager+0x718>
ffffffffc0202eea:	d70fd0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0202eee <vmm_init>:

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
// 2310675: 虚拟内存管理初始化函数，建立VMA（虚拟内存区域）管理框架
void vmm_init(void)
{
ffffffffc0202eee:	7139                	addi	sp,sp,-64
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0202ef0:	03000513          	li	a0,48
{
ffffffffc0202ef4:	fc06                	sd	ra,56(sp)
ffffffffc0202ef6:	f822                	sd	s0,48(sp)
ffffffffc0202ef8:	f426                	sd	s1,40(sp)
ffffffffc0202efa:	f04a                	sd	s2,32(sp)
ffffffffc0202efc:	ec4e                	sd	s3,24(sp)
ffffffffc0202efe:	e852                	sd	s4,16(sp)
ffffffffc0202f00:	e456                	sd	s5,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0202f02:	bd5fe0ef          	jal	ra,ffffffffc0201ad6 <kmalloc>
    if (mm != NULL)
ffffffffc0202f06:	2e050f63          	beqz	a0,ffffffffc0203204 <vmm_init+0x316>
ffffffffc0202f0a:	84aa                	mv	s1,a0
    elm->prev = elm->next = elm;
ffffffffc0202f0c:	e508                	sd	a0,8(a0)
ffffffffc0202f0e:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc0202f10:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0202f14:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0202f18:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc0202f1c:	02053423          	sd	zero,40(a0)
ffffffffc0202f20:	03200413          	li	s0,50
ffffffffc0202f24:	a811                	j	ffffffffc0202f38 <vmm_init+0x4a>
        vma->vm_start = vm_start;
ffffffffc0202f26:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc0202f28:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0202f2a:	00052c23          	sw	zero,24(a0)
    assert(mm != NULL);

    int step1 = 10, step2 = step1 * 10;

    int i;
    for (i = step1; i >= 1; i--)
ffffffffc0202f2e:	146d                	addi	s0,s0,-5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0202f30:	8526                	mv	a0,s1
ffffffffc0202f32:	eedff0ef          	jal	ra,ffffffffc0202e1e <insert_vma_struct>
    for (i = step1; i >= 1; i--)
ffffffffc0202f36:	c80d                	beqz	s0,ffffffffc0202f68 <vmm_init+0x7a>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0202f38:	03000513          	li	a0,48
ffffffffc0202f3c:	b9bfe0ef          	jal	ra,ffffffffc0201ad6 <kmalloc>
ffffffffc0202f40:	85aa                	mv	a1,a0
ffffffffc0202f42:	00240793          	addi	a5,s0,2
    if (vma != NULL)
ffffffffc0202f46:	f165                	bnez	a0,ffffffffc0202f26 <vmm_init+0x38>
        assert(vma != NULL);
ffffffffc0202f48:	00002697          	auipc	a3,0x2
ffffffffc0202f4c:	6e868693          	addi	a3,a3,1768 # ffffffffc0205630 <default_pmm_manager+0x900>
ffffffffc0202f50:	00002617          	auipc	a2,0x2
ffffffffc0202f54:	a3060613          	addi	a2,a2,-1488 # ffffffffc0204980 <commands+0x838>
ffffffffc0202f58:	0dc00593          	li	a1,220
ffffffffc0202f5c:	00002517          	auipc	a0,0x2
ffffffffc0202f60:	4ec50513          	addi	a0,a0,1260 # ffffffffc0205448 <default_pmm_manager+0x718>
ffffffffc0202f64:	cf6fd0ef          	jal	ra,ffffffffc020045a <__panic>
ffffffffc0202f68:	03700413          	li	s0,55
    }

    for (i = step1 + 1; i <= step2; i++)
ffffffffc0202f6c:	1f900913          	li	s2,505
ffffffffc0202f70:	a819                	j	ffffffffc0202f86 <vmm_init+0x98>
        vma->vm_start = vm_start;
ffffffffc0202f72:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc0202f74:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0202f76:	00052c23          	sw	zero,24(a0)
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0202f7a:	0415                	addi	s0,s0,5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0202f7c:	8526                	mv	a0,s1
ffffffffc0202f7e:	ea1ff0ef          	jal	ra,ffffffffc0202e1e <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0202f82:	03240a63          	beq	s0,s2,ffffffffc0202fb6 <vmm_init+0xc8>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0202f86:	03000513          	li	a0,48
ffffffffc0202f8a:	b4dfe0ef          	jal	ra,ffffffffc0201ad6 <kmalloc>
ffffffffc0202f8e:	85aa                	mv	a1,a0
ffffffffc0202f90:	00240793          	addi	a5,s0,2
    if (vma != NULL)
ffffffffc0202f94:	fd79                	bnez	a0,ffffffffc0202f72 <vmm_init+0x84>
        assert(vma != NULL);
ffffffffc0202f96:	00002697          	auipc	a3,0x2
ffffffffc0202f9a:	69a68693          	addi	a3,a3,1690 # ffffffffc0205630 <default_pmm_manager+0x900>
ffffffffc0202f9e:	00002617          	auipc	a2,0x2
ffffffffc0202fa2:	9e260613          	addi	a2,a2,-1566 # ffffffffc0204980 <commands+0x838>
ffffffffc0202fa6:	0e300593          	li	a1,227
ffffffffc0202faa:	00002517          	auipc	a0,0x2
ffffffffc0202fae:	49e50513          	addi	a0,a0,1182 # ffffffffc0205448 <default_pmm_manager+0x718>
ffffffffc0202fb2:	ca8fd0ef          	jal	ra,ffffffffc020045a <__panic>
    return listelm->next;
ffffffffc0202fb6:	649c                	ld	a5,8(s1)
ffffffffc0202fb8:	471d                	li	a4,7
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i++)
ffffffffc0202fba:	1fb00593          	li	a1,507
    {
        assert(le != &(mm->mmap_list));
ffffffffc0202fbe:	18f48363          	beq	s1,a5,ffffffffc0203144 <vmm_init+0x256>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0202fc2:	fe87b603          	ld	a2,-24(a5)
ffffffffc0202fc6:	ffe70693          	addi	a3,a4,-2 # ffe <kern_entry-0xffffffffc01ff002>
ffffffffc0202fca:	10d61d63          	bne	a2,a3,ffffffffc02030e4 <vmm_init+0x1f6>
ffffffffc0202fce:	ff07b683          	ld	a3,-16(a5)
ffffffffc0202fd2:	10e69963          	bne	a3,a4,ffffffffc02030e4 <vmm_init+0x1f6>
    for (i = 1; i <= step2; i++)
ffffffffc0202fd6:	0715                	addi	a4,a4,5
ffffffffc0202fd8:	679c                	ld	a5,8(a5)
ffffffffc0202fda:	feb712e3          	bne	a4,a1,ffffffffc0202fbe <vmm_init+0xd0>
ffffffffc0202fde:	4a1d                	li	s4,7
ffffffffc0202fe0:	4415                	li	s0,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0202fe2:	1f900a93          	li	s5,505
    {
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc0202fe6:	85a2                	mv	a1,s0
ffffffffc0202fe8:	8526                	mv	a0,s1
ffffffffc0202fea:	df5ff0ef          	jal	ra,ffffffffc0202dde <find_vma>
ffffffffc0202fee:	892a                	mv	s2,a0
        assert(vma1 != NULL);
ffffffffc0202ff0:	18050a63          	beqz	a0,ffffffffc0203184 <vmm_init+0x296>
        struct vma_struct *vma2 = find_vma(mm, i + 1);
ffffffffc0202ff4:	00140593          	addi	a1,s0,1
ffffffffc0202ff8:	8526                	mv	a0,s1
ffffffffc0202ffa:	de5ff0ef          	jal	ra,ffffffffc0202dde <find_vma>
ffffffffc0202ffe:	89aa                	mv	s3,a0
        assert(vma2 != NULL);
ffffffffc0203000:	16050263          	beqz	a0,ffffffffc0203164 <vmm_init+0x276>
        struct vma_struct *vma3 = find_vma(mm, i + 2);
ffffffffc0203004:	85d2                	mv	a1,s4
ffffffffc0203006:	8526                	mv	a0,s1
ffffffffc0203008:	dd7ff0ef          	jal	ra,ffffffffc0202dde <find_vma>
        assert(vma3 == NULL);
ffffffffc020300c:	18051c63          	bnez	a0,ffffffffc02031a4 <vmm_init+0x2b6>
        struct vma_struct *vma4 = find_vma(mm, i + 3);
ffffffffc0203010:	00340593          	addi	a1,s0,3
ffffffffc0203014:	8526                	mv	a0,s1
ffffffffc0203016:	dc9ff0ef          	jal	ra,ffffffffc0202dde <find_vma>
        assert(vma4 == NULL);
ffffffffc020301a:	1c051563          	bnez	a0,ffffffffc02031e4 <vmm_init+0x2f6>
        struct vma_struct *vma5 = find_vma(mm, i + 4);
ffffffffc020301e:	00440593          	addi	a1,s0,4
ffffffffc0203022:	8526                	mv	a0,s1
ffffffffc0203024:	dbbff0ef          	jal	ra,ffffffffc0202dde <find_vma>
        assert(vma5 == NULL);
ffffffffc0203028:	18051e63          	bnez	a0,ffffffffc02031c4 <vmm_init+0x2d6>

        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc020302c:	00893783          	ld	a5,8(s2)
ffffffffc0203030:	0c879a63          	bne	a5,s0,ffffffffc0203104 <vmm_init+0x216>
ffffffffc0203034:	01093783          	ld	a5,16(s2)
ffffffffc0203038:	0d479663          	bne	a5,s4,ffffffffc0203104 <vmm_init+0x216>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc020303c:	0089b783          	ld	a5,8(s3)
ffffffffc0203040:	0e879263          	bne	a5,s0,ffffffffc0203124 <vmm_init+0x236>
ffffffffc0203044:	0109b783          	ld	a5,16(s3)
ffffffffc0203048:	0d479e63          	bne	a5,s4,ffffffffc0203124 <vmm_init+0x236>
    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc020304c:	0415                	addi	s0,s0,5
ffffffffc020304e:	0a15                	addi	s4,s4,5
ffffffffc0203050:	f9541be3          	bne	s0,s5,ffffffffc0202fe6 <vmm_init+0xf8>
ffffffffc0203054:	4411                	li	s0,4
    }

    for (i = 4; i >= 0; i--)
ffffffffc0203056:	597d                	li	s2,-1
    {
        struct vma_struct *vma_below_5 = find_vma(mm, i);
ffffffffc0203058:	85a2                	mv	a1,s0
ffffffffc020305a:	8526                	mv	a0,s1
ffffffffc020305c:	d83ff0ef          	jal	ra,ffffffffc0202dde <find_vma>
ffffffffc0203060:	0004059b          	sext.w	a1,s0
        if (vma_below_5 != NULL)
ffffffffc0203064:	c90d                	beqz	a0,ffffffffc0203096 <vmm_init+0x1a8>
        {
            cprintf("vma_below_5: i %x, start %x, end %x\n", i, vma_below_5->vm_start, vma_below_5->vm_end);
ffffffffc0203066:	6914                	ld	a3,16(a0)
ffffffffc0203068:	6510                	ld	a2,8(a0)
ffffffffc020306a:	00002517          	auipc	a0,0x2
ffffffffc020306e:	54e50513          	addi	a0,a0,1358 # ffffffffc02055b8 <default_pmm_manager+0x888>
ffffffffc0203072:	922fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
        }
        assert(vma_below_5 == NULL);
ffffffffc0203076:	00002697          	auipc	a3,0x2
ffffffffc020307a:	56a68693          	addi	a3,a3,1386 # ffffffffc02055e0 <default_pmm_manager+0x8b0>
ffffffffc020307e:	00002617          	auipc	a2,0x2
ffffffffc0203082:	90260613          	addi	a2,a2,-1790 # ffffffffc0204980 <commands+0x838>
ffffffffc0203086:	10900593          	li	a1,265
ffffffffc020308a:	00002517          	auipc	a0,0x2
ffffffffc020308e:	3be50513          	addi	a0,a0,958 # ffffffffc0205448 <default_pmm_manager+0x718>
ffffffffc0203092:	bc8fd0ef          	jal	ra,ffffffffc020045a <__panic>
    for (i = 4; i >= 0; i--)
ffffffffc0203096:	147d                	addi	s0,s0,-1
ffffffffc0203098:	fd2410e3          	bne	s0,s2,ffffffffc0203058 <vmm_init+0x16a>
ffffffffc020309c:	6488                	ld	a0,8(s1)
    while ((le = list_next(list)) != list)
ffffffffc020309e:	00a48c63          	beq	s1,a0,ffffffffc02030b6 <vmm_init+0x1c8>
    __list_del(listelm->prev, listelm->next);
ffffffffc02030a2:	6118                	ld	a4,0(a0)
ffffffffc02030a4:	651c                	ld	a5,8(a0)
        kfree(le2vma(le, list_link)); // kfree vma
ffffffffc02030a6:	1501                	addi	a0,a0,-32
    prev->next = next;
ffffffffc02030a8:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc02030aa:	e398                	sd	a4,0(a5)
ffffffffc02030ac:	adbfe0ef          	jal	ra,ffffffffc0201b86 <kfree>
    return listelm->next;
ffffffffc02030b0:	6488                	ld	a0,8(s1)
    while ((le = list_next(list)) != list)
ffffffffc02030b2:	fea498e3          	bne	s1,a0,ffffffffc02030a2 <vmm_init+0x1b4>
    kfree(mm); // kfree mm
ffffffffc02030b6:	8526                	mv	a0,s1
ffffffffc02030b8:	acffe0ef          	jal	ra,ffffffffc0201b86 <kfree>
    }

    mm_destroy(mm);

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc02030bc:	00002517          	auipc	a0,0x2
ffffffffc02030c0:	53c50513          	addi	a0,a0,1340 # ffffffffc02055f8 <default_pmm_manager+0x8c8>
ffffffffc02030c4:	8d0fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
}
ffffffffc02030c8:	7442                	ld	s0,48(sp)
ffffffffc02030ca:	70e2                	ld	ra,56(sp)
ffffffffc02030cc:	74a2                	ld	s1,40(sp)
ffffffffc02030ce:	7902                	ld	s2,32(sp)
ffffffffc02030d0:	69e2                	ld	s3,24(sp)
ffffffffc02030d2:	6a42                	ld	s4,16(sp)
ffffffffc02030d4:	6aa2                	ld	s5,8(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc02030d6:	00002517          	auipc	a0,0x2
ffffffffc02030da:	54250513          	addi	a0,a0,1346 # ffffffffc0205618 <default_pmm_manager+0x8e8>
}
ffffffffc02030de:	6121                	addi	sp,sp,64
    cprintf("check_vmm() succeeded.\n");
ffffffffc02030e0:	8b4fd06f          	j	ffffffffc0200194 <cprintf>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc02030e4:	00002697          	auipc	a3,0x2
ffffffffc02030e8:	3ec68693          	addi	a3,a3,1004 # ffffffffc02054d0 <default_pmm_manager+0x7a0>
ffffffffc02030ec:	00002617          	auipc	a2,0x2
ffffffffc02030f0:	89460613          	addi	a2,a2,-1900 # ffffffffc0204980 <commands+0x838>
ffffffffc02030f4:	0ed00593          	li	a1,237
ffffffffc02030f8:	00002517          	auipc	a0,0x2
ffffffffc02030fc:	35050513          	addi	a0,a0,848 # ffffffffc0205448 <default_pmm_manager+0x718>
ffffffffc0203100:	b5afd0ef          	jal	ra,ffffffffc020045a <__panic>
        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203104:	00002697          	auipc	a3,0x2
ffffffffc0203108:	45468693          	addi	a3,a3,1108 # ffffffffc0205558 <default_pmm_manager+0x828>
ffffffffc020310c:	00002617          	auipc	a2,0x2
ffffffffc0203110:	87460613          	addi	a2,a2,-1932 # ffffffffc0204980 <commands+0x838>
ffffffffc0203114:	0fe00593          	li	a1,254
ffffffffc0203118:	00002517          	auipc	a0,0x2
ffffffffc020311c:	33050513          	addi	a0,a0,816 # ffffffffc0205448 <default_pmm_manager+0x718>
ffffffffc0203120:	b3afd0ef          	jal	ra,ffffffffc020045a <__panic>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203124:	00002697          	auipc	a3,0x2
ffffffffc0203128:	46468693          	addi	a3,a3,1124 # ffffffffc0205588 <default_pmm_manager+0x858>
ffffffffc020312c:	00002617          	auipc	a2,0x2
ffffffffc0203130:	85460613          	addi	a2,a2,-1964 # ffffffffc0204980 <commands+0x838>
ffffffffc0203134:	0ff00593          	li	a1,255
ffffffffc0203138:	00002517          	auipc	a0,0x2
ffffffffc020313c:	31050513          	addi	a0,a0,784 # ffffffffc0205448 <default_pmm_manager+0x718>
ffffffffc0203140:	b1afd0ef          	jal	ra,ffffffffc020045a <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc0203144:	00002697          	auipc	a3,0x2
ffffffffc0203148:	37468693          	addi	a3,a3,884 # ffffffffc02054b8 <default_pmm_manager+0x788>
ffffffffc020314c:	00002617          	auipc	a2,0x2
ffffffffc0203150:	83460613          	addi	a2,a2,-1996 # ffffffffc0204980 <commands+0x838>
ffffffffc0203154:	0eb00593          	li	a1,235
ffffffffc0203158:	00002517          	auipc	a0,0x2
ffffffffc020315c:	2f050513          	addi	a0,a0,752 # ffffffffc0205448 <default_pmm_manager+0x718>
ffffffffc0203160:	afafd0ef          	jal	ra,ffffffffc020045a <__panic>
        assert(vma2 != NULL);
ffffffffc0203164:	00002697          	auipc	a3,0x2
ffffffffc0203168:	3b468693          	addi	a3,a3,948 # ffffffffc0205518 <default_pmm_manager+0x7e8>
ffffffffc020316c:	00002617          	auipc	a2,0x2
ffffffffc0203170:	81460613          	addi	a2,a2,-2028 # ffffffffc0204980 <commands+0x838>
ffffffffc0203174:	0f600593          	li	a1,246
ffffffffc0203178:	00002517          	auipc	a0,0x2
ffffffffc020317c:	2d050513          	addi	a0,a0,720 # ffffffffc0205448 <default_pmm_manager+0x718>
ffffffffc0203180:	adafd0ef          	jal	ra,ffffffffc020045a <__panic>
        assert(vma1 != NULL);
ffffffffc0203184:	00002697          	auipc	a3,0x2
ffffffffc0203188:	38468693          	addi	a3,a3,900 # ffffffffc0205508 <default_pmm_manager+0x7d8>
ffffffffc020318c:	00001617          	auipc	a2,0x1
ffffffffc0203190:	7f460613          	addi	a2,a2,2036 # ffffffffc0204980 <commands+0x838>
ffffffffc0203194:	0f400593          	li	a1,244
ffffffffc0203198:	00002517          	auipc	a0,0x2
ffffffffc020319c:	2b050513          	addi	a0,a0,688 # ffffffffc0205448 <default_pmm_manager+0x718>
ffffffffc02031a0:	abafd0ef          	jal	ra,ffffffffc020045a <__panic>
        assert(vma3 == NULL);
ffffffffc02031a4:	00002697          	auipc	a3,0x2
ffffffffc02031a8:	38468693          	addi	a3,a3,900 # ffffffffc0205528 <default_pmm_manager+0x7f8>
ffffffffc02031ac:	00001617          	auipc	a2,0x1
ffffffffc02031b0:	7d460613          	addi	a2,a2,2004 # ffffffffc0204980 <commands+0x838>
ffffffffc02031b4:	0f800593          	li	a1,248
ffffffffc02031b8:	00002517          	auipc	a0,0x2
ffffffffc02031bc:	29050513          	addi	a0,a0,656 # ffffffffc0205448 <default_pmm_manager+0x718>
ffffffffc02031c0:	a9afd0ef          	jal	ra,ffffffffc020045a <__panic>
        assert(vma5 == NULL);
ffffffffc02031c4:	00002697          	auipc	a3,0x2
ffffffffc02031c8:	38468693          	addi	a3,a3,900 # ffffffffc0205548 <default_pmm_manager+0x818>
ffffffffc02031cc:	00001617          	auipc	a2,0x1
ffffffffc02031d0:	7b460613          	addi	a2,a2,1972 # ffffffffc0204980 <commands+0x838>
ffffffffc02031d4:	0fc00593          	li	a1,252
ffffffffc02031d8:	00002517          	auipc	a0,0x2
ffffffffc02031dc:	27050513          	addi	a0,a0,624 # ffffffffc0205448 <default_pmm_manager+0x718>
ffffffffc02031e0:	a7afd0ef          	jal	ra,ffffffffc020045a <__panic>
        assert(vma4 == NULL);
ffffffffc02031e4:	00002697          	auipc	a3,0x2
ffffffffc02031e8:	35468693          	addi	a3,a3,852 # ffffffffc0205538 <default_pmm_manager+0x808>
ffffffffc02031ec:	00001617          	auipc	a2,0x1
ffffffffc02031f0:	79460613          	addi	a2,a2,1940 # ffffffffc0204980 <commands+0x838>
ffffffffc02031f4:	0fa00593          	li	a1,250
ffffffffc02031f8:	00002517          	auipc	a0,0x2
ffffffffc02031fc:	25050513          	addi	a0,a0,592 # ffffffffc0205448 <default_pmm_manager+0x718>
ffffffffc0203200:	a5afd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(mm != NULL);
ffffffffc0203204:	00002697          	auipc	a3,0x2
ffffffffc0203208:	43c68693          	addi	a3,a3,1084 # ffffffffc0205640 <default_pmm_manager+0x910>
ffffffffc020320c:	00001617          	auipc	a2,0x1
ffffffffc0203210:	77460613          	addi	a2,a2,1908 # ffffffffc0204980 <commands+0x838>
ffffffffc0203214:	0d400593          	li	a1,212
ffffffffc0203218:	00002517          	auipc	a0,0x2
ffffffffc020321c:	23050513          	addi	a0,a0,560 # ffffffffc0205448 <default_pmm_manager+0x718>
ffffffffc0203220:	a3afd0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0203224 <kernel_thread_entry>:
.text
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void)
	# 2310675: 内核线程统一入口点，此时s0/s1已由trapframe恢复为函数指针和参数
	# s0保存线程入口函数指针（如init_main），s1保存参数（如"Hello world!!"）
	move a0, s1             # 2310675: 按RISC-V调用约定，a0传递第一个参数
ffffffffc0203224:	8526                	mv	a0,s1
	# 调用真正的线程函数，执行完返回继续向下
	jalr s0                 # 2310675: 跳转到s0指向的函数（如init_main），执行线程任务
ffffffffc0203226:	9402                	jalr	s0

	# 线程函数返回即视为线程结束，统一走内核的do_exit流程
	jal do_exit             # 2310675: 线程正常结束后调用do_exit清理资源
ffffffffc0203228:	40e000ef          	jal	ra,ffffffffc0203636 <do_exit>

ffffffffc020322c <alloc_proc>:
void switch_to(struct context *from, struct context *to);

// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct *
alloc_proc(void)
{
ffffffffc020322c:	1141                	addi	sp,sp,-16
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc020322e:	0e800513          	li	a0,232
{
ffffffffc0203232:	e022                	sd	s0,0(sp)
ffffffffc0203234:	e406                	sd	ra,8(sp)
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0203236:	8a1fe0ef          	jal	ra,ffffffffc0201ad6 <kmalloc>
ffffffffc020323a:	842a                	mv	s0,a0
    if (proc != NULL)
ffffffffc020323c:	cd21                	beqz	a0,ffffffffc0203294 <alloc_proc+0x68>
    {
        // LAB4:EXERCISE1 2310675
        proc->state = PROC_UNINIT;              // 进程初始状态设为“未初始化”，等待进一步配置
ffffffffc020323e:	57fd                	li	a5,-1
ffffffffc0203240:	1782                	slli	a5,a5,0x20
ffffffffc0203242:	e11c                	sd	a5,0(a0)
        proc->runs = 0;                        // 运行次数清零，便于调度器统计
        proc->kstack = 0;                      // 内核栈稍后由setup_kstack分配
        proc->need_resched = 0;                // 初始不请求调度，让调度器按需设置
        proc->parent = NULL;                   // 尚无父进程关系
        proc->mm = NULL;                       // 内核线程共享内核地址空间，此处先置空
        memset(&(proc->context), 0, sizeof(struct context)); // 清空上下文，保证switch_to时有确定初值
ffffffffc0203244:	07000613          	li	a2,112
ffffffffc0203248:	4581                	li	a1,0
        proc->runs = 0;                        // 运行次数清零，便于调度器统计
ffffffffc020324a:	00052423          	sw	zero,8(a0)
        proc->kstack = 0;                      // 内核栈稍后由setup_kstack分配
ffffffffc020324e:	00053823          	sd	zero,16(a0)
        proc->need_resched = 0;                // 初始不请求调度，让调度器按需设置
ffffffffc0203252:	00052c23          	sw	zero,24(a0)
        proc->parent = NULL;                   // 尚无父进程关系
ffffffffc0203256:	02053023          	sd	zero,32(a0)
        proc->mm = NULL;                       // 内核线程共享内核地址空间，此处先置空
ffffffffc020325a:	02053423          	sd	zero,40(a0)
        memset(&(proc->context), 0, sizeof(struct context)); // 清空上下文，保证switch_to时有确定初值
ffffffffc020325e:	03050513          	addi	a0,a0,48
ffffffffc0203262:	431000ef          	jal	ra,ffffffffc0203e92 <memset>
        proc->tf = NULL;                       // trapframe稍后在copy_thread中建立
        proc->pgdir = boot_pgdir_pa;           // 新线程默认使用内核页表，保持同一虚拟空间
ffffffffc0203266:	0000a797          	auipc	a5,0xa
ffffffffc020326a:	23a7b783          	ld	a5,570(a5) # ffffffffc020d4a0 <boot_pgdir_pa>
ffffffffc020326e:	f45c                	sd	a5,168(s0)
        proc->tf = NULL;                       // trapframe稍后在copy_thread中建立
ffffffffc0203270:	0a043023          	sd	zero,160(s0)
        proc->flags = 0;
ffffffffc0203274:	0a042823          	sw	zero,176(s0)
        memset(proc->name, 0, sizeof(proc->name));
ffffffffc0203278:	4641                	li	a2,16
ffffffffc020327a:	4581                	li	a1,0
ffffffffc020327c:	0b440513          	addi	a0,s0,180
ffffffffc0203280:	413000ef          	jal	ra,ffffffffc0203e92 <memset>
        list_init(&(proc->list_link));         // 将链表指针初始化，便于加入全局进程队列
ffffffffc0203284:	0c840713          	addi	a4,s0,200
        list_init(&(proc->hash_link));         // 初始化哈希链表，便于PID快速索引
ffffffffc0203288:	0d840793          	addi	a5,s0,216
    elm->prev = elm->next = elm;
ffffffffc020328c:	e878                	sd	a4,208(s0)
ffffffffc020328e:	e478                	sd	a4,200(s0)
ffffffffc0203290:	f07c                	sd	a5,224(s0)
ffffffffc0203292:	ec7c                	sd	a5,216(s0)
    }
    return proc;
}
ffffffffc0203294:	60a2                	ld	ra,8(sp)
ffffffffc0203296:	8522                	mv	a0,s0
ffffffffc0203298:	6402                	ld	s0,0(sp)
ffffffffc020329a:	0141                	addi	sp,sp,16
ffffffffc020329c:	8082                	ret

ffffffffc020329e <forkret>:
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
static void
forkret(void)
{
    forkrets(current->tf);
ffffffffc020329e:	0000a797          	auipc	a5,0xa
ffffffffc02032a2:	2327b783          	ld	a5,562(a5) # ffffffffc020d4d0 <current>
ffffffffc02032a6:	73c8                	ld	a0,160(a5)
ffffffffc02032a8:	b4dfd06f          	j	ffffffffc0200df4 <forkrets>

ffffffffc02032ac <init_main>:

// init_main - the second kernel thread used to create user_main kernel threads
// 2310675: 第一个真正的内核线程initproc的主函数，本实验只输出欢迎信息
static int
init_main(void *arg)
{
ffffffffc02032ac:	7179                	addi	sp,sp,-48
ffffffffc02032ae:	ec26                	sd	s1,24(sp)
    memset(name, 0, sizeof(name));
ffffffffc02032b0:	0000a497          	auipc	s1,0xa
ffffffffc02032b4:	19848493          	addi	s1,s1,408 # ffffffffc020d448 <name.2>
{
ffffffffc02032b8:	f022                	sd	s0,32(sp)
ffffffffc02032ba:	e84a                	sd	s2,16(sp)
ffffffffc02032bc:	842a                	mv	s0,a0
    // 2310675: 输出当前进程信息，验证进程创建成功
    cprintf("this initproc, pid = %d, name = \"%s\"\n", current->pid, get_proc_name(current));
ffffffffc02032be:	0000a917          	auipc	s2,0xa
ffffffffc02032c2:	21293903          	ld	s2,530(s2) # ffffffffc020d4d0 <current>
    memset(name, 0, sizeof(name));
ffffffffc02032c6:	4641                	li	a2,16
ffffffffc02032c8:	4581                	li	a1,0
ffffffffc02032ca:	8526                	mv	a0,s1
{
ffffffffc02032cc:	f406                	sd	ra,40(sp)
ffffffffc02032ce:	e44e                	sd	s3,8(sp)
    cprintf("this initproc, pid = %d, name = \"%s\"\n", current->pid, get_proc_name(current));
ffffffffc02032d0:	00492983          	lw	s3,4(s2)
    memset(name, 0, sizeof(name));
ffffffffc02032d4:	3bf000ef          	jal	ra,ffffffffc0203e92 <memset>
    return memcpy(name, proc->name, PROC_NAME_LEN);
ffffffffc02032d8:	0b490593          	addi	a1,s2,180
ffffffffc02032dc:	463d                	li	a2,15
ffffffffc02032de:	8526                	mv	a0,s1
ffffffffc02032e0:	3c5000ef          	jal	ra,ffffffffc0203ea4 <memcpy>
ffffffffc02032e4:	862a                	mv	a2,a0
    cprintf("this initproc, pid = %d, name = \"%s\"\n", current->pid, get_proc_name(current));
ffffffffc02032e6:	85ce                	mv	a1,s3
ffffffffc02032e8:	00002517          	auipc	a0,0x2
ffffffffc02032ec:	36850513          	addi	a0,a0,872 # ffffffffc0205650 <default_pmm_manager+0x920>
ffffffffc02032f0:	ea5fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("To U: \"%s\".\n", (const char *)arg);  // 2310675: 输出传入的参数"Hello world!!"
ffffffffc02032f4:	85a2                	mv	a1,s0
ffffffffc02032f6:	00002517          	auipc	a0,0x2
ffffffffc02032fa:	38250513          	addi	a0,a0,898 # ffffffffc0205678 <default_pmm_manager+0x948>
ffffffffc02032fe:	e97fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("To U: \"en.., Bye, Bye. :)\"\n");
ffffffffc0203302:	00002517          	auipc	a0,0x2
ffffffffc0203306:	38650513          	addi	a0,a0,902 # ffffffffc0205688 <default_pmm_manager+0x958>
ffffffffc020330a:	e8bfc0ef          	jal	ra,ffffffffc0200194 <cprintf>
    return 0;  // 2310675: 返回后会调用do_exit退出进程
}
ffffffffc020330e:	70a2                	ld	ra,40(sp)
ffffffffc0203310:	7402                	ld	s0,32(sp)
ffffffffc0203312:	64e2                	ld	s1,24(sp)
ffffffffc0203314:	6942                	ld	s2,16(sp)
ffffffffc0203316:	69a2                	ld	s3,8(sp)
ffffffffc0203318:	4501                	li	a0,0
ffffffffc020331a:	6145                	addi	sp,sp,48
ffffffffc020331c:	8082                	ret

ffffffffc020331e <proc_run>:
{
ffffffffc020331e:	7179                	addi	sp,sp,-48
ffffffffc0203320:	ec4a                	sd	s2,24(sp)
    if (proc != current)
ffffffffc0203322:	0000a917          	auipc	s2,0xa
ffffffffc0203326:	1ae90913          	addi	s2,s2,430 # ffffffffc020d4d0 <current>
{
ffffffffc020332a:	f026                	sd	s1,32(sp)
    if (proc != current)
ffffffffc020332c:	00093483          	ld	s1,0(s2)
{
ffffffffc0203330:	f406                	sd	ra,40(sp)
ffffffffc0203332:	e84e                	sd	s3,16(sp)
    if (proc != current)
ffffffffc0203334:	02a48963          	beq	s1,a0,ffffffffc0203366 <proc_run+0x48>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0203338:	100027f3          	csrr	a5,sstatus
ffffffffc020333c:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc020333e:	4981                	li	s3,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0203340:	e3a1                	bnez	a5,ffffffffc0203380 <proc_run+0x62>
        lsatp(proc->pgdir);                    // 切换satp寄存器，加载目标进程页表基址
ffffffffc0203342:	755c                	ld	a5,168(a0)
#define barrier() __asm__ __volatile__("fence" ::: "memory")

static inline void
lsatp(unsigned int pgdir)
{
  write_csr(satp, SATP32_MODE | (pgdir >> RISCV_PGSHIFT));
ffffffffc0203344:	80000737          	lui	a4,0x80000
        current = proc;                        // 更新当前运行的进程指针
ffffffffc0203348:	00a93023          	sd	a0,0(s2)
ffffffffc020334c:	00c7d79b          	srliw	a5,a5,0xc
ffffffffc0203350:	8fd9                	or	a5,a5,a4
ffffffffc0203352:	18079073          	csrw	satp,a5
        switch_to(&(prev->context), &(proc->context)); // 保存旧上下文，恢复新上下文
ffffffffc0203356:	03050593          	addi	a1,a0,48
ffffffffc020335a:	03048513          	addi	a0,s1,48
ffffffffc020335e:	55e000ef          	jal	ra,ffffffffc02038bc <switch_to>
    if (flag) {
ffffffffc0203362:	00099863          	bnez	s3,ffffffffc0203372 <proc_run+0x54>
}
ffffffffc0203366:	70a2                	ld	ra,40(sp)
ffffffffc0203368:	7482                	ld	s1,32(sp)
ffffffffc020336a:	6962                	ld	s2,24(sp)
ffffffffc020336c:	69c2                	ld	s3,16(sp)
ffffffffc020336e:	6145                	addi	sp,sp,48
ffffffffc0203370:	8082                	ret
ffffffffc0203372:	70a2                	ld	ra,40(sp)
ffffffffc0203374:	7482                	ld	s1,32(sp)
ffffffffc0203376:	6962                	ld	s2,24(sp)
ffffffffc0203378:	69c2                	ld	s3,16(sp)
ffffffffc020337a:	6145                	addi	sp,sp,48
        intr_enable();
ffffffffc020337c:	daefd06f          	j	ffffffffc020092a <intr_enable>
ffffffffc0203380:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0203382:	daefd0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        return 1;
ffffffffc0203386:	6522                	ld	a0,8(sp)
ffffffffc0203388:	4985                	li	s3,1
ffffffffc020338a:	bf65                	j	ffffffffc0203342 <proc_run+0x24>

ffffffffc020338c <do_fork>:
{
ffffffffc020338c:	7179                	addi	sp,sp,-48
ffffffffc020338e:	ec26                	sd	s1,24(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc0203390:	0000a497          	auipc	s1,0xa
ffffffffc0203394:	15848493          	addi	s1,s1,344 # ffffffffc020d4e8 <nr_process>
ffffffffc0203398:	4098                	lw	a4,0(s1)
{
ffffffffc020339a:	f406                	sd	ra,40(sp)
ffffffffc020339c:	f022                	sd	s0,32(sp)
ffffffffc020339e:	e84a                	sd	s2,16(sp)
ffffffffc02033a0:	e44e                	sd	s3,8(sp)
ffffffffc02033a2:	e052                	sd	s4,0(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc02033a4:	6785                	lui	a5,0x1
ffffffffc02033a6:	1ef75863          	bge	a4,a5,ffffffffc0203596 <do_fork+0x20a>
ffffffffc02033aa:	892e                	mv	s2,a1
ffffffffc02033ac:	89b2                	mv	s3,a2
    if ((proc = alloc_proc()) == NULL)
ffffffffc02033ae:	e7fff0ef          	jal	ra,ffffffffc020322c <alloc_proc>
ffffffffc02033b2:	842a                	mv	s0,a0
ffffffffc02033b4:	1e050863          	beqz	a0,ffffffffc02035a4 <do_fork+0x218>
    proc->parent = current; // 记录父进程，便于后续wait/回收等处理
ffffffffc02033b8:	0000aa17          	auipc	s4,0xa
ffffffffc02033bc:	118a0a13          	addi	s4,s4,280 # ffffffffc020d4d0 <current>
ffffffffc02033c0:	000a3783          	ld	a5,0(s4)
    struct Page *page = alloc_pages(KSTACKPAGE);  // 2310675: 分配KSTACKPAGE（2）个连续物理页
ffffffffc02033c4:	4509                	li	a0,2
    proc->parent = current; // 记录父进程，便于后续wait/回收等处理
ffffffffc02033c6:	f01c                	sd	a5,32(s0)
    struct Page *page = alloc_pages(KSTACKPAGE);  // 2310675: 分配KSTACKPAGE（2）个连续物理页
ffffffffc02033c8:	8edfe0ef          	jal	ra,ffffffffc0201cb4 <alloc_pages>
    if (page != NULL)
ffffffffc02033cc:	16050d63          	beqz	a0,ffffffffc0203546 <do_fork+0x1ba>
    return page - pages + nbase;
ffffffffc02033d0:	0000a697          	auipc	a3,0xa
ffffffffc02033d4:	0e86b683          	ld	a3,232(a3) # ffffffffc020d4b8 <pages>
ffffffffc02033d8:	40d506b3          	sub	a3,a0,a3
ffffffffc02033dc:	8699                	srai	a3,a3,0x6
ffffffffc02033de:	00002517          	auipc	a0,0x2
ffffffffc02033e2:	66a53503          	ld	a0,1642(a0) # ffffffffc0205a48 <nbase>
ffffffffc02033e6:	96aa                	add	a3,a3,a0
    return KADDR(page2pa(page));
ffffffffc02033e8:	00c69793          	slli	a5,a3,0xc
ffffffffc02033ec:	83b1                	srli	a5,a5,0xc
ffffffffc02033ee:	0000a717          	auipc	a4,0xa
ffffffffc02033f2:	0c273703          	ld	a4,194(a4) # ffffffffc020d4b0 <npage>
    return page2ppn(page) << PGSHIFT;
ffffffffc02033f6:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02033f8:	1ae7fb63          	bgeu	a5,a4,ffffffffc02035ae <do_fork+0x222>
    assert(current->mm == NULL);  // 2310675: 确保当前是内核线程（mm为NULL）
ffffffffc02033fc:	000a3783          	ld	a5,0(s4)
ffffffffc0203400:	0000a717          	auipc	a4,0xa
ffffffffc0203404:	0c873703          	ld	a4,200(a4) # ffffffffc020d4c8 <va_pa_offset>
ffffffffc0203408:	96ba                	add	a3,a3,a4
ffffffffc020340a:	779c                	ld	a5,40(a5)
        proc->kstack = (uintptr_t)page2kva(page);  // 2310675: 保存内核栈的虚拟地址
ffffffffc020340c:	e814                	sd	a3,16(s0)
    assert(current->mm == NULL);  // 2310675: 确保当前是内核线程（mm为NULL）
ffffffffc020340e:	1a079c63          	bnez	a5,ffffffffc02035c6 <do_fork+0x23a>
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE - sizeof(struct trapframe));
ffffffffc0203412:	6789                	lui	a5,0x2
ffffffffc0203414:	ee078793          	addi	a5,a5,-288 # 1ee0 <kern_entry-0xffffffffc01fe120>
ffffffffc0203418:	96be                	add	a3,a3,a5
    *(proc->tf) = *tf;  // 2310675: 复制父进程传入的trapframe（包含s0=fn, s1=arg, epc=kernel_thread_entry）
ffffffffc020341a:	864e                	mv	a2,s3
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE - sizeof(struct trapframe));
ffffffffc020341c:	f054                	sd	a3,160(s0)
    *(proc->tf) = *tf;  // 2310675: 复制父进程传入的trapframe（包含s0=fn, s1=arg, epc=kernel_thread_entry）
ffffffffc020341e:	87b6                	mv	a5,a3
ffffffffc0203420:	12098893          	addi	a7,s3,288
ffffffffc0203424:	00063803          	ld	a6,0(a2)
ffffffffc0203428:	6608                	ld	a0,8(a2)
ffffffffc020342a:	6a0c                	ld	a1,16(a2)
ffffffffc020342c:	6e18                	ld	a4,24(a2)
ffffffffc020342e:	0107b023          	sd	a6,0(a5)
ffffffffc0203432:	e788                	sd	a0,8(a5)
ffffffffc0203434:	eb8c                	sd	a1,16(a5)
ffffffffc0203436:	ef98                	sd	a4,24(a5)
ffffffffc0203438:	02060613          	addi	a2,a2,32
ffffffffc020343c:	02078793          	addi	a5,a5,32
ffffffffc0203440:	ff1612e3          	bne	a2,a7,ffffffffc0203424 <do_fork+0x98>
    proc->tf->gpr.a0 = 0;
ffffffffc0203444:	0406b823          	sd	zero,80(a3)
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc0203448:	10090b63          	beqz	s2,ffffffffc020355e <do_fork+0x1d2>
    if (++last_pid >= MAX_PID)
ffffffffc020344c:	00006817          	auipc	a6,0x6
ffffffffc0203450:	bdc80813          	addi	a6,a6,-1060 # ffffffffc0209028 <last_pid.1>
ffffffffc0203454:	00082783          	lw	a5,0(a6)
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc0203458:	0126b823          	sd	s2,16(a3)
    proc->context.ra = (uintptr_t)forkret;     // 2310675: switch_to的ret将跳转到forkret
ffffffffc020345c:	00000717          	auipc	a4,0x0
ffffffffc0203460:	e4270713          	addi	a4,a4,-446 # ffffffffc020329e <forkret>
    if (++last_pid >= MAX_PID)
ffffffffc0203464:	0017851b          	addiw	a0,a5,1
    proc->context.ra = (uintptr_t)forkret;     // 2310675: switch_to的ret将跳转到forkret
ffffffffc0203468:	f818                	sd	a4,48(s0)
    proc->context.sp = (uintptr_t)(proc->tf);  // 2310675: 栈指针指向trapframe，作为forkret的参数
ffffffffc020346a:	fc14                	sd	a3,56(s0)
    if (++last_pid >= MAX_PID)
ffffffffc020346c:	00a82023          	sw	a0,0(a6)
ffffffffc0203470:	6789                	lui	a5,0x2
ffffffffc0203472:	0ef55863          	bge	a0,a5,ffffffffc0203562 <do_fork+0x1d6>
    if (last_pid >= next_safe)
ffffffffc0203476:	00006317          	auipc	t1,0x6
ffffffffc020347a:	bb630313          	addi	t1,t1,-1098 # ffffffffc020902c <next_safe.0>
ffffffffc020347e:	00032783          	lw	a5,0(t1)
ffffffffc0203482:	0000a917          	auipc	s2,0xa
ffffffffc0203486:	fd690913          	addi	s2,s2,-42 # ffffffffc020d458 <proc_list>
ffffffffc020348a:	06f54063          	blt	a0,a5,ffffffffc02034ea <do_fork+0x15e>
    return listelm->next;
ffffffffc020348e:	0000a917          	auipc	s2,0xa
ffffffffc0203492:	fca90913          	addi	s2,s2,-54 # ffffffffc020d458 <proc_list>
ffffffffc0203496:	00893e03          	ld	t3,8(s2)
        next_safe = MAX_PID;
ffffffffc020349a:	6789                	lui	a5,0x2
ffffffffc020349c:	00f32023          	sw	a5,0(t1)
ffffffffc02034a0:	86aa                	mv	a3,a0
ffffffffc02034a2:	4581                	li	a1,0
        while ((le = list_next(le)) != list)
ffffffffc02034a4:	6e89                	lui	t4,0x2
ffffffffc02034a6:	0f2e0a63          	beq	t3,s2,ffffffffc020359a <do_fork+0x20e>
ffffffffc02034aa:	88ae                	mv	a7,a1
ffffffffc02034ac:	87f2                	mv	a5,t3
ffffffffc02034ae:	6609                	lui	a2,0x2
ffffffffc02034b0:	a811                	j	ffffffffc02034c4 <do_fork+0x138>
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc02034b2:	00e6d663          	bge	a3,a4,ffffffffc02034be <do_fork+0x132>
ffffffffc02034b6:	00c75463          	bge	a4,a2,ffffffffc02034be <do_fork+0x132>
ffffffffc02034ba:	863a                	mv	a2,a4
ffffffffc02034bc:	4885                	li	a7,1
ffffffffc02034be:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc02034c0:	01278d63          	beq	a5,s2,ffffffffc02034da <do_fork+0x14e>
            if (proc->pid == last_pid)
ffffffffc02034c4:	f3c7a703          	lw	a4,-196(a5) # 1f3c <kern_entry-0xffffffffc01fe0c4>
ffffffffc02034c8:	fed715e3          	bne	a4,a3,ffffffffc02034b2 <do_fork+0x126>
                if (++last_pid >= next_safe)
ffffffffc02034cc:	2685                	addiw	a3,a3,1
ffffffffc02034ce:	0ac6df63          	bge	a3,a2,ffffffffc020358c <do_fork+0x200>
ffffffffc02034d2:	679c                	ld	a5,8(a5)
ffffffffc02034d4:	4585                	li	a1,1
        while ((le = list_next(le)) != list)
ffffffffc02034d6:	ff2797e3          	bne	a5,s2,ffffffffc02034c4 <do_fork+0x138>
ffffffffc02034da:	c581                	beqz	a1,ffffffffc02034e2 <do_fork+0x156>
ffffffffc02034dc:	00d82023          	sw	a3,0(a6)
ffffffffc02034e0:	8536                	mv	a0,a3
ffffffffc02034e2:	00088463          	beqz	a7,ffffffffc02034ea <do_fork+0x15e>
ffffffffc02034e6:	00c32023          	sw	a2,0(t1)
    proc->pid = get_pid();
ffffffffc02034ea:	c048                	sw	a0,4(s0)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc02034ec:	45a9                	li	a1,10
ffffffffc02034ee:	2501                	sext.w	a0,a0
ffffffffc02034f0:	4fc000ef          	jal	ra,ffffffffc02039ec <hash32>
ffffffffc02034f4:	02051793          	slli	a5,a0,0x20
ffffffffc02034f8:	01c7d513          	srli	a0,a5,0x1c
ffffffffc02034fc:	00006797          	auipc	a5,0x6
ffffffffc0203500:	f4c78793          	addi	a5,a5,-180 # ffffffffc0209448 <hash_list>
ffffffffc0203504:	953e                	add	a0,a0,a5
    __list_add(elm, listelm, listelm->next);
ffffffffc0203506:	6518                	ld	a4,8(a0)
ffffffffc0203508:	0d840793          	addi	a5,s0,216
ffffffffc020350c:	00893683          	ld	a3,8(s2)
    prev->next = next->prev = elm;
ffffffffc0203510:	e31c                	sd	a5,0(a4)
ffffffffc0203512:	e51c                	sd	a5,8(a0)
    nr_process++;
ffffffffc0203514:	409c                	lw	a5,0(s1)
    elm->next = next;
ffffffffc0203516:	f078                	sd	a4,224(s0)
    elm->prev = prev;
ffffffffc0203518:	ec68                	sd	a0,216(s0)
    list_add(&proc_list, &(proc->list_link));
ffffffffc020351a:	0c840713          	addi	a4,s0,200
    prev->next = next->prev = elm;
ffffffffc020351e:	e298                	sd	a4,0(a3)
    elm->prev = prev;
ffffffffc0203520:	0d243423          	sd	s2,200(s0)
    wakeup_proc(proc);
ffffffffc0203524:	8522                	mv	a0,s0
    nr_process++;
ffffffffc0203526:	2785                	addiw	a5,a5,1
    elm->next = next;
ffffffffc0203528:	e874                	sd	a3,208(s0)
    prev->next = next->prev = elm;
ffffffffc020352a:	00e93423          	sd	a4,8(s2)
ffffffffc020352e:	c09c                	sw	a5,0(s1)
    wakeup_proc(proc);
ffffffffc0203530:	3f6000ef          	jal	ra,ffffffffc0203926 <wakeup_proc>
    ret = proc->pid;   // 7. 返回子进程PID给父进程，用于区分父子执行路径
ffffffffc0203534:	4048                	lw	a0,4(s0)
}
ffffffffc0203536:	70a2                	ld	ra,40(sp)
ffffffffc0203538:	7402                	ld	s0,32(sp)
ffffffffc020353a:	64e2                	ld	s1,24(sp)
ffffffffc020353c:	6942                	ld	s2,16(sp)
ffffffffc020353e:	69a2                	ld	s3,8(sp)
ffffffffc0203540:	6a02                	ld	s4,0(sp)
ffffffffc0203542:	6145                	addi	sp,sp,48
ffffffffc0203544:	8082                	ret
    kfree(proc);
ffffffffc0203546:	8522                	mv	a0,s0
ffffffffc0203548:	e3efe0ef          	jal	ra,ffffffffc0201b86 <kfree>
    return -E_NO_MEM;  // 2310675: 分配失败，返回内存不足错误
ffffffffc020354c:	5571                	li	a0,-4
}
ffffffffc020354e:	70a2                	ld	ra,40(sp)
ffffffffc0203550:	7402                	ld	s0,32(sp)
ffffffffc0203552:	64e2                	ld	s1,24(sp)
ffffffffc0203554:	6942                	ld	s2,16(sp)
ffffffffc0203556:	69a2                	ld	s3,8(sp)
ffffffffc0203558:	6a02                	ld	s4,0(sp)
ffffffffc020355a:	6145                	addi	sp,sp,48
ffffffffc020355c:	8082                	ret
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc020355e:	8936                	mv	s2,a3
ffffffffc0203560:	b5f5                	j	ffffffffc020344c <do_fork+0xc0>
        last_pid = 1;
ffffffffc0203562:	4785                	li	a5,1
ffffffffc0203564:	00f82023          	sw	a5,0(a6)
        goto inside;
ffffffffc0203568:	4505                	li	a0,1
ffffffffc020356a:	00006317          	auipc	t1,0x6
ffffffffc020356e:	ac230313          	addi	t1,t1,-1342 # ffffffffc020902c <next_safe.0>
    return listelm->next;
ffffffffc0203572:	0000a917          	auipc	s2,0xa
ffffffffc0203576:	ee690913          	addi	s2,s2,-282 # ffffffffc020d458 <proc_list>
        next_safe = MAX_PID;
ffffffffc020357a:	6789                	lui	a5,0x2
ffffffffc020357c:	00893e03          	ld	t3,8(s2)
ffffffffc0203580:	00f32023          	sw	a5,0(t1)
ffffffffc0203584:	86aa                	mv	a3,a0
ffffffffc0203586:	4581                	li	a1,0
        while ((le = list_next(le)) != list)
ffffffffc0203588:	6e89                	lui	t4,0x2
ffffffffc020358a:	bf31                	j	ffffffffc02034a6 <do_fork+0x11a>
                    if (last_pid >= MAX_PID)
ffffffffc020358c:	01d6c363          	blt	a3,t4,ffffffffc0203592 <do_fork+0x206>
                        last_pid = 1;
ffffffffc0203590:	4685                	li	a3,1
                    goto repeat;
ffffffffc0203592:	4585                	li	a1,1
ffffffffc0203594:	bf09                	j	ffffffffc02034a6 <do_fork+0x11a>
    int ret = -E_NO_FREE_PROC;
ffffffffc0203596:	556d                	li	a0,-5
ffffffffc0203598:	bf5d                	j	ffffffffc020354e <do_fork+0x1c2>
ffffffffc020359a:	c599                	beqz	a1,ffffffffc02035a8 <do_fork+0x21c>
ffffffffc020359c:	00d82023          	sw	a3,0(a6)
    return last_pid;
ffffffffc02035a0:	8536                	mv	a0,a3
ffffffffc02035a2:	b7a1                	j	ffffffffc02034ea <do_fork+0x15e>
    ret = -E_NO_MEM;
ffffffffc02035a4:	5571                	li	a0,-4
    return ret;
ffffffffc02035a6:	b765                	j	ffffffffc020354e <do_fork+0x1c2>
    return last_pid;
ffffffffc02035a8:	00082503          	lw	a0,0(a6)
ffffffffc02035ac:	bf3d                	j	ffffffffc02034ea <do_fork+0x15e>
ffffffffc02035ae:	00001617          	auipc	a2,0x1
ffffffffc02035b2:	7ba60613          	addi	a2,a2,1978 # ffffffffc0204d68 <default_pmm_manager+0x38>
ffffffffc02035b6:	07100593          	li	a1,113
ffffffffc02035ba:	00001517          	auipc	a0,0x1
ffffffffc02035be:	7d650513          	addi	a0,a0,2006 # ffffffffc0204d90 <default_pmm_manager+0x60>
ffffffffc02035c2:	e99fc0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(current->mm == NULL);  // 2310675: 确保当前是内核线程（mm为NULL）
ffffffffc02035c6:	00002697          	auipc	a3,0x2
ffffffffc02035ca:	0e268693          	addi	a3,a3,226 # ffffffffc02056a8 <default_pmm_manager+0x978>
ffffffffc02035ce:	00001617          	auipc	a2,0x1
ffffffffc02035d2:	3b260613          	addi	a2,a2,946 # ffffffffc0204980 <commands+0x838>
ffffffffc02035d6:	10a00593          	li	a1,266
ffffffffc02035da:	00002517          	auipc	a0,0x2
ffffffffc02035de:	0e650513          	addi	a0,a0,230 # ffffffffc02056c0 <default_pmm_manager+0x990>
ffffffffc02035e2:	e79fc0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc02035e6 <kernel_thread>:
{
ffffffffc02035e6:	7129                	addi	sp,sp,-320
ffffffffc02035e8:	fa22                	sd	s0,304(sp)
ffffffffc02035ea:	f626                	sd	s1,296(sp)
ffffffffc02035ec:	f24a                	sd	s2,288(sp)
ffffffffc02035ee:	84ae                	mv	s1,a1
ffffffffc02035f0:	892a                	mv	s2,a0
ffffffffc02035f2:	8432                	mv	s0,a2
    memset(&tf, 0, sizeof(struct trapframe));  // 2310675: 清零trapframe，保证未设置字段为0
ffffffffc02035f4:	4581                	li	a1,0
ffffffffc02035f6:	12000613          	li	a2,288
ffffffffc02035fa:	850a                	mv	a0,sp
{
ffffffffc02035fc:	fe06                	sd	ra,312(sp)
    memset(&tf, 0, sizeof(struct trapframe));  // 2310675: 清零trapframe，保证未设置字段为0
ffffffffc02035fe:	095000ef          	jal	ra,ffffffffc0203e92 <memset>
    tf.gpr.s0 = (uintptr_t)fn;                 // 2310675: s0保存线程函数指针（如init_main）
ffffffffc0203602:	e0ca                	sd	s2,64(sp)
    tf.gpr.s1 = (uintptr_t)arg;                // 2310675: s1保存函数参数（如"Hello world!!"）
ffffffffc0203604:	e4a6                	sd	s1,72(sp)
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc0203606:	100027f3          	csrr	a5,sstatus
ffffffffc020360a:	edd7f793          	andi	a5,a5,-291
ffffffffc020360e:	1207e793          	ori	a5,a5,288
ffffffffc0203612:	e23e                	sd	a5,256(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);  // 2310675: 调用do_fork创建线程
ffffffffc0203614:	860a                	mv	a2,sp
ffffffffc0203616:	10046513          	ori	a0,s0,256
    tf.epc = (uintptr_t)kernel_thread_entry;   // 2310675: 设置epc为统一的内核线程入口
ffffffffc020361a:	00000797          	auipc	a5,0x0
ffffffffc020361e:	c0a78793          	addi	a5,a5,-1014 # ffffffffc0203224 <kernel_thread_entry>
    return do_fork(clone_flags | CLONE_VM, 0, &tf);  // 2310675: 调用do_fork创建线程
ffffffffc0203622:	4581                	li	a1,0
    tf.epc = (uintptr_t)kernel_thread_entry;   // 2310675: 设置epc为统一的内核线程入口
ffffffffc0203624:	e63e                	sd	a5,264(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);  // 2310675: 调用do_fork创建线程
ffffffffc0203626:	d67ff0ef          	jal	ra,ffffffffc020338c <do_fork>
}
ffffffffc020362a:	70f2                	ld	ra,312(sp)
ffffffffc020362c:	7452                	ld	s0,304(sp)
ffffffffc020362e:	74b2                	ld	s1,296(sp)
ffffffffc0203630:	7912                	ld	s2,288(sp)
ffffffffc0203632:	6131                	addi	sp,sp,320
ffffffffc0203634:	8082                	ret

ffffffffc0203636 <do_exit>:
{
ffffffffc0203636:	1141                	addi	sp,sp,-16
    panic("process exit!!.\n");
ffffffffc0203638:	00002617          	auipc	a2,0x2
ffffffffc020363c:	0a060613          	addi	a2,a2,160 # ffffffffc02056d8 <default_pmm_manager+0x9a8>
ffffffffc0203640:	16400593          	li	a1,356
ffffffffc0203644:	00002517          	auipc	a0,0x2
ffffffffc0203648:	07c50513          	addi	a0,a0,124 # ffffffffc02056c0 <default_pmm_manager+0x990>
{
ffffffffc020364c:	e406                	sd	ra,8(sp)
    panic("process exit!!.\n");
ffffffffc020364e:	e0dfc0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0203652 <proc_init>:

// proc_init - set up the first kernel thread idleproc "idle" by itself and
//           - create the second kernel thread init_main
// 2310675: 进程管理初始化函数，创建idleproc（0号）和initproc（1号）两个内核线程
void proc_init(void)
{
ffffffffc0203652:	7179                	addi	sp,sp,-48
ffffffffc0203654:	ec26                	sd	s1,24(sp)
    elm->prev = elm->next = elm;
ffffffffc0203656:	0000a797          	auipc	a5,0xa
ffffffffc020365a:	e0278793          	addi	a5,a5,-510 # ffffffffc020d458 <proc_list>
ffffffffc020365e:	f406                	sd	ra,40(sp)
ffffffffc0203660:	f022                	sd	s0,32(sp)
ffffffffc0203662:	e84a                	sd	s2,16(sp)
ffffffffc0203664:	e44e                	sd	s3,8(sp)
ffffffffc0203666:	00006497          	auipc	s1,0x6
ffffffffc020366a:	de248493          	addi	s1,s1,-542 # ffffffffc0209448 <hash_list>
ffffffffc020366e:	e79c                	sd	a5,8(a5)
ffffffffc0203670:	e39c                	sd	a5,0(a5)
    int i;

    // 2310675: 初始化全局进程链表和PID哈希表
    list_init(&proc_list);
    for (i = 0; i < HASH_LIST_SIZE; i++)
ffffffffc0203672:	0000a717          	auipc	a4,0xa
ffffffffc0203676:	dd670713          	addi	a4,a4,-554 # ffffffffc020d448 <name.2>
ffffffffc020367a:	87a6                	mv	a5,s1
ffffffffc020367c:	e79c                	sd	a5,8(a5)
ffffffffc020367e:	e39c                	sd	a5,0(a5)
ffffffffc0203680:	07c1                	addi	a5,a5,16
ffffffffc0203682:	fef71de3          	bne	a4,a5,ffffffffc020367c <proc_init+0x2a>
    {
        list_init(hash_list + i);
    }

    // 2310675: 分配并初始化idleproc（第0个内核线程）
    if ((idleproc = alloc_proc()) == NULL)
ffffffffc0203686:	ba7ff0ef          	jal	ra,ffffffffc020322c <alloc_proc>
ffffffffc020368a:	0000a917          	auipc	s2,0xa
ffffffffc020368e:	e4e90913          	addi	s2,s2,-434 # ffffffffc020d4d8 <idleproc>
ffffffffc0203692:	00a93023          	sd	a0,0(s2)
ffffffffc0203696:	18050d63          	beqz	a0,ffffffffc0203830 <proc_init+0x1de>
    {
        panic("cannot alloc idleproc.\n");
    }

    // check the proc structure
    int *context_mem = (int *)kmalloc(sizeof(struct context));
ffffffffc020369a:	07000513          	li	a0,112
ffffffffc020369e:	c38fe0ef          	jal	ra,ffffffffc0201ad6 <kmalloc>
    memset(context_mem, 0, sizeof(struct context));
ffffffffc02036a2:	07000613          	li	a2,112
ffffffffc02036a6:	4581                	li	a1,0
    int *context_mem = (int *)kmalloc(sizeof(struct context));
ffffffffc02036a8:	842a                	mv	s0,a0
    memset(context_mem, 0, sizeof(struct context));
ffffffffc02036aa:	7e8000ef          	jal	ra,ffffffffc0203e92 <memset>
    int context_init_flag = memcmp(&(idleproc->context), context_mem, sizeof(struct context));
ffffffffc02036ae:	00093503          	ld	a0,0(s2)
ffffffffc02036b2:	85a2                	mv	a1,s0
ffffffffc02036b4:	07000613          	li	a2,112
ffffffffc02036b8:	03050513          	addi	a0,a0,48
ffffffffc02036bc:	001000ef          	jal	ra,ffffffffc0203ebc <memcmp>
ffffffffc02036c0:	89aa                	mv	s3,a0

    int *proc_name_mem = (int *)kmalloc(PROC_NAME_LEN);
ffffffffc02036c2:	453d                	li	a0,15
ffffffffc02036c4:	c12fe0ef          	jal	ra,ffffffffc0201ad6 <kmalloc>
    memset(proc_name_mem, 0, PROC_NAME_LEN);
ffffffffc02036c8:	463d                	li	a2,15
ffffffffc02036ca:	4581                	li	a1,0
    int *proc_name_mem = (int *)kmalloc(PROC_NAME_LEN);
ffffffffc02036cc:	842a                	mv	s0,a0
    memset(proc_name_mem, 0, PROC_NAME_LEN);
ffffffffc02036ce:	7c4000ef          	jal	ra,ffffffffc0203e92 <memset>
    int proc_name_flag = memcmp(&(idleproc->name), proc_name_mem, PROC_NAME_LEN);
ffffffffc02036d2:	00093503          	ld	a0,0(s2)
ffffffffc02036d6:	463d                	li	a2,15
ffffffffc02036d8:	85a2                	mv	a1,s0
ffffffffc02036da:	0b450513          	addi	a0,a0,180
ffffffffc02036de:	7de000ef          	jal	ra,ffffffffc0203ebc <memcmp>

    if (idleproc->pgdir == boot_pgdir_pa && idleproc->tf == NULL && !context_init_flag && idleproc->state == PROC_UNINIT && idleproc->pid == -1 && idleproc->runs == 0 && idleproc->kstack == 0 && idleproc->need_resched == 0 && idleproc->parent == NULL && idleproc->mm == NULL && idleproc->flags == 0 && !proc_name_flag)
ffffffffc02036e2:	00093783          	ld	a5,0(s2)
ffffffffc02036e6:	0000a717          	auipc	a4,0xa
ffffffffc02036ea:	dba73703          	ld	a4,-582(a4) # ffffffffc020d4a0 <boot_pgdir_pa>
ffffffffc02036ee:	77d4                	ld	a3,168(a5)
ffffffffc02036f0:	0ee68463          	beq	a3,a4,ffffffffc02037d8 <proc_init+0x186>
        cprintf("alloc_proc() correct!\n");
    }

    // 2310675: 为idleproc设置特殊属性（pid=0，使用bootstack，立即请求调度）
    idleproc->pid = 0;                         // 2310675: idleproc的PID固定为0
    idleproc->state = PROC_RUNNABLE;           // 2310675: 设置为就绪状态
ffffffffc02036f4:	4709                	li	a4,2
ffffffffc02036f6:	e398                	sd	a4,0(a5)
    idleproc->kstack = (uintptr_t)bootstack;   // 2310675: 使用boot时的栈，不需要重新分配
ffffffffc02036f8:	00003717          	auipc	a4,0x3
ffffffffc02036fc:	90870713          	addi	a4,a4,-1784 # ffffffffc0206000 <bootstack>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0203700:	0b478413          	addi	s0,a5,180
    idleproc->kstack = (uintptr_t)bootstack;   // 2310675: 使用boot时的栈，不需要重新分配
ffffffffc0203704:	eb98                	sd	a4,16(a5)
    idleproc->need_resched = 1;                // 2310675: 立即请求调度，让出CPU给initproc
ffffffffc0203706:	4705                	li	a4,1
ffffffffc0203708:	cf98                	sw	a4,24(a5)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc020370a:	4641                	li	a2,16
ffffffffc020370c:	4581                	li	a1,0
ffffffffc020370e:	8522                	mv	a0,s0
ffffffffc0203710:	782000ef          	jal	ra,ffffffffc0203e92 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0203714:	463d                	li	a2,15
ffffffffc0203716:	00002597          	auipc	a1,0x2
ffffffffc020371a:	00a58593          	addi	a1,a1,10 # ffffffffc0205720 <default_pmm_manager+0x9f0>
ffffffffc020371e:	8522                	mv	a0,s0
ffffffffc0203720:	784000ef          	jal	ra,ffffffffc0203ea4 <memcpy>
    set_proc_name(idleproc, "idle");
    nr_process++;
ffffffffc0203724:	0000a717          	auipc	a4,0xa
ffffffffc0203728:	dc470713          	addi	a4,a4,-572 # ffffffffc020d4e8 <nr_process>
ffffffffc020372c:	431c                	lw	a5,0(a4)

    current = idleproc;  // 2310675: 设置idleproc为当前进程
ffffffffc020372e:	00093683          	ld	a3,0(s2)

    // 2310675: 创建第一个真正的内核线程initproc（1号进程）
    int pid = kernel_thread(init_main, "Hello world!!", 0);
ffffffffc0203732:	4601                	li	a2,0
    nr_process++;
ffffffffc0203734:	2785                	addiw	a5,a5,1
    int pid = kernel_thread(init_main, "Hello world!!", 0);
ffffffffc0203736:	00002597          	auipc	a1,0x2
ffffffffc020373a:	ff258593          	addi	a1,a1,-14 # ffffffffc0205728 <default_pmm_manager+0x9f8>
ffffffffc020373e:	00000517          	auipc	a0,0x0
ffffffffc0203742:	b6e50513          	addi	a0,a0,-1170 # ffffffffc02032ac <init_main>
    nr_process++;
ffffffffc0203746:	c31c                	sw	a5,0(a4)
    current = idleproc;  // 2310675: 设置idleproc为当前进程
ffffffffc0203748:	0000a797          	auipc	a5,0xa
ffffffffc020374c:	d8d7b423          	sd	a3,-632(a5) # ffffffffc020d4d0 <current>
    int pid = kernel_thread(init_main, "Hello world!!", 0);
ffffffffc0203750:	e97ff0ef          	jal	ra,ffffffffc02035e6 <kernel_thread>
ffffffffc0203754:	842a                	mv	s0,a0
    if (pid <= 0)
ffffffffc0203756:	0ea05963          	blez	a0,ffffffffc0203848 <proc_init+0x1f6>
    if (0 < pid && pid < MAX_PID)
ffffffffc020375a:	6789                	lui	a5,0x2
ffffffffc020375c:	fff5071b          	addiw	a4,a0,-1
ffffffffc0203760:	17f9                	addi	a5,a5,-2
ffffffffc0203762:	2501                	sext.w	a0,a0
ffffffffc0203764:	02e7e363          	bltu	a5,a4,ffffffffc020378a <proc_init+0x138>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0203768:	45a9                	li	a1,10
ffffffffc020376a:	282000ef          	jal	ra,ffffffffc02039ec <hash32>
ffffffffc020376e:	02051793          	slli	a5,a0,0x20
ffffffffc0203772:	01c7d693          	srli	a3,a5,0x1c
ffffffffc0203776:	96a6                	add	a3,a3,s1
ffffffffc0203778:	87b6                	mv	a5,a3
        while ((le = list_next(le)) != list)
ffffffffc020377a:	a029                	j	ffffffffc0203784 <proc_init+0x132>
            if (proc->pid == pid)
ffffffffc020377c:	f2c7a703          	lw	a4,-212(a5) # 1f2c <kern_entry-0xffffffffc01fe0d4>
ffffffffc0203780:	0a870563          	beq	a4,s0,ffffffffc020382a <proc_init+0x1d8>
    return listelm->next;
ffffffffc0203784:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0203786:	fef69be3          	bne	a3,a5,ffffffffc020377c <proc_init+0x12a>
    return NULL;
ffffffffc020378a:	4781                	li	a5,0
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc020378c:	0b478493          	addi	s1,a5,180
ffffffffc0203790:	4641                	li	a2,16
ffffffffc0203792:	4581                	li	a1,0
    {
        panic("create init_main failed.\n");
    }

    // 2310675: 通过PID找到initproc并设置进程名
    initproc = find_proc(pid);
ffffffffc0203794:	0000a417          	auipc	s0,0xa
ffffffffc0203798:	d4c40413          	addi	s0,s0,-692 # ffffffffc020d4e0 <initproc>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc020379c:	8526                	mv	a0,s1
    initproc = find_proc(pid);
ffffffffc020379e:	e01c                	sd	a5,0(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02037a0:	6f2000ef          	jal	ra,ffffffffc0203e92 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc02037a4:	463d                	li	a2,15
ffffffffc02037a6:	00002597          	auipc	a1,0x2
ffffffffc02037aa:	fb258593          	addi	a1,a1,-78 # ffffffffc0205758 <default_pmm_manager+0xa28>
ffffffffc02037ae:	8526                	mv	a0,s1
ffffffffc02037b0:	6f4000ef          	jal	ra,ffffffffc0203ea4 <memcpy>
    set_proc_name(initproc, "init");

    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc02037b4:	00093783          	ld	a5,0(s2)
ffffffffc02037b8:	c7e1                	beqz	a5,ffffffffc0203880 <proc_init+0x22e>
ffffffffc02037ba:	43dc                	lw	a5,4(a5)
ffffffffc02037bc:	e3f1                	bnez	a5,ffffffffc0203880 <proc_init+0x22e>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc02037be:	601c                	ld	a5,0(s0)
ffffffffc02037c0:	c3c5                	beqz	a5,ffffffffc0203860 <proc_init+0x20e>
ffffffffc02037c2:	43d8                	lw	a4,4(a5)
ffffffffc02037c4:	4785                	li	a5,1
ffffffffc02037c6:	08f71d63          	bne	a4,a5,ffffffffc0203860 <proc_init+0x20e>
}
ffffffffc02037ca:	70a2                	ld	ra,40(sp)
ffffffffc02037cc:	7402                	ld	s0,32(sp)
ffffffffc02037ce:	64e2                	ld	s1,24(sp)
ffffffffc02037d0:	6942                	ld	s2,16(sp)
ffffffffc02037d2:	69a2                	ld	s3,8(sp)
ffffffffc02037d4:	6145                	addi	sp,sp,48
ffffffffc02037d6:	8082                	ret
    if (idleproc->pgdir == boot_pgdir_pa && idleproc->tf == NULL && !context_init_flag && idleproc->state == PROC_UNINIT && idleproc->pid == -1 && idleproc->runs == 0 && idleproc->kstack == 0 && idleproc->need_resched == 0 && idleproc->parent == NULL && idleproc->mm == NULL && idleproc->flags == 0 && !proc_name_flag)
ffffffffc02037d8:	73d8                	ld	a4,160(a5)
ffffffffc02037da:	ff09                	bnez	a4,ffffffffc02036f4 <proc_init+0xa2>
ffffffffc02037dc:	f0099ce3          	bnez	s3,ffffffffc02036f4 <proc_init+0xa2>
ffffffffc02037e0:	6394                	ld	a3,0(a5)
ffffffffc02037e2:	577d                	li	a4,-1
ffffffffc02037e4:	1702                	slli	a4,a4,0x20
ffffffffc02037e6:	f0e697e3          	bne	a3,a4,ffffffffc02036f4 <proc_init+0xa2>
ffffffffc02037ea:	4798                	lw	a4,8(a5)
ffffffffc02037ec:	f00714e3          	bnez	a4,ffffffffc02036f4 <proc_init+0xa2>
ffffffffc02037f0:	6b98                	ld	a4,16(a5)
ffffffffc02037f2:	f00711e3          	bnez	a4,ffffffffc02036f4 <proc_init+0xa2>
ffffffffc02037f6:	4f98                	lw	a4,24(a5)
ffffffffc02037f8:	2701                	sext.w	a4,a4
ffffffffc02037fa:	ee071de3          	bnez	a4,ffffffffc02036f4 <proc_init+0xa2>
ffffffffc02037fe:	7398                	ld	a4,32(a5)
ffffffffc0203800:	ee071ae3          	bnez	a4,ffffffffc02036f4 <proc_init+0xa2>
ffffffffc0203804:	7798                	ld	a4,40(a5)
ffffffffc0203806:	ee0717e3          	bnez	a4,ffffffffc02036f4 <proc_init+0xa2>
ffffffffc020380a:	0b07a703          	lw	a4,176(a5)
ffffffffc020380e:	8d59                	or	a0,a0,a4
ffffffffc0203810:	0005071b          	sext.w	a4,a0
ffffffffc0203814:	ee0710e3          	bnez	a4,ffffffffc02036f4 <proc_init+0xa2>
        cprintf("alloc_proc() correct!\n");
ffffffffc0203818:	00002517          	auipc	a0,0x2
ffffffffc020381c:	ef050513          	addi	a0,a0,-272 # ffffffffc0205708 <default_pmm_manager+0x9d8>
ffffffffc0203820:	975fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
    idleproc->pid = 0;                         // 2310675: idleproc的PID固定为0
ffffffffc0203824:	00093783          	ld	a5,0(s2)
ffffffffc0203828:	b5f1                	j	ffffffffc02036f4 <proc_init+0xa2>
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc020382a:	f2878793          	addi	a5,a5,-216
ffffffffc020382e:	bfb9                	j	ffffffffc020378c <proc_init+0x13a>
        panic("cannot alloc idleproc.\n");
ffffffffc0203830:	00002617          	auipc	a2,0x2
ffffffffc0203834:	ec060613          	addi	a2,a2,-320 # ffffffffc02056f0 <default_pmm_manager+0x9c0>
ffffffffc0203838:	18400593          	li	a1,388
ffffffffc020383c:	00002517          	auipc	a0,0x2
ffffffffc0203840:	e8450513          	addi	a0,a0,-380 # ffffffffc02056c0 <default_pmm_manager+0x990>
ffffffffc0203844:	c17fc0ef          	jal	ra,ffffffffc020045a <__panic>
        panic("create init_main failed.\n");
ffffffffc0203848:	00002617          	auipc	a2,0x2
ffffffffc020384c:	ef060613          	addi	a2,a2,-272 # ffffffffc0205738 <default_pmm_manager+0xa08>
ffffffffc0203850:	1a300593          	li	a1,419
ffffffffc0203854:	00002517          	auipc	a0,0x2
ffffffffc0203858:	e6c50513          	addi	a0,a0,-404 # ffffffffc02056c0 <default_pmm_manager+0x990>
ffffffffc020385c:	bfffc0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0203860:	00002697          	auipc	a3,0x2
ffffffffc0203864:	f2868693          	addi	a3,a3,-216 # ffffffffc0205788 <default_pmm_manager+0xa58>
ffffffffc0203868:	00001617          	auipc	a2,0x1
ffffffffc020386c:	11860613          	addi	a2,a2,280 # ffffffffc0204980 <commands+0x838>
ffffffffc0203870:	1ab00593          	li	a1,427
ffffffffc0203874:	00002517          	auipc	a0,0x2
ffffffffc0203878:	e4c50513          	addi	a0,a0,-436 # ffffffffc02056c0 <default_pmm_manager+0x990>
ffffffffc020387c:	bdffc0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0203880:	00002697          	auipc	a3,0x2
ffffffffc0203884:	ee068693          	addi	a3,a3,-288 # ffffffffc0205760 <default_pmm_manager+0xa30>
ffffffffc0203888:	00001617          	auipc	a2,0x1
ffffffffc020388c:	0f860613          	addi	a2,a2,248 # ffffffffc0204980 <commands+0x838>
ffffffffc0203890:	1aa00593          	li	a1,426
ffffffffc0203894:	00002517          	auipc	a0,0x2
ffffffffc0203898:	e2c50513          	addi	a0,a0,-468 # ffffffffc02056c0 <default_pmm_manager+0x990>
ffffffffc020389c:	bbffc0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc02038a0 <cpu_idle>:

// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
// 2310675: idleproc的主循环，不断检查need_resched并调用调度器
void cpu_idle(void)
{
ffffffffc02038a0:	1141                	addi	sp,sp,-16
ffffffffc02038a2:	e022                	sd	s0,0(sp)
ffffffffc02038a4:	e406                	sd	ra,8(sp)
ffffffffc02038a6:	0000a417          	auipc	s0,0xa
ffffffffc02038aa:	c2a40413          	addi	s0,s0,-982 # ffffffffc020d4d0 <current>
    while (1)  // 2310675: 无限循环，系统空闲时占位
    {
        if (current->need_resched)  // 2310675: 检查是否需要调度
ffffffffc02038ae:	6018                	ld	a4,0(s0)
ffffffffc02038b0:	4f1c                	lw	a5,24(a4)
ffffffffc02038b2:	2781                	sext.w	a5,a5
ffffffffc02038b4:	dff5                	beqz	a5,ffffffffc02038b0 <cpu_idle+0x10>
        {
            schedule();  // 2310675: 调用调度器，切换到其他就绪进程
ffffffffc02038b6:	0a2000ef          	jal	ra,ffffffffc0203958 <schedule>
ffffffffc02038ba:	bfd5                	j	ffffffffc02038ae <cpu_idle+0xe>

ffffffffc02038bc <switch_to>:
.globl switch_to
switch_to:
    # save from's registers
    # 2310675: a0指向旧进程的context结构（&prev->context），保存被调用者保存寄存器
    # 为什么只保存这些寄存器？因为caller-saved寄存器（t0-t6,a0-a7）已由编译器保存到栈上
    STORE ra, 0*REGBYTES(a0)      # 2310675: 保存返回地址，ret时跳转到这里
ffffffffc02038bc:	00153023          	sd	ra,0(a0)
    STORE sp, 1*REGBYTES(a0)      # 2310675: 保存栈指针，切换回来时恢复栈
ffffffffc02038c0:	00253423          	sd	sp,8(a0)
    STORE s0, 2*REGBYTES(a0)      # 2310675: 保存s0-s11寄存器（callee-saved）
ffffffffc02038c4:	e900                	sd	s0,16(a0)
    STORE s1, 3*REGBYTES(a0)
ffffffffc02038c6:	ed04                	sd	s1,24(a0)
    STORE s2, 4*REGBYTES(a0)
ffffffffc02038c8:	03253023          	sd	s2,32(a0)
    STORE s3, 5*REGBYTES(a0)
ffffffffc02038cc:	03353423          	sd	s3,40(a0)
    STORE s4, 6*REGBYTES(a0)
ffffffffc02038d0:	03453823          	sd	s4,48(a0)
    STORE s5, 7*REGBYTES(a0)
ffffffffc02038d4:	03553c23          	sd	s5,56(a0)
    STORE s6, 8*REGBYTES(a0)
ffffffffc02038d8:	05653023          	sd	s6,64(a0)
    STORE s7, 9*REGBYTES(a0)
ffffffffc02038dc:	05753423          	sd	s7,72(a0)
    STORE s8, 10*REGBYTES(a0)
ffffffffc02038e0:	05853823          	sd	s8,80(a0)
    STORE s9, 11*REGBYTES(a0)
ffffffffc02038e4:	05953c23          	sd	s9,88(a0)
    STORE s10, 12*REGBYTES(a0)
ffffffffc02038e8:	07a53023          	sd	s10,96(a0)
    STORE s11, 13*REGBYTES(a0)
ffffffffc02038ec:	07b53423          	sd	s11,104(a0)

    # restore to's registers
    # 2310675: a1指向新进程的context结构（&proc->context），恢复目标进程的寄存器状态
    LOAD ra, 0*REGBYTES(a1)       # 2310675: 恢复ra，ret时将跳转到新进程的"返回地址"
ffffffffc02038f0:	0005b083          	ld	ra,0(a1)
    LOAD sp, 1*REGBYTES(a1)       # 2310675: 切换到新进程的栈
ffffffffc02038f4:	0085b103          	ld	sp,8(a1)
    LOAD s0, 2*REGBYTES(a1)       # 2310675: 恢复s0-s11寄存器
ffffffffc02038f8:	6980                	ld	s0,16(a1)
    LOAD s1, 3*REGBYTES(a1)
ffffffffc02038fa:	6d84                	ld	s1,24(a1)
    LOAD s2, 4*REGBYTES(a1)
ffffffffc02038fc:	0205b903          	ld	s2,32(a1)
    LOAD s3, 5*REGBYTES(a1)
ffffffffc0203900:	0285b983          	ld	s3,40(a1)
    LOAD s4, 6*REGBYTES(a1)
ffffffffc0203904:	0305ba03          	ld	s4,48(a1)
    LOAD s5, 7*REGBYTES(a1)
ffffffffc0203908:	0385ba83          	ld	s5,56(a1)
    LOAD s6, 8*REGBYTES(a1)
ffffffffc020390c:	0405bb03          	ld	s6,64(a1)
    LOAD s7, 9*REGBYTES(a1)
ffffffffc0203910:	0485bb83          	ld	s7,72(a1)
    LOAD s8, 10*REGBYTES(a1)
ffffffffc0203914:	0505bc03          	ld	s8,80(a1)
    LOAD s9, 11*REGBYTES(a1)
ffffffffc0203918:	0585bc83          	ld	s9,88(a1)
    LOAD s10, 12*REGBYTES(a1)
ffffffffc020391c:	0605bd03          	ld	s10,96(a1)
    LOAD s11, 13*REGBYTES(a1)
ffffffffc0203920:	0685bd83          	ld	s11,104(a1)

    ret                           # 2310675: 跳转到ra指向的地址（新进程的执行点）
ffffffffc0203924:	8082                	ret

ffffffffc0203926 <wakeup_proc>:
#include <sched.h>
#include <assert.h>

void
wakeup_proc(struct proc_struct *proc) {
    assert(proc->state != PROC_ZOMBIE && proc->state != PROC_RUNNABLE);
ffffffffc0203926:	411c                	lw	a5,0(a0)
ffffffffc0203928:	4705                	li	a4,1
ffffffffc020392a:	37f9                	addiw	a5,a5,-2
ffffffffc020392c:	00f77563          	bgeu	a4,a5,ffffffffc0203936 <wakeup_proc+0x10>
    proc->state = PROC_RUNNABLE; // 从睡眠/新建态切换到就绪态，等待调度
ffffffffc0203930:	4789                	li	a5,2
ffffffffc0203932:	c11c                	sw	a5,0(a0)
ffffffffc0203934:	8082                	ret
wakeup_proc(struct proc_struct *proc) {
ffffffffc0203936:	1141                	addi	sp,sp,-16
    assert(proc->state != PROC_ZOMBIE && proc->state != PROC_RUNNABLE);
ffffffffc0203938:	00002697          	auipc	a3,0x2
ffffffffc020393c:	e7868693          	addi	a3,a3,-392 # ffffffffc02057b0 <default_pmm_manager+0xa80>
ffffffffc0203940:	00001617          	auipc	a2,0x1
ffffffffc0203944:	04060613          	addi	a2,a2,64 # ffffffffc0204980 <commands+0x838>
ffffffffc0203948:	45a5                	li	a1,9
ffffffffc020394a:	00002517          	auipc	a0,0x2
ffffffffc020394e:	ea650513          	addi	a0,a0,-346 # ffffffffc02057f0 <default_pmm_manager+0xac0>
wakeup_proc(struct proc_struct *proc) {
ffffffffc0203952:	e406                	sd	ra,8(sp)
    assert(proc->state != PROC_ZOMBIE && proc->state != PROC_RUNNABLE);
ffffffffc0203954:	b07fc0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0203958 <schedule>:
}

void
schedule(void) {
ffffffffc0203958:	1141                	addi	sp,sp,-16
ffffffffc020395a:	e406                	sd	ra,8(sp)
ffffffffc020395c:	e022                	sd	s0,0(sp)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020395e:	100027f3          	csrr	a5,sstatus
ffffffffc0203962:	8b89                	andi	a5,a5,2
ffffffffc0203964:	4401                	li	s0,0
ffffffffc0203966:	efbd                	bnez	a5,ffffffffc02039e4 <schedule+0x8c>
    bool intr_flag;
    list_entry_t *le, *last;
    struct proc_struct *next = NULL;
    local_intr_save(intr_flag); // 调度过程需互斥，先关闭中断
    {
        current->need_resched = 0; // 清除当前线程的调度请求
ffffffffc0203968:	0000a897          	auipc	a7,0xa
ffffffffc020396c:	b688b883          	ld	a7,-1176(a7) # ffffffffc020d4d0 <current>
ffffffffc0203970:	0008ac23          	sw	zero,24(a7)
        // idleproc从链表头开始找，其余线程从自身之后开始，实现简单轮转
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc0203974:	0000a517          	auipc	a0,0xa
ffffffffc0203978:	b6453503          	ld	a0,-1180(a0) # ffffffffc020d4d8 <idleproc>
ffffffffc020397c:	04a88e63          	beq	a7,a0,ffffffffc02039d8 <schedule+0x80>
ffffffffc0203980:	0c888693          	addi	a3,a7,200
ffffffffc0203984:	0000a617          	auipc	a2,0xa
ffffffffc0203988:	ad460613          	addi	a2,a2,-1324 # ffffffffc020d458 <proc_list>
        le = last;
ffffffffc020398c:	87b6                	mv	a5,a3
    struct proc_struct *next = NULL;
ffffffffc020398e:	4581                	li	a1,0
        do {
            if ((le = list_next(le)) != &proc_list) {
                next = le2proc(le, list_link);
                if (next->state == PROC_RUNNABLE) { // 找到就绪线程立即退出循环
ffffffffc0203990:	4809                	li	a6,2
ffffffffc0203992:	679c                	ld	a5,8(a5)
            if ((le = list_next(le)) != &proc_list) {
ffffffffc0203994:	00c78863          	beq	a5,a2,ffffffffc02039a4 <schedule+0x4c>
                if (next->state == PROC_RUNNABLE) { // 找到就绪线程立即退出循环
ffffffffc0203998:	f387a703          	lw	a4,-200(a5)
                next = le2proc(le, list_link);
ffffffffc020399c:	f3878593          	addi	a1,a5,-200
                if (next->state == PROC_RUNNABLE) { // 找到就绪线程立即退出循环
ffffffffc02039a0:	03070163          	beq	a4,a6,ffffffffc02039c2 <schedule+0x6a>
                    break;
                }
            }
        } while (le != last);
ffffffffc02039a4:	fef697e3          	bne	a3,a5,ffffffffc0203992 <schedule+0x3a>
        if (next == NULL || next->state != PROC_RUNNABLE) {
ffffffffc02039a8:	ed89                	bnez	a1,ffffffffc02039c2 <schedule+0x6a>
            next = idleproc; // 没有就绪线程时回退到idleproc占位
        }
        next->runs ++; // 统计线程被调度次数
ffffffffc02039aa:	451c                	lw	a5,8(a0)
ffffffffc02039ac:	2785                	addiw	a5,a5,1
ffffffffc02039ae:	c51c                	sw	a5,8(a0)
        if (next != current) {
ffffffffc02039b0:	00a88463          	beq	a7,a0,ffffffffc02039b8 <schedule+0x60>
            proc_run(next); // 执行真正的上下文切换
ffffffffc02039b4:	96bff0ef          	jal	ra,ffffffffc020331e <proc_run>
    if (flag) {
ffffffffc02039b8:	e819                	bnez	s0,ffffffffc02039ce <schedule+0x76>
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc02039ba:	60a2                	ld	ra,8(sp)
ffffffffc02039bc:	6402                	ld	s0,0(sp)
ffffffffc02039be:	0141                	addi	sp,sp,16
ffffffffc02039c0:	8082                	ret
        if (next == NULL || next->state != PROC_RUNNABLE) {
ffffffffc02039c2:	4198                	lw	a4,0(a1)
ffffffffc02039c4:	4789                	li	a5,2
ffffffffc02039c6:	fef712e3          	bne	a4,a5,ffffffffc02039aa <schedule+0x52>
ffffffffc02039ca:	852e                	mv	a0,a1
ffffffffc02039cc:	bff9                	j	ffffffffc02039aa <schedule+0x52>
}
ffffffffc02039ce:	6402                	ld	s0,0(sp)
ffffffffc02039d0:	60a2                	ld	ra,8(sp)
ffffffffc02039d2:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc02039d4:	f57fc06f          	j	ffffffffc020092a <intr_enable>
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc02039d8:	0000a617          	auipc	a2,0xa
ffffffffc02039dc:	a8060613          	addi	a2,a2,-1408 # ffffffffc020d458 <proc_list>
ffffffffc02039e0:	86b2                	mv	a3,a2
ffffffffc02039e2:	b76d                	j	ffffffffc020398c <schedule+0x34>
        intr_disable();
ffffffffc02039e4:	f4dfc0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        return 1;
ffffffffc02039e8:	4405                	li	s0,1
ffffffffc02039ea:	bfbd                	j	ffffffffc0203968 <schedule+0x10>

ffffffffc02039ec <hash32>:
 *
 * High bits are more random, so we use them.
 * */
uint32_t
hash32(uint32_t val, unsigned int bits) {
    uint32_t hash = val * GOLDEN_RATIO_PRIME_32;
ffffffffc02039ec:	9e3707b7          	lui	a5,0x9e370
ffffffffc02039f0:	2785                	addiw	a5,a5,1
ffffffffc02039f2:	02a7853b          	mulw	a0,a5,a0
    return (hash >> (32 - bits));
ffffffffc02039f6:	02000793          	li	a5,32
ffffffffc02039fa:	9f8d                	subw	a5,a5,a1
}
ffffffffc02039fc:	00f5553b          	srlw	a0,a0,a5
ffffffffc0203a00:	8082                	ret

ffffffffc0203a02 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0203a02:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0203a06:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0203a08:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0203a0c:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0203a0e:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0203a12:	f022                	sd	s0,32(sp)
ffffffffc0203a14:	ec26                	sd	s1,24(sp)
ffffffffc0203a16:	e84a                	sd	s2,16(sp)
ffffffffc0203a18:	f406                	sd	ra,40(sp)
ffffffffc0203a1a:	e44e                	sd	s3,8(sp)
ffffffffc0203a1c:	84aa                	mv	s1,a0
ffffffffc0203a1e:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0203a20:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0203a24:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc0203a26:	03067e63          	bgeu	a2,a6,ffffffffc0203a62 <printnum+0x60>
ffffffffc0203a2a:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0203a2c:	00805763          	blez	s0,ffffffffc0203a3a <printnum+0x38>
ffffffffc0203a30:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0203a32:	85ca                	mv	a1,s2
ffffffffc0203a34:	854e                	mv	a0,s3
ffffffffc0203a36:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0203a38:	fc65                	bnez	s0,ffffffffc0203a30 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203a3a:	1a02                	slli	s4,s4,0x20
ffffffffc0203a3c:	00002797          	auipc	a5,0x2
ffffffffc0203a40:	dcc78793          	addi	a5,a5,-564 # ffffffffc0205808 <default_pmm_manager+0xad8>
ffffffffc0203a44:	020a5a13          	srli	s4,s4,0x20
ffffffffc0203a48:	9a3e                	add	s4,s4,a5
}
ffffffffc0203a4a:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203a4c:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0203a50:	70a2                	ld	ra,40(sp)
ffffffffc0203a52:	69a2                	ld	s3,8(sp)
ffffffffc0203a54:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203a56:	85ca                	mv	a1,s2
ffffffffc0203a58:	87a6                	mv	a5,s1
}
ffffffffc0203a5a:	6942                	ld	s2,16(sp)
ffffffffc0203a5c:	64e2                	ld	s1,24(sp)
ffffffffc0203a5e:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203a60:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0203a62:	03065633          	divu	a2,a2,a6
ffffffffc0203a66:	8722                	mv	a4,s0
ffffffffc0203a68:	f9bff0ef          	jal	ra,ffffffffc0203a02 <printnum>
ffffffffc0203a6c:	b7f9                	j	ffffffffc0203a3a <printnum+0x38>

ffffffffc0203a6e <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0203a6e:	7119                	addi	sp,sp,-128
ffffffffc0203a70:	f4a6                	sd	s1,104(sp)
ffffffffc0203a72:	f0ca                	sd	s2,96(sp)
ffffffffc0203a74:	ecce                	sd	s3,88(sp)
ffffffffc0203a76:	e8d2                	sd	s4,80(sp)
ffffffffc0203a78:	e4d6                	sd	s5,72(sp)
ffffffffc0203a7a:	e0da                	sd	s6,64(sp)
ffffffffc0203a7c:	fc5e                	sd	s7,56(sp)
ffffffffc0203a7e:	f06a                	sd	s10,32(sp)
ffffffffc0203a80:	fc86                	sd	ra,120(sp)
ffffffffc0203a82:	f8a2                	sd	s0,112(sp)
ffffffffc0203a84:	f862                	sd	s8,48(sp)
ffffffffc0203a86:	f466                	sd	s9,40(sp)
ffffffffc0203a88:	ec6e                	sd	s11,24(sp)
ffffffffc0203a8a:	892a                	mv	s2,a0
ffffffffc0203a8c:	84ae                	mv	s1,a1
ffffffffc0203a8e:	8d32                	mv	s10,a2
ffffffffc0203a90:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203a92:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0203a96:	5b7d                	li	s6,-1
ffffffffc0203a98:	00002a97          	auipc	s5,0x2
ffffffffc0203a9c:	d9ca8a93          	addi	s5,s5,-612 # ffffffffc0205834 <default_pmm_manager+0xb04>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0203aa0:	00002b97          	auipc	s7,0x2
ffffffffc0203aa4:	f70b8b93          	addi	s7,s7,-144 # ffffffffc0205a10 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203aa8:	000d4503          	lbu	a0,0(s10)
ffffffffc0203aac:	001d0413          	addi	s0,s10,1
ffffffffc0203ab0:	01350a63          	beq	a0,s3,ffffffffc0203ac4 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc0203ab4:	c121                	beqz	a0,ffffffffc0203af4 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc0203ab6:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203ab8:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0203aba:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203abc:	fff44503          	lbu	a0,-1(s0)
ffffffffc0203ac0:	ff351ae3          	bne	a0,s3,ffffffffc0203ab4 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203ac4:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0203ac8:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0203acc:	4c81                	li	s9,0
ffffffffc0203ace:	4881                	li	a7,0
        width = precision = -1;
ffffffffc0203ad0:	5c7d                	li	s8,-1
ffffffffc0203ad2:	5dfd                	li	s11,-1
ffffffffc0203ad4:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc0203ad8:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203ada:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0203ade:	0ff5f593          	zext.b	a1,a1
ffffffffc0203ae2:	00140d13          	addi	s10,s0,1
ffffffffc0203ae6:	04b56263          	bltu	a0,a1,ffffffffc0203b2a <vprintfmt+0xbc>
ffffffffc0203aea:	058a                	slli	a1,a1,0x2
ffffffffc0203aec:	95d6                	add	a1,a1,s5
ffffffffc0203aee:	4194                	lw	a3,0(a1)
ffffffffc0203af0:	96d6                	add	a3,a3,s5
ffffffffc0203af2:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0203af4:	70e6                	ld	ra,120(sp)
ffffffffc0203af6:	7446                	ld	s0,112(sp)
ffffffffc0203af8:	74a6                	ld	s1,104(sp)
ffffffffc0203afa:	7906                	ld	s2,96(sp)
ffffffffc0203afc:	69e6                	ld	s3,88(sp)
ffffffffc0203afe:	6a46                	ld	s4,80(sp)
ffffffffc0203b00:	6aa6                	ld	s5,72(sp)
ffffffffc0203b02:	6b06                	ld	s6,64(sp)
ffffffffc0203b04:	7be2                	ld	s7,56(sp)
ffffffffc0203b06:	7c42                	ld	s8,48(sp)
ffffffffc0203b08:	7ca2                	ld	s9,40(sp)
ffffffffc0203b0a:	7d02                	ld	s10,32(sp)
ffffffffc0203b0c:	6de2                	ld	s11,24(sp)
ffffffffc0203b0e:	6109                	addi	sp,sp,128
ffffffffc0203b10:	8082                	ret
            padc = '0';
ffffffffc0203b12:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc0203b14:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203b18:	846a                	mv	s0,s10
ffffffffc0203b1a:	00140d13          	addi	s10,s0,1
ffffffffc0203b1e:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0203b22:	0ff5f593          	zext.b	a1,a1
ffffffffc0203b26:	fcb572e3          	bgeu	a0,a1,ffffffffc0203aea <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc0203b2a:	85a6                	mv	a1,s1
ffffffffc0203b2c:	02500513          	li	a0,37
ffffffffc0203b30:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0203b32:	fff44783          	lbu	a5,-1(s0)
ffffffffc0203b36:	8d22                	mv	s10,s0
ffffffffc0203b38:	f73788e3          	beq	a5,s3,ffffffffc0203aa8 <vprintfmt+0x3a>
ffffffffc0203b3c:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0203b40:	1d7d                	addi	s10,s10,-1
ffffffffc0203b42:	ff379de3          	bne	a5,s3,ffffffffc0203b3c <vprintfmt+0xce>
ffffffffc0203b46:	b78d                	j	ffffffffc0203aa8 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc0203b48:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc0203b4c:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203b50:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0203b52:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0203b56:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0203b5a:	02d86463          	bltu	a6,a3,ffffffffc0203b82 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc0203b5e:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0203b62:	002c169b          	slliw	a3,s8,0x2
ffffffffc0203b66:	0186873b          	addw	a4,a3,s8
ffffffffc0203b6a:	0017171b          	slliw	a4,a4,0x1
ffffffffc0203b6e:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc0203b70:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0203b74:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0203b76:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc0203b7a:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0203b7e:	fed870e3          	bgeu	a6,a3,ffffffffc0203b5e <vprintfmt+0xf0>
            if (width < 0)
ffffffffc0203b82:	f40ddce3          	bgez	s11,ffffffffc0203ada <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc0203b86:	8de2                	mv	s11,s8
ffffffffc0203b88:	5c7d                	li	s8,-1
ffffffffc0203b8a:	bf81                	j	ffffffffc0203ada <vprintfmt+0x6c>
            if (width < 0)
ffffffffc0203b8c:	fffdc693          	not	a3,s11
ffffffffc0203b90:	96fd                	srai	a3,a3,0x3f
ffffffffc0203b92:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203b96:	00144603          	lbu	a2,1(s0)
ffffffffc0203b9a:	2d81                	sext.w	s11,s11
ffffffffc0203b9c:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0203b9e:	bf35                	j	ffffffffc0203ada <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc0203ba0:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203ba4:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0203ba8:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203baa:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc0203bac:	bfd9                	j	ffffffffc0203b82 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc0203bae:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0203bb0:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0203bb4:	01174463          	blt	a4,a7,ffffffffc0203bbc <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc0203bb8:	1a088e63          	beqz	a7,ffffffffc0203d74 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc0203bbc:	000a3603          	ld	a2,0(s4)
ffffffffc0203bc0:	46c1                	li	a3,16
ffffffffc0203bc2:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0203bc4:	2781                	sext.w	a5,a5
ffffffffc0203bc6:	876e                	mv	a4,s11
ffffffffc0203bc8:	85a6                	mv	a1,s1
ffffffffc0203bca:	854a                	mv	a0,s2
ffffffffc0203bcc:	e37ff0ef          	jal	ra,ffffffffc0203a02 <printnum>
            break;
ffffffffc0203bd0:	bde1                	j	ffffffffc0203aa8 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc0203bd2:	000a2503          	lw	a0,0(s4)
ffffffffc0203bd6:	85a6                	mv	a1,s1
ffffffffc0203bd8:	0a21                	addi	s4,s4,8
ffffffffc0203bda:	9902                	jalr	s2
            break;
ffffffffc0203bdc:	b5f1                	j	ffffffffc0203aa8 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0203bde:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0203be0:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0203be4:	01174463          	blt	a4,a7,ffffffffc0203bec <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc0203be8:	18088163          	beqz	a7,ffffffffc0203d6a <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc0203bec:	000a3603          	ld	a2,0(s4)
ffffffffc0203bf0:	46a9                	li	a3,10
ffffffffc0203bf2:	8a2e                	mv	s4,a1
ffffffffc0203bf4:	bfc1                	j	ffffffffc0203bc4 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203bf6:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0203bfa:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203bfc:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0203bfe:	bdf1                	j	ffffffffc0203ada <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc0203c00:	85a6                	mv	a1,s1
ffffffffc0203c02:	02500513          	li	a0,37
ffffffffc0203c06:	9902                	jalr	s2
            break;
ffffffffc0203c08:	b545                	j	ffffffffc0203aa8 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203c0a:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc0203c0e:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203c10:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0203c12:	b5e1                	j	ffffffffc0203ada <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0203c14:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0203c16:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0203c1a:	01174463          	blt	a4,a7,ffffffffc0203c22 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc0203c1e:	14088163          	beqz	a7,ffffffffc0203d60 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc0203c22:	000a3603          	ld	a2,0(s4)
ffffffffc0203c26:	46a1                	li	a3,8
ffffffffc0203c28:	8a2e                	mv	s4,a1
ffffffffc0203c2a:	bf69                	j	ffffffffc0203bc4 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc0203c2c:	03000513          	li	a0,48
ffffffffc0203c30:	85a6                	mv	a1,s1
ffffffffc0203c32:	e03e                	sd	a5,0(sp)
ffffffffc0203c34:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0203c36:	85a6                	mv	a1,s1
ffffffffc0203c38:	07800513          	li	a0,120
ffffffffc0203c3c:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0203c3e:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0203c40:	6782                	ld	a5,0(sp)
ffffffffc0203c42:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0203c44:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0203c48:	bfb5                	j	ffffffffc0203bc4 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0203c4a:	000a3403          	ld	s0,0(s4)
ffffffffc0203c4e:	008a0713          	addi	a4,s4,8
ffffffffc0203c52:	e03a                	sd	a4,0(sp)
ffffffffc0203c54:	14040263          	beqz	s0,ffffffffc0203d98 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0203c58:	0fb05763          	blez	s11,ffffffffc0203d46 <vprintfmt+0x2d8>
ffffffffc0203c5c:	02d00693          	li	a3,45
ffffffffc0203c60:	0cd79163          	bne	a5,a3,ffffffffc0203d22 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203c64:	00044783          	lbu	a5,0(s0)
ffffffffc0203c68:	0007851b          	sext.w	a0,a5
ffffffffc0203c6c:	cf85                	beqz	a5,ffffffffc0203ca4 <vprintfmt+0x236>
ffffffffc0203c6e:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0203c72:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203c76:	000c4563          	bltz	s8,ffffffffc0203c80 <vprintfmt+0x212>
ffffffffc0203c7a:	3c7d                	addiw	s8,s8,-1
ffffffffc0203c7c:	036c0263          	beq	s8,s6,ffffffffc0203ca0 <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc0203c80:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0203c82:	0e0c8e63          	beqz	s9,ffffffffc0203d7e <vprintfmt+0x310>
ffffffffc0203c86:	3781                	addiw	a5,a5,-32
ffffffffc0203c88:	0ef47b63          	bgeu	s0,a5,ffffffffc0203d7e <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc0203c8c:	03f00513          	li	a0,63
ffffffffc0203c90:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203c92:	000a4783          	lbu	a5,0(s4)
ffffffffc0203c96:	3dfd                	addiw	s11,s11,-1
ffffffffc0203c98:	0a05                	addi	s4,s4,1
ffffffffc0203c9a:	0007851b          	sext.w	a0,a5
ffffffffc0203c9e:	ffe1                	bnez	a5,ffffffffc0203c76 <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc0203ca0:	01b05963          	blez	s11,ffffffffc0203cb2 <vprintfmt+0x244>
ffffffffc0203ca4:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0203ca6:	85a6                	mv	a1,s1
ffffffffc0203ca8:	02000513          	li	a0,32
ffffffffc0203cac:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0203cae:	fe0d9be3          	bnez	s11,ffffffffc0203ca4 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0203cb2:	6a02                	ld	s4,0(sp)
ffffffffc0203cb4:	bbd5                	j	ffffffffc0203aa8 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0203cb6:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0203cb8:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc0203cbc:	01174463          	blt	a4,a7,ffffffffc0203cc4 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc0203cc0:	08088d63          	beqz	a7,ffffffffc0203d5a <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc0203cc4:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0203cc8:	0a044d63          	bltz	s0,ffffffffc0203d82 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc0203ccc:	8622                	mv	a2,s0
ffffffffc0203cce:	8a66                	mv	s4,s9
ffffffffc0203cd0:	46a9                	li	a3,10
ffffffffc0203cd2:	bdcd                	j	ffffffffc0203bc4 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc0203cd4:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0203cd8:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc0203cda:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0203cdc:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0203ce0:	8fb5                	xor	a5,a5,a3
ffffffffc0203ce2:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0203ce6:	02d74163          	blt	a4,a3,ffffffffc0203d08 <vprintfmt+0x29a>
ffffffffc0203cea:	00369793          	slli	a5,a3,0x3
ffffffffc0203cee:	97de                	add	a5,a5,s7
ffffffffc0203cf0:	639c                	ld	a5,0(a5)
ffffffffc0203cf2:	cb99                	beqz	a5,ffffffffc0203d08 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0203cf4:	86be                	mv	a3,a5
ffffffffc0203cf6:	00000617          	auipc	a2,0x0
ffffffffc0203cfa:	21260613          	addi	a2,a2,530 # ffffffffc0203f08 <etext+0x28>
ffffffffc0203cfe:	85a6                	mv	a1,s1
ffffffffc0203d00:	854a                	mv	a0,s2
ffffffffc0203d02:	0ce000ef          	jal	ra,ffffffffc0203dd0 <printfmt>
ffffffffc0203d06:	b34d                	j	ffffffffc0203aa8 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0203d08:	00002617          	auipc	a2,0x2
ffffffffc0203d0c:	b2060613          	addi	a2,a2,-1248 # ffffffffc0205828 <default_pmm_manager+0xaf8>
ffffffffc0203d10:	85a6                	mv	a1,s1
ffffffffc0203d12:	854a                	mv	a0,s2
ffffffffc0203d14:	0bc000ef          	jal	ra,ffffffffc0203dd0 <printfmt>
ffffffffc0203d18:	bb41                	j	ffffffffc0203aa8 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0203d1a:	00002417          	auipc	s0,0x2
ffffffffc0203d1e:	b0640413          	addi	s0,s0,-1274 # ffffffffc0205820 <default_pmm_manager+0xaf0>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0203d22:	85e2                	mv	a1,s8
ffffffffc0203d24:	8522                	mv	a0,s0
ffffffffc0203d26:	e43e                	sd	a5,8(sp)
ffffffffc0203d28:	0e2000ef          	jal	ra,ffffffffc0203e0a <strnlen>
ffffffffc0203d2c:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0203d30:	01b05b63          	blez	s11,ffffffffc0203d46 <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0203d34:	67a2                	ld	a5,8(sp)
ffffffffc0203d36:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0203d3a:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0203d3c:	85a6                	mv	a1,s1
ffffffffc0203d3e:	8552                	mv	a0,s4
ffffffffc0203d40:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0203d42:	fe0d9ce3          	bnez	s11,ffffffffc0203d3a <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203d46:	00044783          	lbu	a5,0(s0)
ffffffffc0203d4a:	00140a13          	addi	s4,s0,1
ffffffffc0203d4e:	0007851b          	sext.w	a0,a5
ffffffffc0203d52:	d3a5                	beqz	a5,ffffffffc0203cb2 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0203d54:	05e00413          	li	s0,94
ffffffffc0203d58:	bf39                	j	ffffffffc0203c76 <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0203d5a:	000a2403          	lw	s0,0(s4)
ffffffffc0203d5e:	b7ad                	j	ffffffffc0203cc8 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc0203d60:	000a6603          	lwu	a2,0(s4)
ffffffffc0203d64:	46a1                	li	a3,8
ffffffffc0203d66:	8a2e                	mv	s4,a1
ffffffffc0203d68:	bdb1                	j	ffffffffc0203bc4 <vprintfmt+0x156>
ffffffffc0203d6a:	000a6603          	lwu	a2,0(s4)
ffffffffc0203d6e:	46a9                	li	a3,10
ffffffffc0203d70:	8a2e                	mv	s4,a1
ffffffffc0203d72:	bd89                	j	ffffffffc0203bc4 <vprintfmt+0x156>
ffffffffc0203d74:	000a6603          	lwu	a2,0(s4)
ffffffffc0203d78:	46c1                	li	a3,16
ffffffffc0203d7a:	8a2e                	mv	s4,a1
ffffffffc0203d7c:	b5a1                	j	ffffffffc0203bc4 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc0203d7e:	9902                	jalr	s2
ffffffffc0203d80:	bf09                	j	ffffffffc0203c92 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0203d82:	85a6                	mv	a1,s1
ffffffffc0203d84:	02d00513          	li	a0,45
ffffffffc0203d88:	e03e                	sd	a5,0(sp)
ffffffffc0203d8a:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0203d8c:	6782                	ld	a5,0(sp)
ffffffffc0203d8e:	8a66                	mv	s4,s9
ffffffffc0203d90:	40800633          	neg	a2,s0
ffffffffc0203d94:	46a9                	li	a3,10
ffffffffc0203d96:	b53d                	j	ffffffffc0203bc4 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc0203d98:	03b05163          	blez	s11,ffffffffc0203dba <vprintfmt+0x34c>
ffffffffc0203d9c:	02d00693          	li	a3,45
ffffffffc0203da0:	f6d79de3          	bne	a5,a3,ffffffffc0203d1a <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc0203da4:	00002417          	auipc	s0,0x2
ffffffffc0203da8:	a7c40413          	addi	s0,s0,-1412 # ffffffffc0205820 <default_pmm_manager+0xaf0>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203dac:	02800793          	li	a5,40
ffffffffc0203db0:	02800513          	li	a0,40
ffffffffc0203db4:	00140a13          	addi	s4,s0,1
ffffffffc0203db8:	bd6d                	j	ffffffffc0203c72 <vprintfmt+0x204>
ffffffffc0203dba:	00002a17          	auipc	s4,0x2
ffffffffc0203dbe:	a67a0a13          	addi	s4,s4,-1433 # ffffffffc0205821 <default_pmm_manager+0xaf1>
ffffffffc0203dc2:	02800513          	li	a0,40
ffffffffc0203dc6:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0203dca:	05e00413          	li	s0,94
ffffffffc0203dce:	b565                	j	ffffffffc0203c76 <vprintfmt+0x208>

ffffffffc0203dd0 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0203dd0:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0203dd2:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0203dd6:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0203dd8:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0203dda:	ec06                	sd	ra,24(sp)
ffffffffc0203ddc:	f83a                	sd	a4,48(sp)
ffffffffc0203dde:	fc3e                	sd	a5,56(sp)
ffffffffc0203de0:	e0c2                	sd	a6,64(sp)
ffffffffc0203de2:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0203de4:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0203de6:	c89ff0ef          	jal	ra,ffffffffc0203a6e <vprintfmt>
}
ffffffffc0203dea:	60e2                	ld	ra,24(sp)
ffffffffc0203dec:	6161                	addi	sp,sp,80
ffffffffc0203dee:	8082                	ret

ffffffffc0203df0 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0203df0:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc0203df4:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc0203df6:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc0203df8:	cb81                	beqz	a5,ffffffffc0203e08 <strlen+0x18>
        cnt ++;
ffffffffc0203dfa:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc0203dfc:	00a707b3          	add	a5,a4,a0
ffffffffc0203e00:	0007c783          	lbu	a5,0(a5)
ffffffffc0203e04:	fbfd                	bnez	a5,ffffffffc0203dfa <strlen+0xa>
ffffffffc0203e06:	8082                	ret
    }
    return cnt;
}
ffffffffc0203e08:	8082                	ret

ffffffffc0203e0a <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0203e0a:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0203e0c:	e589                	bnez	a1,ffffffffc0203e16 <strnlen+0xc>
ffffffffc0203e0e:	a811                	j	ffffffffc0203e22 <strnlen+0x18>
        cnt ++;
ffffffffc0203e10:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0203e12:	00f58863          	beq	a1,a5,ffffffffc0203e22 <strnlen+0x18>
ffffffffc0203e16:	00f50733          	add	a4,a0,a5
ffffffffc0203e1a:	00074703          	lbu	a4,0(a4)
ffffffffc0203e1e:	fb6d                	bnez	a4,ffffffffc0203e10 <strnlen+0x6>
ffffffffc0203e20:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0203e22:	852e                	mv	a0,a1
ffffffffc0203e24:	8082                	ret

ffffffffc0203e26 <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc0203e26:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc0203e28:	0005c703          	lbu	a4,0(a1)
ffffffffc0203e2c:	0785                	addi	a5,a5,1
ffffffffc0203e2e:	0585                	addi	a1,a1,1
ffffffffc0203e30:	fee78fa3          	sb	a4,-1(a5)
ffffffffc0203e34:	fb75                	bnez	a4,ffffffffc0203e28 <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc0203e36:	8082                	ret

ffffffffc0203e38 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0203e38:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203e3c:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0203e40:	cb89                	beqz	a5,ffffffffc0203e52 <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0203e42:	0505                	addi	a0,a0,1
ffffffffc0203e44:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0203e46:	fee789e3          	beq	a5,a4,ffffffffc0203e38 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203e4a:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0203e4e:	9d19                	subw	a0,a0,a4
ffffffffc0203e50:	8082                	ret
ffffffffc0203e52:	4501                	li	a0,0
ffffffffc0203e54:	bfed                	j	ffffffffc0203e4e <strcmp+0x16>

ffffffffc0203e56 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0203e56:	c20d                	beqz	a2,ffffffffc0203e78 <strncmp+0x22>
ffffffffc0203e58:	962e                	add	a2,a2,a1
ffffffffc0203e5a:	a031                	j	ffffffffc0203e66 <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc0203e5c:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0203e5e:	00e79a63          	bne	a5,a4,ffffffffc0203e72 <strncmp+0x1c>
ffffffffc0203e62:	00b60b63          	beq	a2,a1,ffffffffc0203e78 <strncmp+0x22>
ffffffffc0203e66:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0203e6a:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0203e6c:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0203e70:	f7f5                	bnez	a5,ffffffffc0203e5c <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203e72:	40e7853b          	subw	a0,a5,a4
}
ffffffffc0203e76:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203e78:	4501                	li	a0,0
ffffffffc0203e7a:	8082                	ret

ffffffffc0203e7c <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0203e7c:	00054783          	lbu	a5,0(a0)
ffffffffc0203e80:	c799                	beqz	a5,ffffffffc0203e8e <strchr+0x12>
        if (*s == c) {
ffffffffc0203e82:	00f58763          	beq	a1,a5,ffffffffc0203e90 <strchr+0x14>
    while (*s != '\0') {
ffffffffc0203e86:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc0203e8a:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0203e8c:	fbfd                	bnez	a5,ffffffffc0203e82 <strchr+0x6>
    }
    return NULL;
ffffffffc0203e8e:	4501                	li	a0,0
}
ffffffffc0203e90:	8082                	ret

ffffffffc0203e92 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0203e92:	ca01                	beqz	a2,ffffffffc0203ea2 <memset+0x10>
ffffffffc0203e94:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0203e96:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0203e98:	0785                	addi	a5,a5,1
ffffffffc0203e9a:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0203e9e:	fec79de3          	bne	a5,a2,ffffffffc0203e98 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0203ea2:	8082                	ret

ffffffffc0203ea4 <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc0203ea4:	ca19                	beqz	a2,ffffffffc0203eba <memcpy+0x16>
ffffffffc0203ea6:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc0203ea8:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc0203eaa:	0005c703          	lbu	a4,0(a1)
ffffffffc0203eae:	0585                	addi	a1,a1,1
ffffffffc0203eb0:	0785                	addi	a5,a5,1
ffffffffc0203eb2:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc0203eb6:	fec59ae3          	bne	a1,a2,ffffffffc0203eaa <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc0203eba:	8082                	ret

ffffffffc0203ebc <memcmp>:
 * */
int
memcmp(const void *v1, const void *v2, size_t n) {
    const char *s1 = (const char *)v1;
    const char *s2 = (const char *)v2;
    while (n -- > 0) {
ffffffffc0203ebc:	c205                	beqz	a2,ffffffffc0203edc <memcmp+0x20>
ffffffffc0203ebe:	962e                	add	a2,a2,a1
ffffffffc0203ec0:	a019                	j	ffffffffc0203ec6 <memcmp+0xa>
ffffffffc0203ec2:	00c58d63          	beq	a1,a2,ffffffffc0203edc <memcmp+0x20>
        if (*s1 != *s2) {
ffffffffc0203ec6:	00054783          	lbu	a5,0(a0)
ffffffffc0203eca:	0005c703          	lbu	a4,0(a1)
            return (int)((unsigned char)*s1 - (unsigned char)*s2);
        }
        s1 ++, s2 ++;
ffffffffc0203ece:	0505                	addi	a0,a0,1
ffffffffc0203ed0:	0585                	addi	a1,a1,1
        if (*s1 != *s2) {
ffffffffc0203ed2:	fee788e3          	beq	a5,a4,ffffffffc0203ec2 <memcmp+0x6>
            return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203ed6:	40e7853b          	subw	a0,a5,a4
ffffffffc0203eda:	8082                	ret
    }
    return 0;
ffffffffc0203edc:	4501                	li	a0,0
}
ffffffffc0203ede:	8082                	ret
