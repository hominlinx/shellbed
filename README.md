# shellbed

1.  `run.sh` 是工作中修改代码后自动编译，push， kill相应守护进程 的一个便利脚本
2. `addr2line_dbg.sh` 是定位crash的脚本。
3. `burn` 是使用脚本实现uboot 内核的加载，这个在A20开发板上使用。这个脚本涉及到sd卡的分区，写文件系统。因为A20需要提供一个boot.scr，所以脚本里面有一个boot.txt。脚本的第一个参数是sd卡的设备文件， 第二个参数是kernel镜像。

4. `return` 是一个将cpp里面的“return XXX” 转换为“RETURN（XXX）”的脚本。

