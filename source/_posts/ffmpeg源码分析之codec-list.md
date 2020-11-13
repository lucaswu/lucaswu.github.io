---
title: ffmpeg源码分析之codec_list
date: 2020-11-12 22:58:54
tags:
---
&nbsp;&nbsp;&nbsp;&nbsp;在看ffmpeg自带example中的encoder_video.c的源码，遇到的第一个ffmpeg函数就是avcodec_find_encoder_by_name，最后跳转到av_codec_iterate函数，函数内部code_list的AVCodec数组，搜索整个目录发现只有在libavcodec/allcodes.c中定义为：
```c
#if CONFIG_OSSFUZZ
AVCodec * codec_list[] = {
    NULL,
    NULL,
    NULL
};
#else
#include "libavcodec/codec_list.c"
#endif
```
<!--more-->
&nbsp;&nbsp;&nbsp;&nbsp;显然是走到else分支，但是codec_list.c文件却没有找到。**最后发现竟然是在./configure的时候生成的。**    
&nbsp;&nbsp;&nbsp;&nbsp;在configure文件中，搜到如下代码：
```shell
...
find_things_extern(){
    thing=$1
    pattern=$2
    file=$source_path/$3
    out=${4:-$thing}
    sed -n "s/^[^#]*extern.*$pattern *ff_\([^ ]*\)_$thing;/\1_$out/p" "$file"
}

find_filters_extern(){
    file=$source_path/$1
    sed -n 's/^extern AVFilter ff_[avfsinkrc]\{2,5\}_\([[:alnum:]_]\{1,\}\);/\1_filter/p' $file
}

FILTER_LIST=$(find_filters_extern libavfilter/allfilters.c)
OUTDEV_LIST=$(find_things_extern muxer AVOutputFormat libavdevice/alldevices.c outdev)
INDEV_LIST=$(find_things_extern demuxer AVInputFormat libavdevice/alldevices.c indev)
MUXER_LIST=$(find_things_extern muxer AVOutputFormat libavformat/allformats.c)
DEMUXER_LIST=$(find_things_extern demuxer AVInputFormat libavformat/allformats.c)
ENCODER_LIST=$(find_things_extern encoder AVCodec libavcodec/allcodecs.c)
DECODER_LIST=$(find_things_extern decoder AVCodec libavcodec/allcodecs.c)
CODEC_LIST="
    $ENCODER_LIST
    $DECODER_LIST
"
...

# generate the lists of enabled components
print_enabled_components(){
    file=$1
    struct_name=$2
    name=$3
    shift 3
    echo "static const $struct_name * const $name[] = {" > $TMPH
    for c in $*; do
        if enabled $c; then
            case $name in
                filter_list)
                    eval c=\$full_filter_name_${c%_filter}
                ;;
                indev_list)
                    c=${c%_indev}_demuxer
                ;;
                outdev_list)
                    c=${c%_outdev}_muxer
                ;;
            esac
            printf "    &ff_%s,\n" $c >> $TMPH
        fi
    done
    if [ "$name" = "filter_list" ]; then
        for c in asrc_abuffer vsrc_buffer asink_abuffer vsink_buffer; do
            printf "    &ff_%s,\n" $c >> $TMPH
        done
    fi
    echo "    NULL };" >> $TMPH
    cp_if_changed $TMPH $file
}

print_enabled_components libavfilter/filter_list.c AVFilter filter_list $FILTER_LIST
print_enabled_components libavcodec/codec_list.c AVCodec codec_list $CODEC_LIST
print_enabled_components libavcodec/parser_list.c AVCodecParser parser_list $PARSER_LIST
print_enabled_components libavcodec/bsf_list.c AVBitStreamFilter bitstream_filters $BSF_LIST
print_enabled_components libavformat/demuxer_list.c AVInputFormat demuxer_list $DEMUXER_LIST
print_enabled_components libavformat/muxer_list.c AVOutputFormat muxer_list $MUXER_LIST
print_enabled_components libavdevice/indev_list.c AVInputFormat indev_list $INDEV_LIST
print_enabled_components libavdevice/outdev_list.c AVOutputFormat outdev_list $OUTDEV_LIST
print_enabled_components libavformat/protocol_list.c URLProtocol url_protocols $PROTOCOL_LIST
```
&nbsp;&nbsp;&nbsp;&nbsp;看到以上代码，舒了一口气，codec_list.c终于找到了。正则表达式去查找libavcodec/allcodecs.c中声明的encoder和decoder，
```c
...
extern AVCodec ff_a64multi_encoder;
extern AVCodec ff_a64multi5_encoder;
extern AVCodec ff_aasc_decoder;
extern AVCodec ff_aic_decoder;
extern AVCodec ff_alias_pix_encoder;
extern AVCodec ff_alias_pix_decoder;
extern AVCodec ff_agm_decoder;
extern AVCodec ff_amv_encoder;
extern AVCodec ff_amv_decoder;
extern AVCodec ff_anm_decoder;
extern AVCodec ff_ansi_decoder;
extern AVCodec ff_apng_encoder;
extern AVCodec ff_apng_decoder;
extern AVCodec ff_arbc_decoder;
extern AVCodec ff_argo_decoder;
extern AVCodec ff_asv1_encoder;
extern AVCodec ff_asv1_decoder;
extern AVCodec ff_asv2_encoder;
extern AVCodec ff_asv2_decoder;
extern AVCodec ff_aura_decoder;
extern AVCodec ff_aura2_decoder;
extern AVCodec ff_avrp_encoder;
extern AVCodec ff_avrp_decoder;
extern AVCodec ff_avrn_decoder;
extern AVCodec ff_avs_decoder;
extern AVCodec ff_avui_encoder;
extern AVCodec ff_avui_decoder;
extern AVCodec ff_ayuv_encoder;
extern AVCodec ff_ayuv_decoder;
extern AVCodec ff_bethsoftvid_decoder;
extern AVCodec ff_bfi_decoder;
extern AVCodec ff_bink_decoder;
extern AVCodec ff_bitpacked_decoder;
extern AVCodec ff_bmp_encoder;
...
```
---------
&nbsp;&nbsp;&nbsp;&nbsp;题外话插一句：对我而言，开源项目认真看了的项目是tensorflow lite，MACE和MNN，最近才开始认真阅读ffmpeg的源码，但给我带来的冲击远比其他开源项目大，感慨c原来也可以这么玩。