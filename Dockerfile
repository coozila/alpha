# 'dev' or 'release' container build
ARG BUILD_TYPE=dev

# Use an official Python base image from the Docker Hub
FROM python:3.10-slim AS alpha-base

# Install browsers
RUN apt-get update && apt-get install -y \
    chromium-driver firefox-esr ca-certificates \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install utilities
RUN apt-get update && apt-get install -y \
    curl jq wget git \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Set environment variables
ENV PIP_NO_CACHE_DIR=yes \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

# Install the required python packages globally
ENV PATH="$PATH:/root/.local/bin"
COPY requirements.txt .

# Set the entrypoint
ENTRYPOINT ["python", "-m", "alpha", "--install-plugin-deps"]

# dev build -> include everything
FROM alpha-base as alpha-dev
RUN pip install --default-timeout=300 --no-cache-dir -r requirements.txt
WORKDIR /app
ONBUILD COPY . ./

# release build -> include bare minimum
FROM alpha-base as alpha-release
RUN sed -i '/Items below this point will not be included in the Docker Image/,$d' requirements.txt && \
	pip install --no-cache-dir -r requirements.txt
WORKDIR /app
ONBUILD COPY alpha/ ./alpha
ONBUILD COPY scripts/ ./scripts
ONBUILD COPY plugins/ ./plugins
ONBUILD RUN mkdir ./data

FROM alpha-${BUILD_TYPE} AS alpha
