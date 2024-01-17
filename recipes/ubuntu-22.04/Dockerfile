FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive

RUN sed -i 's/archive.ubuntu.com/ubuntu.mirrors.ovh.net/g' /etc/apt/sources.list
RUN apt-get update -y

RUN apt-get install -y \
    gcc \
    libssl-dev \
    libpam-dev \
    libkrb5-dev \
    libffi-dev \
    libsystemd-dev \
    libx11-dev \
    libxtst-dev \
    libxcursor-dev \
    libxrandr-dev \
    libgtk2.0-dev \
    libgtk-3-dev \
    libglib2.0-dev \
    libappindicator-dev \
    libappindicator3-dev \
    libnotify-dev \
    libcups2-dev \
    libusb-1.0-0-dev \
    libudev-dev \
    libsdl2-dev \
    libsdl2-ttf-dev \
    libsoup-3.0-dev \
    libwebkit2gtk-4.1-dev \
    libvte-2.91-dev
