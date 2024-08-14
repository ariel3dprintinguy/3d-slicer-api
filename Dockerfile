FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

# Combine package installation and clean up cache to reduce layers and image size
RUN apt-get update \
    && apt-get install -y \
        libcairo2 \
        libglu1-mesa \
        gstreamer1.0-libav \
        gstreamer1.0-plugins-base \
        libgtk-3-0 \
        libsoup2.4-1 \
        libxkbcommon0 \
        libgl1-mesa-dri \
        libopenvdb-dev \
        fonts-noto \
        wayland-protocols \
        libwebkit2gtk-4.0-37 \
        libfuse2 \
        curl \
    && curl -sL https://deb.nodesource.com/setup_14.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN npm install \
    && npm install express express-fileupload cors

WORKDIR /app

COPY package*.json ./

# Install npm dependencies
RUN npm install

COPY . .

EXPOSE 3000

CMD ["node", "index.js"]
