# ffmpeg-git

*This branch is an unfinished multistage build that significantly reduces the size of the docker image.*
*Known issues:*

    *- FFmpeg binary still has library dependencies*
    *- The arm64 build fails with a "too many GOT entries for -fpic, please recompile with -fPIC" error*


Available on [Docker Hub][1].

```docker pull five82/ffmpeg-git```

FFmpeg container compiled with the following configuration:

```--disable-static --enable-shared --disable-debug --disable-doc --disable-ffplay --enable-ffprobe --enable-gpl --enable-libfreetype --enable-version3 --enable-libvmaf --enable-libzimg --enable-libopus --enable-libx264 --enable-libx265 --enable-libsvtav1 --enable-libaom```

The Dockerfile will build ffmpeg and ffprobe binaries. The libx264 encoder is 8 bit. The libx265 encoder is 10 bit. libvmaf is intentionally versioned to maintain testing consistency.

Run ffmpeg commands using the example below:

    docker run \
    --rm \
    --name ffmpeg-git \
    -v <path/to/input/dir>:/input \
    -v <path/to/output/dir>:/output \
    five82/ffmpeg-git \
    ffmpeg -i /input/input.mkv -c:v libx264 -preset medium -crf 20 -c:a aac -b:a 384k /output/output.mkv

Versions:

- ffmpeg      - git master HEAD
- libvmaf    - 2.3.0
- libzimg    - git master HEAD
- libopus    - git master HEAD
- libx264    - git master HEAD
- libx265    - git master HEAD
- libsvthevc - git master HEAD
- libsvtvp9  - git master HEAD
- libsvtav1  - git master HEAD
- libaom     - git master HEAD

[1]: https://hub.docker.com/r/five82/ffmpeg-git/ "ffmpeg-git"
