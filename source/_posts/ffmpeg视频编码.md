---
title: ffmpeg视频编码
date: 2020-11-11 19:33:16
tags:
---
&nbsp;&nbsp;&nbsp;&nbsp;FFmpeg编码流程如下图所示:    
![](/images/FFmpeg视频编码流程.png)    
&nbsp;&nbsp;&nbsp;&nbsp;流程来说：    
1. 通过编码器名字选择编码器，avcodec_find_encoder_by_name，例如：avcodec_find_encoder_by_name(“libx264”)