# shellbed

1.  `run.sh` 是工作中修改代码后自动编译，push， kill相应守护进程 的一个便利脚本
2. `addr2line_dbg.sh` 是定位crash的脚本。
3. `burn` 是使用脚本实现uboot 内核的加载，这个在A20开发板上使用。这个脚本涉及到sd卡的分区，写文件系统。因为A20需要提供一个boot.scr，所以脚本里面有一个boot.txt。脚本的第一个参数是sd卡的设备文件， 第二个参数是kernel镜像。

4. `return` 是一个将cpp里面的“return XXX” 转换为“RETURN（XXX）”的脚本。

5. `run_L2.sh` 是自动从suntec服务器上下载，并且编译。如果每周一到周五的凌晨3点半运行脚本,需要`crontab`， 参考了[网络](http://linuxtools-rst.readthedocs.org/zh_CN/latest/tool/crontab.html) , 使用`vi` 编辑需要编辑$HOME目录下的. profile文件，在其中加入这样一行:`EDITOR=vi; export EDITOR`

```
执行命令:"crontab -e"
30 6 * * 1-5 ~/suntec/run_L2.sh > ~/suntec/L2log.log 2>&1
```

