# Use Alpine as a base image
FROM alpine:latest

# Set the working directory to /app
WORKDIR /app

# Copy the current directory contents into the container at /app
ADD . /app

#--------------------------------
# Update and install dependencies
#--------------------------------
RUN \
export MAKEFLAGS="-j4" && \
apk --no-cache update && \
apk --no-cache upgrade && \
# Add build packages
apk add --no-cache --update \
  autoconf \
  automake \
  binutils \
  bzip2-dev \
  cmake \
  file \
  fortify-headers \
  g++ \
  gcc \
  gmp \
  isl \
  libatomic \
  libc-dev \
  libgomp \
  libmagic \
  libtool \
  make \
  mpc1 \
  mpfr3 \
  musl-dev \
  nasm \
  yasm && \
# Add FFmpeg dependencies
apk add --no-cache --update \
  libgcc \
  libstdc++ \
  freetype-dev && \
# Add system packages
apk add --no-cache --update \
  bash \
  coreutils \
  curl \
  git && \
#------------------
# Setup directories
#------------------
mkdir -p /input /output /ffmpeg/ffmpeg_sources && \
#----------------
# Download source
#----------------
cd /ffmpeg/ffmpeg_sources && \
git clone https://github.com/sekrit-twc/zimg.git && \
git clone https://github.com/Netflix/vmaf.git && \
git clone --depth 1 https://github.com/xiph/opus.git && \
git clone --depth 1 https://git.videolan.org/git/x264 && \
git clone https://github.com/videolan/x265.git && \
curl -O https://ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2 && \
tar xjf ffmpeg-snapshot.tar.bz2 && \
#-------------------
# Compile z.lib/zimg
#-------------------
cd /ffmpeg/ffmpeg_sources/zimg && \
./autogen.sh && \
./configure && \
make ${MAKEFLAGS} && \
make install && \
#----------------
# Compile libvmaf
#----------------
cd /ffmpeg/ffmpeg_sources/vmaf/ptools && \
make ${MAKEFLAGS} && \
cd ../wrapper && \
make ${MAKEFLAGS} && \
cd .. && \
make install && \
#----------------
# Compile libopus
#----------------
cd /ffmpeg/ffmpeg_sources/opus && \
./autogen.sh && \
./configure \
--disable-shared && \
make ${MAKEFLAGS} && \
make install && \
#-------------
# Compile x264
#-------------
cd /ffmpeg/ffmpeg_sources/x264 && \
./configure \
--bindir="$HOME/bin" \
--enable-static \
--enable-pic && \
make ${MAKEFLAGS} && \
make install && \
#-------------
# Compile x265
#-------------
cd /ffmpeg/ffmpeg_sources/x265/build/linux && \
mkdir -p 8bit 10bit && \
# 10 bit
cd 10bit && \
cmake -G "Unix Makefiles" \
../../../source \
-DHIGH_BIT_DEPTH=ON \
-DEXPORT_C_API=OFF \
-DENABLE_SHARED=OFF \
-DENABLE_CLI=OFF && \
make ${MAKEFLAGS} && \
# 8 bit
cd ../8bit && \
ln -sf ../10bit/libx265.a libx265_main10.a && \
cmake -G "Unix Makefiles" \
../../../source \
-DEXTRA_LIB="x265_main10.a" \
-DEXTRA_LINK_FLAGS=-L. \
-DLINKED_10BIT=ON && \
make ${MAKEFLAGS} && \
mv libx265.a libx265_main.a && \
ar -M </app/libx265.mri && \
make install && \
#---------------
# Compile ffmpeg
#---------------
cd /ffmpeg/ffmpeg_sources/ffmpeg && \
./configure \
--pkg-config-flags="--static" \
--extra-libs="-lpthread -lm" \
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
--enable-libx264 \
--enable-libx265 && \
make ${MAKEFLAGS} && \
make install && \
hash -r && \
#----------------------------------------------------
# Clean up directories and packages after compilation
#----------------------------------------------------
rm -rf /ffmpeg && \
# Remove build packages
apk del \
  autoconf \
  automake \
  binutils \
  bzip2-dev \
  cmake \
  file \
  fortify-headers \
  g++ \
  gcc \
  gmp \
  isl \
  libatomic \
  libc-dev \
  libgomp \
  libmagic \
  libtool \
  make \
  mpc1 \
  mpfr3 \
  musl-dev \
  nasm \
  yasm && \
# Remove system packages
apk del \
  coreutils \
  git && \
rm -rf /var/cache/apk/*
#---------------------------------------
# Run ffmpeg when the container launches
#---------------------------------------
CMD ["ffmpeg"]
