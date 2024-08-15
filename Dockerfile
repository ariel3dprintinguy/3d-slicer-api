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
    GITHUB_TOKEN="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" && \
    FILE_PATH="prusaslicer/bin/bambu-studio" && \
    REPO="ariel3dprintinguy/3d-slicer-api" && \
    # Get file info
    FILE_INFO=$(curl -H "Authorization: token $GITHUB_TOKEN" \
        "https://api.github.com/repos/$REPO/contents/$FILE_PATH") && \
    # Extract SHA
    SHA=$(echo $FILE_INFO | jq -r .sha) && \
    # Get LFS file info
    LFS_INFO=$(curl -H "Authorization: token $GITHUB_TOKEN" \
        "https://api.github.com/repos/$REPO/git/blobs/$SHA" | jq -r .content | base64 -d) && \
    # Extract OID and SIZE
    OID=$(echo "$LFS_INFO" | grep oid | cut -d' ' -f2) && \
    SIZE=$(echo "$LFS_INFO" | grep size | cut -d' ' -f2) && \
    # Get download URL
    DOWNLOAD_URL=$(curl -X POST \
        -H "Authorization: token $GITHUB_TOKEN" \
        -H "Accept: application/vnd.git-lfs+json" \
        -H "Content-Type: application/json" \
        -d "{\"operation\": \"download\", \"transfer\": [\"basic\"], \"objects\": [{\"oid\": \"$OID\", \"size\": $SIZE}]}" \
        "https://github.com/$REPO.git/info/lfs/objects/batch" | \
        jq -r '.objects[0].actions.download.href') && \
    # Download the file
    curl -L -o ./prusaslicer/bin/bambu-studio "$DOWNLOAD_URL"

# Ensure Bambu Studio is executable
RUN chmod +x ./prusaslicer/bin/bambu-studio

EXPOSE 28508

CMD ["node", "index.js"]
