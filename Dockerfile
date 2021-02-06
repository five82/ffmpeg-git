# Custom ffmpeg Dockerfile

# Versions:

# ffmpeg     - git master HEAD
# libvmaf    - 2.1.1
# libzimg    - git master HEAD
# libopus    - git master HEAD
# libx264    - git master HEAD
# libx265    - git master HEAD
# libsvthevc - git master HEAD
# libsvtvp9  - git master HEAD
# libsvtav1  - git master HEAD


# Use Debian for our base image
FROM docker.io/debian:stable-slim AS build

# Set the working directory to /app
WORKDIR /app

# Copy the current directory contents into the container at /app
ADD . /app

#--------------------------------
# Update and install dependencies
#--------------------------------
RUN \
apt update && \
apt install -y \
  --no-install-recommends \
  autoconf \
  automake \
  build-essential \
  ca-certificates \
  cmake \
  doxygen \
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
  ninja-build \
  pkg-config \
  python3 \
  python3-pip \
  python3-setuptools \
  python3-wheel \
  texinfo \
  zlib1g-dev \
  git-core \
  nasm \
  yasm && \
#--------------
# Install meson
#--------------
pip3 install meson && \
#------------------
# Setup directories
#------------------
mkdir -p /input /output /ffmpeg/ffmpeg_sources && \
#----------------
# Download source
#----------------
cd /ffmpeg/ffmpeg_sources && \
git clone https://github.com/sekrit-twc/zimg.git && \
git clone --branch v2.1.1 https://github.com/Netflix/vmaf.git && \
git clone --depth 1 https://github.com/xiph/opus.git && \
git clone --depth 1 https://code.videolan.org/videolan/x264.git && \
git clone https://github.com/videolan/x265.git && \
git clone https://github.com/OpenVisualCloud/SVT-HEVC && \
git clone https://github.com/OpenVisualCloud/SVT-VP9.git && \
git clone https://github.com/AOMediaCodec/SVT-AV1.git && \
git clone https://github.com/FFmpeg/FFmpeg ffmpeg && \
#-------------------
# Compile z.lib/zimg
#-------------------
cd /ffmpeg/ffmpeg_sources/zimg && \
./autogen.sh && \
./configure && \
make -j $(nproc) && \
make install && \
#----------------
# Compile libvmaf
#----------------
cd /ffmpeg/ffmpeg_sources/vmaf/libvmaf && \
meson build --buildtype release && \
ninja -vC build && \
ninja -vC build install && \
mkdir -p /usr/local/share/model/ && \
cp -r /ffmpeg/ffmpeg_sources/vmaf/model/* /usr/local/share/model/ && \
#----------------
# Compile libopus
#----------------
cd /ffmpeg/ffmpeg_sources/opus && \
./autogen.sh && \
./configure && \
make -j $(nproc) && \
make install && \
#-------------------
# Compile libsvthevc
#-------------------
cd /ffmpeg/ffmpeg_sources/SVT-HEVC/Build/linux && \
./build.sh release install && \
#------------------
# Compile libsvtvp9
#------------------
cd /ffmpeg/ffmpeg_sources/SVT-VP9/Build && \
cmake .. -DCMAKE_BUILD_TYPE=Release && \
make -j $(nproc) && \
make install && \
#------------------
# Compile libsvtav1
#------------------
cd /ffmpeg/ffmpeg_sources/SVT-AV1/Build && \
cmake .. -G"Unix Makefiles" -DCMAKE_BUILD_TYPE=Release && \
make -j $(nproc) && \
make install && \
#----------------
# Compile libx264
#----------------
cd /ffmpeg/ffmpeg_sources/x264 && \
./configure \
  --enable-static \
  --enable-pic && \
make -j $(nproc) && \
make install && \
#----------------
# Compile libx265
#----------------
cd /ffmpeg/ffmpeg_sources/x265/build/linux && \
cmake -G "Unix Makefiles" \
  -DHIGH_BIT_DEPTH=on \
  -DENABLE_CLI=OFF \
  ../../source && \
make install && \
make clean && \
#---------------
# Compile ffmpeg
#---------------
cd /ffmpeg/ffmpeg_sources/ffmpeg && \
# apply libsvthevc patches
git apply /ffmpeg/ffmpeg_sources/SVT-HEVC/ffmpeg_plugin/0001*.patch && \
# apply libsvtvp9 patch
git apply /ffmpeg/ffmpeg_sources/SVT-VP9/ffmpeg_plugin/master-0001-Add-ability-for-ffmpeg-to-run-svt-vp9.patch && \
./configure \
  --disable-static \
  --enable-shared \
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
  --enable-libsvthevc \
  --enable-libsvtvp9 \
  --enable-libsvtav1 && \
make -j $(nproc) && \
make install && \
hash -r && \
#----------------------------------------------------
# Clean up directories and packages after compilation
#----------------------------------------------------
pip3 uninstall meson -y && \
apt purge -y \
  autoconf \
  automake \
  build-essential \
  ca-certificates \
  cmake \
  doxygen \
  ninja-build \
  pkg-config \
  python3-pip \
  python3-setuptools \
  python3-wheel \
  texinfo \
  git-core \
  nasm \
  yasm && \
apt autoremove -y && \
apt install -y \
  --no-install-recommends \
  libsdl2-dev && \
apt clean && \
apt autoclean && \
rm -rf /ffmpeg
#---------------------------------------
# Run ffmpeg when the container launches
#---------------------------------------
CMD ["ffmpeg"]
