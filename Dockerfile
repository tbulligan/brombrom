# syntax=docker/dockerfile:1

FROM ghcr.io/osgeo/gdal:ubuntu-small-3.9.1

# Install System Dependencies
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && apt-get install -y \
    openjdk-17-jre-headless \
    zip \
    unzip \
    curl \
    procps \
    python3-pip \
    python3-venv \
    osmium-tool \
    gdal-bin \
    libgdal-dev \
    g++ \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Create a venv that inherits system-level GDAL/GEOS bindings,
# then install our packages into it cleanly.
RUN python3 -m venv /opt/venv --system-site-packages
ENV PATH="/opt/venv/bin:$PATH"

COPY requirements.txt .
RUN --mount=type=cache,target=/root/.cache/pip \
    GDAL_CONFIG=/usr/bin/gdal-config pip install --no-binary pyogrio -r requirements.txt

# --- Tool Acquisition (Isolation in /opt) ---

# 1. OsmAndMapCreator (Latest Nightly)
RUN curl -fsSL --connect-timeout 15 --retry 5 --retry-delay 5 --retry-connrefused --speed-limit 10240 --speed-time 30 https://download.osmand.net/latest-night-build/OsmAndMapCreator-main.zip -o /tmp/omc.zip && \
    unzip -q /tmp/omc.zip -d /opt/OsmAndMapCreator && \
    rm /tmp/omc.zip

# --- Project Files ---

# Copy source code (Context is small)
COPY . .

# Ensure scripts are executable
RUN chmod +x *.sh scripts/*.sh

# Entrypoint
ENV JAVA_OPTS="-Xmx6G"
ENTRYPOINT ["/bin/bash", "./run_full_build.sh"]

