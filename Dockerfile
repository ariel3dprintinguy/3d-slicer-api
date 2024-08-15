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
# Set up git lfs and fetch Bambu Studio binary
ARG GITHUB_TOKEN
RUN echo "Setting up git and attempting to clone repository..." && \
    git config --global credential.helper store && \
    echo "https://${GITHUB_TOKEN}:x-oauth-basic@github.com" > ~/.git-credentials && \
    git lfs install && \
    echo "Git LFS installed. Attempting to clone repository..." && \
    REPO_URL="https://github.com/ariel3dprintinguy/3d-slicer-api.git" && \
    echo "Repository URL: ${REPO_URL}" && \
    if git clone "${REPO_URL%/}" temp_repo; then \
        echo "Repository cloned successfully." && \
        cd temp_repo && \
        echo "Fetching LFS objects..." && \
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
            echo "Contents of prusaslicer/bin:" && \
            ls -la prusaslicer/bin && \
            exit 1; \
        fi && \
        cd .. && \
        rm -rf temp_repo; \
    else \
        echo "Failed to clone repository. Diagnostic information:" && \
        echo "Git version: $(git --version)" && \
        echo "Testing GitHub API access:" && \
        curl -H "Authorization: token ${GITHUB_TOKEN}" https://api.github.com/user && \
        echo "Testing repository access:" && \
        curl -H "Authorization: token ${GITHUB_TOKEN}" https://api.github.com/repos/ariel3dprintinguy/3d-slicer-api && \
        echo "Attempting to clone with verbose output:" && \
        GIT_CURL_VERBOSE=1 GIT_TRACE=1 git clone "${REPO_URL%/}" && \
        exit 1; \
    fi && \
    rm ~/.git-credentials
# Ensure Bambu Studio is executable
RUN chmod +x ./prusaslicer/bin/bambu-studio

EXPOSE 28508

CMD ["node", "index.js"]
