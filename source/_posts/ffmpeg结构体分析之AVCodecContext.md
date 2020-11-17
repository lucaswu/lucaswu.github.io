---
title: ffmpeg结构体分析之AVCodecContext
date: 2020-11-13 00:13:13
tags:
---
&nbsp;&nbsp;&nbsp;&nbsp;在找到需要的音视频编解码器( AVCodec 数据类型)后，紧接着的就是分配编解码器的上下 AVCodecContext。    AVCodecContext 结构体的声明在libavcodec/avcodec.h中，很长很长……在此，就不把定义贴出来。 
&nbsp;&nbsp;&nbsp;&nbsp;在我个人看来，AVCodecContext 存放的是编解码器的一些参数。例如对于视频编码而言，视频的长宽信息，帧率，gopSize 等；对音频一些采样率，通道数等。
<!--more-->  