FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Install necessary packages including Flatpak
RUN apt-get update && apt-get install -y \
    flatpak \
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
    libwebkit2gtk \
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
    libgstreamer1.0-0 \
    libgstreamer-plugins-base1.0-0 \
    libgstreamer-plugins-bad1.0-0 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Add Flathub repository
RUN flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Install BambuStudio from Flatpak
RUN flatpak install -y flathub com.bambulab.BambuStudio

# Install Node.js
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs

WORKDIR /app

# Copy package.json and package-lock.json (if available)
COPY package*.json ./

# Install npm dependencies
RUN npm install \
    && npm install express express-fileupload cors

# Copy the rest of your application
COPY . .

# Create a non-root user to run the application
RUN useradd -m appuser
RUN chown -R appuser:appuser /app
USER appuser

# Expose port for the Node.js application
EXPOSE 28508

# Set the entrypoint to run BambuStudio
ENTRYPOINT ["flatpak", "run", "com.bambulab.BambuStudio"]

# Set the default command to run the Node.js application
CMD ["node", "index.js"]
