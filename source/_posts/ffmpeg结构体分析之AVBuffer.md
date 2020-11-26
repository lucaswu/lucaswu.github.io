---
title: ffmpeg结构体分析之AVBuffer
date: 2020-11-25 00:24:16
tags:
---
&nbsp;&nbsp;&nbsp;&nbsp;在ffmpeg中，很多数据的存储都是以AVBufferRef/AVBuffer为基础的。现在就来说说这两个结构体的关系。
<!--more-->     
&nbsp;&nbsp;&nbsp;&nbsp;AVBuffer定义在<libavutil\buffer_internal.h>中，对调用者是隐藏的。AVBufferRef定义在<libavutil\buffer.h>中，对调用者是公开的。    
* AVBuffer代表数据缓存本身，但一般情况下调用者不能直接调用它，需要通过AVBufferRef的调用，让API内部对AVBuffer进行操作。
* AVBufferRef是AVBuffer提供了一层封装，最主要的是作引用计数处理。    
## **AVBuffer结构体**
&nbsp;&nbsp;&nbsp;&nbsp;AVBuffer结构体的结构体定义如下：
```C
struct AVBuffer {
    uint8_t *data; /**< data described by this buffer */
    int      size; /**< size of data in bytes */

    /**
     *  number of existing AVBufferRef instances referring to this buffer
     */
    atomic_uint refcount;

    /**
     * a callback for freeing the data
     */
    void (*free)(void *opaque, uint8_t *data);

    /**
     * an opaque pointer, to be used by the freeing callback
     */
    void *opaque;

    /**
     * A combination of AV_BUFFER_FLAG_*
     */
    int flags;

    /**
     * A combination of BUFFER_FLAG_*
     */
    int flags_internal;
};
```
* data: 缓冲区地址
* size: 缓冲区大小
* refcount: 应用计数值
* free: 用于释放缓冲区内存的回调函数
* opaque: 提供给free回调函数的参数
* flags/flags_internal: 缓冲区标志    
## **AVBufferRef结构体**
&nbsp;&nbsp;&nbsp;&nbsp;AVBufferRef结构体的结构体定义如下：
```C
typedef struct AVBufferRef {
    AVBuffer *buffer;

    /**
     * The data buffer. It is considered writable if and only if
     * this is the only reference to the buffer, in which case
     * av_buffer_is_writable() returns 1.
     */
    uint8_t *data;
    /**
     * Size of data in bytes.
     */
    int      size;
} AVBufferRef;
```
* buffer:  真正的数据对象
* data: 缓冲区地址，实际等于buffer->data
* size: 缓冲区大小，实际等于buffer->size
## **相关函数分析**
### **av_buffer_alloc()**
```C
AVBufferRef *av_buffer_alloc(int size)
{
    AVBufferRef *ret = NULL;
    uint8_t    *data = NULL;

    data = av_malloc(size);
    if (!data)
        return NULL;

    ret = av_buffer_create(data, size, av_buffer_default_free, NULL, 0);
    if (!ret)
        av_freep(&data);

    return ret;
}
```
### **av_buffer_create()**
```C
AVBufferRef *av_buffer_create(uint8_t *data, int size,
                              void (*free)(void *opaque, uint8_t *data),
                              void *opaque, int flags)
{
    AVBufferRef *ref = NULL;
    AVBuffer    *buf = NULL;

    buf = av_mallocz(sizeof(*buf));
    if (!buf)
        return NULL;

    buf->data     = data;
    buf->size     = size;
    buf->free     = free ? free : av_buffer_default_free;
    buf->opaque   = opaque;

    atomic_init(&buf->refcount, 1);

    buf->flags = flags;

    ref = av_mallocz(sizeof(*ref));
    if (!ref) {
        av_freep(&buf);
        return NULL;
    }

    ref->buffer = buf;
    ref->data   = data;
    ref->size   = size;

    return ref;
}
```
### **av_buffer_ref()**
```C
AVBufferRef *av_buffer_ref(AVBufferRef *buf)
{
    AVBufferRef *ret = av_mallocz(sizeof(*ret));

    if (!ret)
        return NULL;

    *ret = *buf;

    atomic_fetch_add_explicit(&buf->buffer->refcount, 1, memory_order_relaxed);

    return ret;
}
```
&nbsp;&nbsp;&nbsp;&nbsp;这个函数的作用是新创建一个指向同一AVBuffer的引用参考。把传入的buf参数赋值给ref，也就是buf和ref将共有一份AVBuffer缓冲区，但缓冲区引用计数加1.

### **av_buffer_ref()**
```C
static void buffer_replace(AVBufferRef **dst, AVBufferRef **src)
{
    AVBuffer *b;

    b = (*dst)->buffer;

    if (src) {
        **dst = **src;
        av_freep(src);
    } else
        av_freep(dst);

    if (atomic_fetch_sub_explicit(&b->refcount, 1, memory_order_acq_rel) == 1) {
        b->free(b->opaque, b->data);
        av_freep(&b);
    }
}

void av_buffer_unref(AVBufferRef **buf)
{
    if (!buf || !*buf)
        return;

    buffer_replace(buf, NULL);
}
```
&nbsp;&nbsp;&nbsp;&nbsp;回收AVBufferRef **buf内存。将(*buf)->buffer的引用计数减1，若引用计数为0，则通过b->free(b->opaque, b->data)调用回调函数回收AVBuffer缓冲区内存。