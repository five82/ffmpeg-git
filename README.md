# ffmpeg-vmaf

Available on Docker Hub at https://hub.docker.com/r/five82/ffmpeg-vmaf/

```docker pull five82/ffmpeg-vmaf```

FFmpeg container compiled from git master HEAD with the following configuration:

```--pkg-config-flags=--static --extra-libs='-lpthread -lm' --disable-debug --disable-doc --disable-ffplay --enable-ffprobe --enable-gpl --enable-libfreetype --enable-libvmaf --enable-version3 --enable-libzimg --enable-libopus --enable-libx264 --enable-libx265```

Forked from five82/ffmpeg-git. Added libvmaf support for testing purposes.

Run ffmpeg commands using the example below:

    docker run \
    --name ffmpeg-vmaf \
    -v <path/to/input/dir>:/input \
    -v <path/to/output/dir>:/output \
    five82/ffmpeg-vmaf \
    ffmpeg -i /input/input.mkv -c:v libx264 -preset medium -crf 20 -c:a aac -b:a 384k /output/output.mkv
