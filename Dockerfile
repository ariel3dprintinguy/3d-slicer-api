FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

# Install necessary packages
RUN apt-get update && apt-get install -y \
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
RUN mkdir -p ./prusaslicer/bin && \
    FILE_PATH="prusaslicer/bin/bambu-studio" && \
    REPO="ariel3dprintinguy/3d-slicer-api" && \
    echo "Fetching file info..." && \
    FILE_INFO=$(curl -sS -H "Authorization: token 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" \
        "https://api.github.com/repos/$REPO/contents/$FILE_PATH") && \
    echo "File info: $FILE_INFO" && \
    if [ "$(echo "$FILE_INFO" | jq -r .message)" = "Not Found" ]; then \
        echo "Error: File not found" && exit 1; \
    fi && \
    SHA=$(echo $FILE_INFO | jq -r .sha) && \
    echo "SHA: $SHA" && \
    echo "Fetching LFS info..." && \
    LFS_INFO=$(curl -sS -H "Authorization: token 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" \
        "https://api.github.com/repos/$REPO/git/blobs/$SHA" | jq -r .content | base64 -d) && \
    echo "LFS info: $LFS_INFO" && \
    OID=$(echo "$LFS_INFO" | grep oid | cut -d' ' -f2) && \
    SIZE=$(echo "$LFS_INFO" | grep size | cut -d' ' -f2) && \
    echo "OID: $OID, Size: $SIZE" && \
    echo "Fetching download URL..." && \
    DOWNLOAD_URL=$(curl -sS -X POST \
        -H "Authorization: token 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" \
        -H "Accept: application/vnd.git-lfs+json" \
        -H "Content-Type: application/json" \
        -d "{\"operation\": \"download\", \"transfer\": [\"basic\"], \"objects\": [{\"oid\": \"$OID\", \"size\": $SIZE}]}" \
        "https://github.com/$REPO.git/info/lfs/objects/batch" | \
        jq -r '.objects[0].actions.download.href') && \
    echo "Download URL: $DOWNLOAD_URL" && \
    if [ -z "$DOWNLOAD_URL" ]; then \
        echo "Error: Failed to get download URL" && exit 1; \
    fi && \
    echo "Downloading file..." && \
    curl -sS -L -o ./prusaslicer/bin/bambu-studio "$DOWNLOAD_URL" && \
    echo "Download complete. Checking file..." && \
    if [ ! -f ./prusaslicer/bin/bambu-studio ]; then \
        echo "Error: File not downloaded" && exit 1; \
    fi && \
    echo "File size: $(wc -c < ./prusaslicer/bin/bambu-studio) bytes" && \
    echo "File type: $(file ./prusaslicer/bin/bambu-studio)"

# Ensure Bambu Studio is executable
RUN chmod +x ./prusaslicer/bin/bambu-studio

EXPOSE 28508

CMD ["node", "index.js"]
