---
title: ubuntu20.04编译vlc
date: 2020-11-03 22:58:45
tags:
---

&nbsp;&nbsp;&nbsp;&nbsp;给自己立了一个flag就是熟悉vlc，那熟悉的第一步就是源码编译vlc。弄了一个很干净的环境(docker最新的ubuntu镜像，ubuntu20.04)来记录自己编译vlc中遇到的问题。    

&nbsp;&nbsp;&nbsp;&nbsp;一）源码下载    
&nbsp;&nbsp;&nbsp;&nbsp;从[官网](https://www.videolan.org/vlc/download-sources.html)或者官方git上拉取代码(git://git.videolan.org/vlc.git)，或者github(https://github.com/videolan/vlc.git)上拉取代码
```shell
$ git clone https://github.com/videolan/vlc.git
```
&nbsp;&nbsp;&nbsp;&nbsp;二) 依赖库    
&nbsp;&nbsp;&nbsp;&nbsp;vlc的编译依赖了其他库，在官方的[wiki](https://wiki.videolan.org/UnixCompile/)安装如下库：   
```shell
$ apt-get install git build-essential pkg-config libtool automake autopoint gettext
```

&nbsp;&nbsp;&nbsp;&nbsp;三) 编译    
&nbsp;&nbsp;&nbsp;&nbsp;第一步的基础上，直接贴出操作步骤：
```shell
$ cd vlc
$ ./bootstrap
```
&nbsp;&nbsp;&nbsp;&nbsp;1）遇到的第1个问题是：
```shell
root@374051914cd9:~/vlc# ./bootstrap
ERROR: flex is not installed.
```
&nbsp;&nbsp;&nbsp;&nbsp;解决办法嘛：
```shell
$ apt-get install flex
```
&nbsp;&nbsp;&nbsp;&nbsp;2）遇到的第2个问题是：
```shell
root@374051914cd9:~/vlc# ./bootstrap
ERROR: GNU bison is not installed.
```
&nbsp;&nbsp;&nbsp;&nbsp;解决办法嘛：
```shell
$ apt-get install bison
```
&nbsp;&nbsp;&nbsp;&nbsp;经过如上操作，./bootstrap顺利通过。因为我打算调试vlc，所以我接下里的命令如下:
```shell
$ ./configure --enable-debug
```
&nbsp;&nbsp;&nbsp;&nbsp;3）遇到的第3个问题是：
```shell
checking for LUA... no
configure: WARNING: No package 'lua5.2' found, trying lua 5.1 instead
checking for LUA... no
configure: WARNING: No package 'lua5.1' found, trying lua >= 5.1 instead
checking for LUA... no
configure: WARNING: No package 'lua' found, trying manual detection instead
checking lua.h usability... no
checking lua.h presence... no
checking for lua.h... no
checking lauxlib.h usability... no
checking lauxlib.h presence... no
checking for lauxlib.h... no
checking lualib.h usability... no
checking lualib.h presence... no
checking for lualib.h... no
checking for luaL_newstate in -llua5.2 ... no
checking for luaL_newstate in -llua5.1 ... no
checking for luaL_newstate in -llua51 ... no
checking for luaL_newstate in -llua ... no
configure: error: Could not find lua. Lua is needed for some interfaces (rc, telnet, http) as well as many other custom scripts. Use --disable-lua to ignore this error.

```
&nbsp;&nbsp;&nbsp;&nbsp;解决办法嘛：
```shell
$ apt-get install lua5.2 liblua5.2-dev 
```    
&nbsp;&nbsp;&nbsp;&nbsp;4）遇到的第4个问题是：
```shell
configure: error: Missing libav or FFmpeg. Pass --disable-avcodec to ignore this error.
```
&nbsp;&nbsp;&nbsp;&nbsp;解决办法嘛：
```shell
$ apt-get install libavformat-dev
```
&nbsp;&nbsp;&nbsp;&nbsp;5）遇到的第5个问题是：
```shell
configure: error: No package 'libswscale' found. Pass --disable-swscale to ignore this error. Proper software scaling and some video chroma conversion will be missing.
```
&nbsp;&nbsp;&nbsp;&nbsp;解决办法嘛：
```shell
$ apt-get install libswscale-dev
```
&nbsp;&nbsp;&nbsp;&nbsp;6）遇到的第6个问题是：
```shell
configure: error: Could not find liba52 on your system: you may get it from http://liba52.sf.net/. Alternatively you can use --disable-a52 to disable the a52 plugin.
```
&nbsp;&nbsp;&nbsp;&nbsp;解决办法嘛：
```shell
$ apt-get install liba52-0.7.4-dev
```
&nbsp;&nbsp;&nbsp;&nbsp;7）遇到的第7个问题是：
```shell
configure: error:  No package 'xcb' found. No package 'xcb-composite' found. No package 'xcb-randr' found. No package 'xcb-render' found. No package 'xcb-shm' found. No package 'xcb-xkb' found. No package 'xproto' found. Pass --disable-xcb to skip X11 support.
```
&nbsp;&nbsp;&nbsp;&nbsp;解决办法嘛：
```shell
$ apt-get install libxcb-composite0-dev
```

&nbsp;&nbsp;&nbsp;&nbsp;8）遇到的第8个问题是：
```shell
configure: error:  No package 'xcb-randr' found. No package 'xcb-shm' found. No package 'xcb-xkb' found. Pass --disable-xcb to skip X11 support.
```
&nbsp;&nbsp;&nbsp;&nbsp;解决办法嘛：
```shell
$ apt-get install libxcb-shm0-dev
```

&nbsp;&nbsp;&nbsp;&nbsp;9）遇到的第9个问题是：
```shell
configure: error:  No package 'xcb-randr' found. No package 'xcb-xkb' found. Pass --disable-xcb to skip X11 support.
```
&nbsp;&nbsp;&nbsp;&nbsp;解决办法嘛：
```shell
$ apt-get install libxcb-xkb-dev
```

&nbsp;&nbsp;&nbsp;&nbsp;10）遇到的第10个问题是：
```shell
configure: error:  No package 'xcb-randr' found. Pass --disable-xcb to skip X11 support.
```
&nbsp;&nbsp;&nbsp;&nbsp;解决办法嘛：
```shell
$ apt-get install libxcb-randr0-dev
```

&nbsp;&nbsp;&nbsp;&nbsp;11）遇到的第11个问题是：
```shell
configure: error: No package 'alsa' found. alsa-lib 1.0.24 or later required. Pass --disable-alsa to ignore this error.
```
&nbsp;&nbsp;&nbsp;&nbsp;解决办法嘛：
```shell
$ apt-get install libasound2-dev 
```

&nbsp;&nbsp;&nbsp;&nbsp;12）遇到的第12个问题是：
```shell
checking for QT... no
configure: error: No package 'Qt5Core' found
No package 'Qt5Widgets' found
No package 'Qt5Gui' found
No package 'Qt5Quick' found
No package 'Qt5QuickWidgets' found
No package 'Qt5QuickControls2' found
No package 'Qt5Svg' found. If you want to build VLC without GUI, pass --disable-qt.
```
&nbsp;&nbsp;&nbsp;&nbsp;解决办法嘛：
```shell
$ apt-get install qtdeclarative5-devel
```
&nbsp;&nbsp;&nbsp;&nbsp;13）遇到的第13个问题是：
```shell
configure: error: No package 'Qt5QuickControls2' found
No package 'Qt5Svg' found. If you want to build VLC without GUI, pass --disable-qt.
```
&nbsp;&nbsp;&nbsp;&nbsp;解决办法嘛：
```shell
$ apt-get install libqt5quickcontrols2-5 libqt5svg5
```
&nbsp;&nbsp;&nbsp;&nbsp;解决了以上问题，终于可以：
 ```shell
$ make 
$ ./vlc test.mp4
```
&nbsp;&nbsp;&nbsp;&nbsp;应该就可以播放界面了。