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
        libnotify4 \
        libnss3 \
        libxss1 \
        libxtst6 \
        xdg-utils \
        libatspi2.0-0 \
        libdrm2 \
        libgbm1 \
        libxcb-dri3-0 \
    && curl -sL https://deb.nodesource.com/setup_14.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
RUN git lfs install

WORKDIR /app

# Copy package.json and package-lock.json (if available)
COPY package*.json ./

# Install npm dependencies
RUN npm install

# Copy the rest of your application
COPY . .

# Specifically pull the Bambu Studio LFS file
RUN mkdir -p ./prusaslicer/bin && \
    git lfs pull --include="prusaslicer/bin/bambu-studio" --exclude=""

# Ensure Bambu Studio is executable
RUN chmod +x ./prusaslicer/bin/bambu-studio

EXPOSE 28508

CMD ["node", "index.js"]
