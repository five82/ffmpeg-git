# Custom ffmpeg Dockerfile

# Versions:

# ffmpeg      - git master HEAD
# libvmaf    - 2.3.0
# libzimg    - git master HEAD
# libopus    - git master HEAD
# libx264    - git master HEAD
# libx265    - git master HEAD
# libsvtav1  - git master HEAD
# libaom     - git master HEAD


#-------------------------------
# Use Debian for our build image
#-------------------------------
FROM debian:stable-slim AS build

#----------------------------------
# Set the working directory to /app
#----------------------------------
WORKDIR /app

#---------------------------------------------------------------
# Copy the current directory contents into the container at /app
#---------------------------------------------------------------
COPY . /app

#--------------------------------
# Update and install dependencies
#--------------------------------
# No, we're not going to version every apt package dependency.
# That's a bad idea in practice and will cause problems.
# hadolint ignore=DL3008
RUN \
apt-get update && \
apt-get install -y \
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
pip3 install --no-cache-dir meson && \
#------------------
# Setup directories
#------------------
mkdir -p /input /output /ffmpeg/ffmpeg_sources && \
#-------------
# Build ffmpeg
#-------------
./build-ffmpeg.sh

#-----------------------------------------
# Use Debian for our multistage base image
#-----------------------------------------
FROM debian:stable-slim

#----------------------------------
# Set the working directory to /app
#----------------------------------
WORKDIR /app

#----------------------------------------
# Copy files/directories from build image
#----------------------------------------
COPY --from=build /usr/local/bin /usr/local/bin

#-------------------------
# Remove unneeded binaries
#-------------------------
RUN \
rm -f \
/usr/local/bin/SvtAv1DecApp \
/usr/local/bin/aomdec \
/usr/local/bin/meson

#---------------------------------------
# Run ffmpeg when the container launches
#---------------------------------------
CMD ["ffmpeg"]
