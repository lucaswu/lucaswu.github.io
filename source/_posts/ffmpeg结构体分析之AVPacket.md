---
title: ffmpeg结构体分析之AVPacket
date: 2020-11-24 23:46:06
tags:
---
&nbsp;&nbsp;&nbsp;&nbsp;AVPacket结构体定义在<libavcodec/packet.h>中，存储的是经过编码的压缩数据。具体的定义如下:
```C
typedef struct AVPacket {
    /**
     * A reference to the reference-counted buffer where the packet data is
     * stored.
     * May be NULL, then the packet data is not reference-counted.
     */
    AVBufferRef *buf;
    /**
     * Presentation timestamp in AVStream->time_base units; the time at which
     * the decompressed packet will be presented to the user.
     * Can be AV_NOPTS_VALUE if it is not stored in the file.
     * pts MUST be larger or equal to dts as presentation cannot happen before
     * decompression, unless one wants to view hex dumps. Some formats misuse
     * the terms dts and pts/cts to mean something different. Such timestamps
     * must be converted to true pts/dts before they are stored in AVPacket.
     */
    int64_t pts;
    /**
     * Decompression timestamp in AVStream->time_base units; the time at which
     * the packet is decompressed.
     * Can be AV_NOPTS_VALUE if it is not stored in the file.
     */
    int64_t dts;
    uint8_t *data;
    int   size;
    int   stream_index;
    /**
     * A combination of AV_PKT_FLAG values
     */
    int   flags;
    /**
     * Additional packet data that can be provided by the container.
     * Packet can contain several types of side information.
     */
    AVPacketSideData *side_data;
    int side_data_elems;

    /**
     * Duration of this packet in AVStream->time_base units, 0 if unknown.
     * Equals next_pts - this_pts in presentation order.
     */
    int64_t duration;

    int64_t pos;                            ///< byte position in stream, -1 if unknown

#if FF_API_CONVERGENCE_DURATION
    /**
     * @deprecated Same as the duration field, but as int64_t. This was required
     * for Matroska subtitles, whose duration values could overflow when the
     * duration field was still an int.
     */
    attribute_deprecated
    int64_t convergence_duration;
#endif
} AVPacket;

```
* buf: 用来管理data指针引用的数据缓存，关于AVBufferRef {% post_link ffmpeg结构体分析之AVBuffer 点击这里查看 %}
* pts: 显示时间，集合AVStream->time_base转换成时间戳
* dts: 解码时间，结合AVStream->time_base转换成时间戳
* data: 指向压缩数据的指针，AVPacket的实际数据
* size: 压缩数据的大小
* stream_index: packet在stream的index位置
* flags: 标识，结合AV_PKT_FLAG使用
* size_data: 容器可以提供的附加数据
* size_data_elems: 附加信息元素个数
* duration: 数据的时长，以所属流媒体的时间基准为单位
* pos: 数据在流媒体中的偏移量
  