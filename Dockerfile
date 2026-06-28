# syntax=docker/dockerfile:1

# --- Stage 1: Build BRouter ---
FROM eclipse-temurin:17-jdk-noble AS brouter-builder
RUN apt-get update && apt-get install -y git
RUN git clone --depth 1 https://github.com/abrensch/brouter.git /src
WORKDIR /src
RUN ./gradlew :brouter-server:fatJar

# --- Stage 2: Final Image ---
FROM ghcr.io/osgeo/gdal:ubuntu-small-latest

# Install System Dependencies
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && apt-get install -y \
    openjdk-17-jre-headless \
    zip \
    unzip \
    wget \
    procps \
    python3-pip \
    python3-venv \
    osmium-tool \
    gdal-bin \
    libgdal-dev \
    g++ \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*

# Create a venv that inherits system-level GDAL/GEOS bindings,
# then install our packages into it cleanly.
RUN python3 -m venv /opt/venv --system-site-packages
ENV PATH="/opt/venv/bin:$PATH"
RUN --mount=type=cache,target=/root/.cache/pip \
    GDAL_CONFIG=/usr/bin/gdal-config pip install \
    requests \
    tqdm \
    geopandas \
    shapely \
    osmium \
    --no-binary pyogrio pyogrio

WORKDIR /app

# --- Tool Acquisition (Isolation in /opt) ---

# 1. BRouter (Built from source)
# We recreate the structure expected by the scripts but in /opt
RUN mkdir -p /opt/brouter/brouter-server/build/libs/ && \
    mkdir -p /opt/brouter/misc/profiles2/
COPY --from=brouter-builder /src/brouter-server/build/libs/brouter-*-all.jar /opt/brouter/brouter-server/build/libs/brouter-1.7.8-all.jar
COPY --from=brouter-builder /src/misc/profiles2/ /opt/brouter/misc/profiles2/

# 2. OsmAndMapCreator (Latest Nightly)
RUN wget -q http://download.osmand.net/latest-night-build/OsmAndMapCreator-main.zip -O /tmp/omc.zip && \
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
