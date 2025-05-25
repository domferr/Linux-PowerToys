FROM ubuntu:22.04

RUN apt update && apt install -y git curl unzip cmake libgtk-3-dev clang ninja-build wget

RUN wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.32.0-stable.tar.xz
RUN tar -xf flutter_linux_3.32.0-stable.tar.xz -C /
RUN git config --global --add safe.directory /flutter
#RUN git clone https://github.com/flutter/flutter.git
ENV PATH "$PATH:/flutter/bin"

# Run basic check to download Dark SDK
RUN flutter doctor

RUN wget -O appimage-builder-x86_64.AppImage https://github.com/AppImageCrafters/appimage-builder/releases/download/v1.1.0/appimage-builder-1.1.0-x86_64.AppImage
RUN chmod +x appimage-builder-x86_64.AppImage

RUN mv appimage-builder-x86_64.AppImage /usr/local/bin/appimage-builder

RUN mkdir /app
WORKDIR /app