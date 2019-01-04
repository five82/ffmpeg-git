# ffmpeg

FFmpeg container compiled with the following configuration:

```--pkg-config-flags=--static --prefix=/ffmpeg/ffmpeg_build --extra-cflags='-I/ffmpeg/ffmpeg_build/include -static' --extra-ldflags='-L/ffmpeg/ffmpeg_build/lib -static' --extra-libs='-lpthread -lm' --bindir=/ffmpeg/bin --enable-static --disable-shared --disable-debug --disable-doc --disable-ffplay --enable-ffprobe --enable-gpl --enable-libfreetype --enable-libopus --enable-libx264 --enable-libx265```

This is used as a base image for five82\batchtranscode but can be run as a standalone container.

    docker run \
    --name ffmpeg \
    -v <path/to/input/dir>:/input \
    -v <path/to/output/dir>:/output \
    five82/ffmpeg *options*
