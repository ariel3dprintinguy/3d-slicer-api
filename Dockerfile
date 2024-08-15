FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

# Install necessary packages
RUN apt-get update && apt-get install -y \
    git \
    git-lfs \
    curl \
    ca-certificates \
    jq \
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
    libnotify4 \
    libnss3 \
    libxss1 \
    libxtst6 \
    xdg-utils \
    libatspi2.0-0 \
    libdrm2 \
    libgbm1 \
    libxcb-dri3-0 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js
RUN curl -fsSL https://deb.nodesource.com/setup_14.x | bash - \
    && apt-get install -y nodejs

WORKDIR /app

# Copy package.json and package-lock.json (if available)
COPY package*.json ./

# Install npm dependencies
RUN npm install \
    && npm install express express-fileupload cors
# Copy the rest of your application
COPY . .
# Download Bambu Studio binary from GitHub LFS
ARG GITHUB_TOKEN
RUN git config --global credential.helper store && \
    echo "https://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:x-oauth-basic@github.com" > ~/.git-credentials && \
    git lfs install && \
    git clone https://github.com/ariel3dprintinguy/3d-slicer-api.git temp_repo && \
    cd temp_repo && \
    git lfs fetch --all && \
    git lfs checkout && \
    if [ -f prusaslicer/bin/bambu-studio ]; then \
        echo "Bambu Studio binary found" && \
        file prusaslicer/bin/bambu-studio && \
        mv prusaslicer/bin/bambu-studio /app/prusaslicer/bin/bambu-studio && \
        echo "Bambu Studio binary moved to /app/prusaslicer/bin/bambu-studio" && \
        file /app/prusaslicer/bin/bambu-studio; \
    else \
        echo "Error: Bambu Studio binary not found" && \
        exit 1; \
    fi && \
    cd .. && \
    rm -rf temp_repo && \
    rm ~/.git-credentials
# Ensure Bambu Studio is executable
RUN chmod +x ./prusaslicer/bin/bambu-studio

EXPOSE 28508

CMD ["node", "index.js"]
