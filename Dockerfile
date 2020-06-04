# Use Debian for our multistage build image
FROM debian:stable-slim AS build

# Set the working directory to /app
WORKDIR /app

# Copy the current directory contents into the container at /app
ADD . /app

#--------------------------------
# Update and install dependencies
#--------------------------------
RUN \
apt-get update && \
# Add build packages
apt-get install -y \
--no-install-recommends \
  autoconf \
  automake \
  build-essential \
  ca-certificates \
  cmake \
  libasound2 \
  libass-dev \
  libfreetype6-dev \
  libnuma-dev \
  libtool-bin \
  libsdl2-dev \
  libtool \
  libva-dev \
  libvdpau-dev \
  libvorbis-dev \
  libxcb1-dev \
  libxcb-shm0-dev \
  libxcb-xfixes0-dev \
  pkg-config \
  texinfo \
  zlib1g-dev \
  git-core \
  nasm \
  yasm && \
#------------------
# Setup directories
#------------------
mkdir -p /input /output /ffmpeg/ffmpeg_sources && \
#----------------
# Download source
#----------------
cd /ffmpeg/ffmpeg_sources && \
git clone https://github.com/sekrit-twc/zimg.git && \
git clone --branch v1.3.15 https://github.com/Netflix/vmaf.git && \
git clone --depth 1 https://github.com/xiph/opus.git && \
git clone --depth 1 https://code.videolan.org/videolan/x264.git && \
git clone https://github.com/videolan/x265.git && \
git clone https://github.com/OpenVisualCloud/SVT-HEVC && \
git clone https://github.com/FFmpeg/FFmpeg ffmpeg && \
#-------------------
# Compile z.lib/zimg
#-------------------
cd /ffmpeg/ffmpeg_sources/zimg && \
./autogen.sh && \
./configure \
--enable-static \
--disable-shared && \
make -j $(nproc) && \
make install && \
#----------------
# Compile libvmaf
#----------------
cd /ffmpeg/ffmpeg_sources/vmaf/ptools && \
make -j $(nproc) && \
cd ../wrapper && \
make -j $(nproc) && \
cd .. && \
make install && \
#----------------
# Compile libopus
#----------------
cd /ffmpeg/ffmpeg_sources/opus && \
./autogen.sh && \
./configure \
--disable-shared && \
make -j $(nproc) && \
make install && \
#-----------------
# Compile SVT-HEVC
#-----------------
cd /ffmpeg/ffmpeg_sources/SVT-HEVC/Build/linux && \
./build.sh release static install && \
#-------------
# Compile x264
#-------------
cd /ffmpeg/ffmpeg_sources/x264 && \
./configure \
--enable-static \
--enable-pic && \
make -j $(nproc) && \
make install && \
#-------------
# Compile x265
#-------------
cd /ffmpeg/ffmpeg_sources/x265/build/linux && \
cmake -G "Unix Makefiles" \
-DENABLE_SHARED=OFF \
-DSTATIC_LINK_CRT=ON \
-DENABLE_CLI=ON \
-DCMAKE_EXE_LINKER_FLAGS="-static" \
../../source && \
sed -i 's/-lgcc_s/-lgcc_eh/g' x265.pc && \
./multilib.sh && \
make install && \
#---------------
# Compile ffmpeg
#---------------
cd /ffmpeg/ffmpeg_sources/ffmpeg && \
git apply /ffmpeg/ffmpeg_sources/SVT-HEVC/ffmpeg_plugin/0001*.patch && \
./configure \
--pkg-config-flags="--static" \
--extra-cflags="-I/usr/local/include -static" \
--extra-ldflags="-L/usr/local/lib -static" \
--extra-libs="-lpthread -lm" \
--disable-shared \
--enable-static \
--disable-debug \
--disable-doc \
--disable-ffplay \
--enable-ffprobe \
--enable-gpl \
--enable-libfreetype \
--enable-libvmaf \
--enable-version3 \
--enable-libzimg \
--enable-libopus \
--enable-libsvthevc \
--enable-libx264 \
--enable-libx265 && \
make -j $(nproc) && \
make install && \
hash -r

# Use Debian for our multistage base image
FROM debian:stable-slim

# Set the working directory to /app
WORKDIR /app

# Copy the vmaf models over
RUN mkdir /usr/local/share/model
COPY --from=build /ffmpeg/ffmpeg_sources/vmaf/model /usr/local/share/model

# Copy the binaries
COPY --from=build /usr/local/bin/ff* /usr/local/bin/
COPY --from=build /usr/local/bin/x265 /usr/local/bin/

#---------------------------------------
# Run ffmpeg when the container launches
#---------------------------------------
CMD ["ffmpeg"]