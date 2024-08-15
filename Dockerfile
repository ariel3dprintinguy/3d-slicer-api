FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

# Install necessary packages
RUN apt-get update && apt-get install -y \
    wget \
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

RUN wget -O /tmp/bambu-studio "https://download.wetransfer.com/eugv/f9c7228d5bd94d4b1af68d019bacb6c720240815191532/298c801e234c850fd1e3059ca1c1159e148d78de/bambu-studio?cf=y&token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6ImRlZmF1bHQifQ.eyJleHAiOjE3MjM3NTAwMTEsImlhdCI6MTcyMzc0OTQxMSwiZG93bmxvYWRfaWQiOiI3M2E5NzBmNS01ZGI0LTQ4ZWItYTEyNS1mOWQzZGI1NTA5YTEiLCJzdG9yYWdlX3NlcnZpY2UiOiJzdG9ybSJ9.8f8OAtDpqqVNuDV2xxjARFibRJIu3DAo3NkZVDDIl2U"

# Make the downloaded file executable
RUN chmod +x /tmp/bambu-studio

# Move the file to the correct location
RUN mkdir -p /app/prusaslicer/bin && \
    mv /tmp/bambu-studio /app/prusaslicer/bin/bambu-studio

# Set the working directory
WORKDIR /app/prusaslicer/bin

# Set the entrypoint
ENTRYPOINT ["./bambu-studio"]
# Ensure Bambu Studio is executable
RUN chmod +x ./prusaslicer/bin/bambu-studio

EXPOSE 28508

CMD ["node", "index.js"]
