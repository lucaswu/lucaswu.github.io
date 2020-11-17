---
title: ffmpeg视频编码
date: 2020-11-11 19:33:16
tags:
---
&nbsp;&nbsp;&nbsp;&nbsp;FFmpeg编码流程如下图所示:    
![](/images/FFmpeg视频编码流程.png)  
<!--more-->   
&nbsp;&nbsp;&nbsp;&nbsp;流程来说：    
1. 通过编码器名字选择编码器：avcodec_find_encoder_by_name    
   例如：avcodec_find_encoder_by_name(“libx264”)。关于这个函数底层实现，我有迷惑的地方，{% post_link ffmpeg源码分析之codec-list 点击这里查看 %}。    
2. 分配编码器的上下文：avcodec_alloc_context3    
   这个函数返回的是AVCodecContext数据类型，关于AVCodecContext的分析，{% post_link ffmpeg结构体分析之AVCodecContext 点击这里查看 %}。
