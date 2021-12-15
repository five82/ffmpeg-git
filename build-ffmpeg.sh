#!/bin/bash

# Compile and install ffmpeg.
# Environment setup and packages dependencies are handled by the Dockerfile.

#----------------
# Download source
#----------------
cd /ffmpeg/ffmpeg_sources || exit
git clone https://github.com/sekrit-twc/zimg.git
git clone --branch v2.3.0 https://github.com/Netflix/vmaf.git
git clone --depth 1 https://github.com/xiph/opus.git
git clone --depth 1 https://code.videolan.org/videolan/x264.git
git clone https://github.com/videolan/x265.git
git clone https://github.com/AOMediaCodec/SVT-AV1.git
git clone https://aomedia.googlesource.com/aom
git clone https://github.com/FFmpeg/FFmpeg ffmpeg

#-------------------
# Compile z.lib/zimg
#-------------------
echo "** Starting zimg compilation **"
cd /ffmpeg/ffmpeg_sources/zimg || exit
./autogen.sh
./configure \
  --enable-static \
  --disable-shared
make -j "$(nproc)"
make install

#----------------
# Compile libvmaf
#----------------
echo "** Starting libvmaf compilation **"
cd /ffmpeg/ffmpeg_sources/vmaf/libvmaf || exit
meson build \
  --buildtype release \
  --default-library=static \
  -Denable_tests=false \
  -Denable_docs=false \
  -Dbuilt_in_models=true
ninja -vC build
ninja -vC build install

#----------------
# Compile libopus
#----------------
echo "** Starting libopus compilation **"
cd /ffmpeg/ffmpeg_sources/opus || exit
./autogen.sh
./configure \
  --disable-shared \
  --enable-static
make -j "$(nproc)"
make install

#------------------
# Compile libsvtav1
#------------------
echo "** Starting libsvtav1 compilation **"
cd /ffmpeg/ffmpeg_sources/SVT-AV1/Build || exit
cmake .. \
  -G"Unix Makefiles" \
  -DBUILD_SHARED_LIBS=OFF \
  -DCMAKE_BUILD_TYPE=Release
make -j "$(nproc)"
make install

#----------------
# Compile libx264
#----------------
echo "** Starting libx264 compilation **"
cd /ffmpeg/ffmpeg_sources/x264 || exit
./configure \
  --enable-static \
  --disable-shared \
  --disable-opencl \
  --enable-pic
make -j "$(nproc)"
make install

#----------------
# Compile libx265
#----------------
echo "** Starting libx265 compilation **"
cd /ffmpeg/ffmpeg_sources/x265/build/linux || exit
cmake -G "Unix Makefiles" \
  -DENABLE_SHARED:BOOL=OFF \
  -DCMAKE_EXE_LINKER_FLAGS="-static" \
  -DSTATIC_LINK_CRT:BOOL=ON \
  -DHIGH_BIT_DEPTH:BOOL=ON \
  ../../source
sed -i 's/-lgcc_s/-lgcc_eh/g' x265.pc
make -j "$(nproc)"
make install

#---------------
# Compile libaom
#---------------
echo "** Starting libaom compilation **"
cd /ffmpeg/ffmpeg_sources/aom || exit
mkdir -p ../aom_build
cd ../aom_build || exit
cmake /ffmpeg/ffmpeg_sources/aom \
  -DBUILD_SHARED_LIBS=0 \
  -DENABLE_SHARED:BOOL=OFF
make -j "$(nproc)"
make install

#---------------
# Compile ffmpeg
#---------------
echo "** Starting ffmpeg compilation **"
cd /ffmpeg/ffmpeg_sources/ffmpeg || exit
./configure \
  --ld="g++" \
  --pkg-config-flags="--static" \
  --extra-cflags="-I/usr/local/include -static" \
  --extra-ldflags="-L/usr/local/lib -static" \
  --extra-libs="-lpthread -lm -lz" \
  --disable-debug \
  --disable-doc \
  --disable-ffplay \
  --enable-ffprobe \
  --enable-gpl \
  --enable-libfreetype \
  --enable-version3 \
  --enable-libvmaf \
  --enable-libzimg \
  --enable-libopus \
  --enable-libx264 \
  --enable-libx265 \
  --enable-libsvtav1 \
  --enable-libaom
make -j "$(nproc)"
make install
hash -r
