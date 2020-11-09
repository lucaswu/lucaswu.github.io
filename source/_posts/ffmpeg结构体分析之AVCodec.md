---
title: ffmpeg结构体分析之AVCodec
date: 2020-11-09 23:23:09
tags:
---
&nbsp;&nbsp;&nbsp;&nbsp;(在开始之前，说几句题外话。本来自己的flag是vlc代码分析，加上工作上也在ijkplayer中分析快手的LAS。看下对于播放器而言，对于软解，基本都是直接在ffmpeg基础上套了一层，所以自己还是来翻翻ffmpeg，先熟悉ffmpeg的源码。我下载版本为4.3.1的ffmpeg的源码)
&nbsp;&nbsp;&nbsp;&nbsp;AVCodec是视(音)频编解码器对应的一个结构体，存储编解码器的相关信息，定义在libavcodec/codec.h文件中。先把源码贴出来：
```c
typedef struct AVCodec {
    /**
     * Name of the codec implementation.
     * The name is globally unique among encoders and among decoders (but an
     * encoder and a decoder can share the same name).
     * This is the primary way to find a codec from the user perspective.
     */
    const char *name;
    /**
     * Descriptive name for the codec, meant to be more human readable than name.
     * You should use the NULL_IF_CONFIG_SMALL() macro to define it.
     */
    const char *long_name;
    enum AVMediaType type;
    enum AVCodecID id;
    /**
     * Codec capabilities.
     * see AV_CODEC_CAP_*
     */
    int capabilities;
    const AVRational *supported_framerates; ///< array of supported framerates, or NULL if any, array is terminated by {0,0}
    const enum AVPixelFormat *pix_fmts;     ///< array of supported pixel formats, or NULL if unknown, array is terminated by -1
    const int *supported_samplerates;       ///< array of supported audio samplerates, or NULL if unknown, array is terminated by 0
    const enum AVSampleFormat *sample_fmts; ///< array of supported sample formats, or NULL if unknown, array is terminated by -1
    const uint64_t *channel_layouts;         ///< array of support channel layouts, or NULL if unknown. array is terminated by 0
    uint8_t max_lowres;                     ///< maximum value for lowres supported by the decoder
    const AVClass *priv_class;              ///< AVClass for the private context
    const AVProfile *profiles;              ///< array of recognized profiles, or NULL if unknown, array is terminated by {FF_PROFILE_UNKNOWN}

    /**
     * Group name of the codec implementation.
     * This is a short symbolic name of the wrapper backing this codec. A
     * wrapper uses some kind of external implementation for the codec, such
     * as an external library, or a codec implementation provided by the OS or
     * the hardware.
     * If this field is NULL, this is a builtin, libavcodec native codec.
     * If non-NULL, this will be the suffix in AVCodec.name in most cases
     * (usually AVCodec.name will be of the form "<codec_name>_<wrapper_name>").
     */
    const char *wrapper_name;

    /*****************************************************************
     * No fields below this line are part of the public API. They
     * may not be used outside of libavcodec and can be changed and
     * removed at will.
     * New public fields should be added right above.
     *****************************************************************
     */
    int priv_data_size;
    struct AVCodec *next;
    /**
     * @name Frame-level threading support functions
     * @{
     */
    /**
     * Copy necessary context variables from a previous thread context to the current one.
     * If not defined, the next thread will start automatically; otherwise, the codec
     * must call ff_thread_finish_setup().
     *
     * dst and src will (rarely) point to the same context, in which case memcpy should be skipped.
     */
    int (*update_thread_context)(struct AVCodecContext *dst, const struct AVCodecContext *src);
    /** @} */

    /**
     * Private codec-specific defaults.
     */
    const AVCodecDefault *defaults;

    /**
     * Initialize codec static data, called from avcodec_register().
     *
     * This is not intended for time consuming operations as it is
     * run for every codec regardless of that codec being used.
     */
    void (*init_static_data)(struct AVCodec *codec);

    int (*init)(struct AVCodecContext *);
    int (*encode_sub)(struct AVCodecContext *, uint8_t *buf, int buf_size,
                      const struct AVSubtitle *sub);
    /**
     * Encode data to an AVPacket.
     *
     * @param      avctx          codec context
     * @param      avpkt          output AVPacket (may contain a user-provided buffer)
     * @param[in]  frame          AVFrame containing the raw data to be encoded
     * @param[out] got_packet_ptr encoder sets to 0 or 1 to indicate that a
     *                            non-empty packet was returned in avpkt.
     * @return 0 on success, negative error code on failure
     */
    int (*encode2)(struct AVCodecContext *avctx, struct AVPacket *avpkt,
                   const struct AVFrame *frame, int *got_packet_ptr);
    int (*decode)(struct AVCodecContext *, void *outdata, int *outdata_size, struct AVPacket *avpkt);
    int (*close)(struct AVCodecContext *);
    /**
     * Encode API with decoupled packet/frame dataflow. The API is the
     * same as the avcodec_ prefixed APIs (avcodec_send_frame() etc.), except
     * that:
     * - never called if the codec is closed or the wrong type,
     * - if AV_CODEC_CAP_DELAY is not set, drain frames are never sent,
     * - only one drain frame is ever passed down,
     */
    int (*send_frame)(struct AVCodecContext *avctx, const struct AVFrame *frame);
    int (*receive_packet)(struct AVCodecContext *avctx, struct AVPacket *avpkt);

    /**
     * Decode API with decoupled packet/frame dataflow. This function is called
     * to get one output frame. It should call ff_decode_get_packet() to obtain
     * input data.
     */
    int (*receive_frame)(struct AVCodecContext *avctx, struct AVFrame *frame);
    /**
     * Flush buffers.
     * Will be called when seeking
     */
    void (*flush)(struct AVCodecContext *);
    /**
     * Internal codec capabilities.
     * See FF_CODEC_CAP_* in internal.h
     */
    int caps_internal;

    /**
     * Decoding only, a comma-separated list of bitstream filters to apply to
     * packets before decoding.
     */
    const char *bsfs;

    /**
     * Array of pointers to hardware configurations supported by the codec,
     * or NULL if no hardware supported.  The array is terminated by a NULL
     * pointer.
     *
     * The user can only access this field via avcodec_get_hw_config().
     */
    const struct AVCodecHWConfigInternal **hw_configs;

    /**
     * List of supported codec_tags, terminated by FF_CODEC_TAGS_END.
     */
    const uint32_t *codec_tags;
}AVCodec;
```
现在逐个来说明下结构体中的变量    
1. **const char *name** ：编解码器的名字，比较短    
2. **const char *long_name** :编解码器的名字，全称    
3. **enum AVMediaType type** :媒体类型,视频、音频、字幕等  
```c
   enum AVMediaType {
    AVMEDIA_TYPE_UNKNOWN = -1,  ///< Usually treated as AVMEDIA_TYPE_DATA
    AVMEDIA_TYPE_VIDEO,
    AVMEDIA_TYPE_AUDIO,
    AVMEDIA_TYPE_DATA,          ///< Opaque data information usually continuous
    AVMEDIA_TYPE_SUBTITLE,
    AVMEDIA_TYPE_ATTACHMENT,    ///< Opaque data information usually sparse
    AVMEDIA_TYPE_NB
};
```
4. **enum AVCodecID id** ：编解码器ID，定义太多，例如AV_CODEC_ID_HEVC、AV_CODEC_ID_H264、AV_CODEC_ID_VP8…… ffmpeg太强大了，支持的编解码器太多太多了。
5. **int capabilities** :编解码器的能力，例如：H264: CODEC_CAP_DR1|CODEC_CAP_DELAY|CODEC_CAP_SLICE_THREADS|CODEC_CAP_FRAME_THREADS
6. **const AVRational *supported_framerates** ：支持的帧率，例如25帧的话，(AVRational){1, 25}
7. **const enum AVPixelFormat *pix_fmts** ：针对视频而言，编解码器支持的数据格式，例如AV_PIX_FMT_YUV420P、AV_PIX_FMT_YUV422P、AV_PIX_FMT_RGB24……格式也是有很多多种
8. **const int *supported_samplerates** ：音频而言，编解码器支持的采样率
9. **const enum AVSampleFormat *sample_fmts** ：音频而言，编解码器支持的采样格式，例如：AV_SAMPLE_FMT_U8、AV_SAMPLE_FMT_S16、AV_SAMPLE_FMT_S16P……
10. **const uint64_t *channel_layouts** ：编解码器支持的声道数
11. **uint8_t max_lowres** ：解码器支持低分辨率的最大值
12. **const AVClass *priv_class** ：AVClass针对私有上下文，以后再来扒AVClass，暂时先跳过
13. **const AVProfile *profiles** ：公认的配置文件数组,如果未知则为NULL,数组由FF_PROFILE_UNKNOWN表示终止
14. **const char *wrapper_name** ：编解码器实现的组名
15. **int priv_data_size** ：私有数据总长度
16. **struct AVCodec *next** ：下一个链接对象