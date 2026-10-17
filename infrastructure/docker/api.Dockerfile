FROM python:3.12-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl git ca-certificates nmap build-essential unzip \
    && rm -rf /var/lib/apt/lists/*

# ProjectDiscovery tools (Hunter Option A — in-process scans)
ARG SUBFINDER_VERSION=2.6.7
ARG HTTPX_VERSION=1.6.9
ARG NUCLEI_VERSION=3.3.7
RUN set -eux; \
    for spec in "subfinder:${SUBFINDER_VERSION}" "httpx:${HTTPX_VERSION}" "nuclei:${NUCLEI_VERSION}"; do \
        tool="${spec%%:*}"; ver="${spec##*:}"; \
        curl -sSfL -o "/tmp/${tool}.zip" "https://github.com/projectdiscovery/${tool}/releases/download/v${ver}/${tool}_${ver}_linux_amd64.zip"; \
        unzip -o "/tmp/${tool}.zip" "${tool}" -d /usr/local/bin; \
        chmod +x "/usr/local/bin/${tool}"; \
        rm -f "/tmp/${tool}.zip"; \
    done; \
    subfinder -version; httpx -version; nuclei -version

RUN nuclei -update-templates || echo "nuclei template update failed; templates will be fetched at runtime"


WORKDIR /app
COPY packages/security /app/packages/security
COPY packages/shared /app/packages/shared
COPY services/detection /app/services/detection
COPY services/ai /app/services/ai
COPY services/api /app/services/api

RUN pip install --no-cache-dir \
    -e /app/packages/security \
    -e /app/packages/shared \
    -e /app/services/detection \
    -e /app/services/ai \
    -e /app/services/api

WORKDIR /app/services/api
ENV SCANNER_MODE=local
ENV ENVIRONMENT=production
EXPOSE 8000
CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}"]
