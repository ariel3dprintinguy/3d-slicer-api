FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

# Install necessary packages including git and git-lfs
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    && curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | bash \
    && apt-get install -y git-lfs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js
RUN curl -fsSL https://deb.nodesource.com/setup_14.x | bash - \
    && apt-get install -y nodejs

# Set up git lfs
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
