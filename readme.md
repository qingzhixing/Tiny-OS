[![wakatime](https://wakatime.com/badge/user/cd8731d7-2366-4da2-8032-5bb5ad0d3122/project/98b03fed-380c-4359-b03a-017e52b6fd99.svg)](https://wakatime.com/badge/user/cd8731d7-2366-4da2-8032-5bb5ad0d3122/project/98b03fed-380c-4359-b03a-017e52b6fd99)

# Tiny-OS

 操作系统真象还原学习

希望能够坚持学下去！

## 如何运行？

需要bo chs模拟代码时，请确保shell当前目录与makefile为同一个目录

命令行输入make bochs即可使用gui_debug模式下的bochs运行

如果不喜欢不需要gui_debug功能请修改bochsrc.disk文件中 ``display_library: x, options="gui_debug"``为 ``display_library: x``

## 运行环境

Bochs x86 Emulator 2.6.11

> 这个需要手动下载源码编译，打开gui_debug并安装，apt,homebrew等下载的Bochs没有打开gui_debug.
>
> 版本2.6+，因为bochs参数不同，比如2.5 bximg -func 在2.6版本改成了-mode
>
> [Bochs2.6.11配置安装参考](https://www.cnblogs.com/oasisyang/archive/2021/09/30/15358137.html "Bochs2.6.11配置安装参考")

GNU Make 4.2.1

> 这个不知道版本有啥关系，反正能用makefile的就行了

## git clone之后要做的事

在references下运行download-references.sh脚本下载参考项目，当然也可以不下载(

[推荐up 看见南山 的视频作为参考](https://www.bilibili.com/video/BV1kg4y1V7TV/?share_source=copy_web&vd_source=6a59c86042f2b2c62159e91ee5e54dc5)
