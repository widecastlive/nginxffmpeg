#!/bin/sh
on_die ()
{
    # kill all children
    pkill -KILL -P $$
}

trap 'on_die' TERM
cd /opt/data/hls/;
ffmpeg -i "rtmp://localhost:1935/$1/$2" \
    -filter_complex "[v:0]scale=1920:-2[vout1];[v:0]scale=1280:-2[vout2];[v:0]scale=320:-2[vout3]" \
    -g 25 -sc_threshold 0 \
    -map "[vout2]" -c:v:0 libx264 -b:v:0 1000k -maxrate:v:0 2500k -bufsize:v:0 5000k \
    -map "[vout3]" -c:v:1 libx264 -b:v:1 150k -maxrate:v:1 250k -bufsize:v:1 500k \
    -map "[vout1]" -c:v:2 libx264 -b:v:2 2500k -maxrate:v:2 5000k -bufsize:v:2 8000k \
    -map a:0 -c:a aac -b:a 92k -ac 2 \
    -f hls -hls_time 6 -hls_segment_type fmp4 \
    -master_pl_name master.m3u8 \
    -strftime 1 -hls_segment_filename output_%v/segment_%s.m4s \
    -var_stream_map "a:0,agroup:audio v:0,agroup:audio v:1,agroup:audio v:2,agroup:audio" output_%v/stream.m3u8 &
wait