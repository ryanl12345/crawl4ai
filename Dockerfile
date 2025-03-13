FROM python:3.10-slim

# Set build arguments
ARG APP_HOME=/app
ARG INSTALL_TYPE=default

# Set environment variables
# Render’s default port is 10000
ENV PYTHONFAULTHANDLER=1 \
    PYTHONHASHSEED=random \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_DEFAULT_TIMEOUT=100 \
    DEBIAN_FRONTEND=noninteractive \
    PORT=10000

LABEL maintainer="unclecode"
LABEL description="🔥🕷️ Crawl4AI: Open-source LLM Friendly Web Crawler & scraper"
LABEL version="1.0"

# Install base dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    git \
    python3-dev \
    libjpeg-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Playwright dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libglib2.0-0 \
    libnss3 \
    libnspr4 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libcups2 \
    libdrm2 \
    libdbus-1-3 \
    libxcb1 \
    libxkbcommon0 \
    libx11-6 \
    libxcomposite1 \
    libxdamage1 \
    libxext6 \
    libxfixes3 \
    libxrandr2 \
    libgbm1 \
    libpango-1.0-0 \
    libcairo2 \
    libasound2 \
    libatspi2.0-0 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR ${APP_HOME}

# Copy and install requirements
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the project and install Crawl4AI
COPY . /tmp/project/
RUN ls -la /tmp/project/ && \  # Debug: Show copied files
    ls -la /tmp/project/crawl4ai/ && \  # Debug: Show crawl4ai directory
    pip install --no-cache-dir "/tmp/project/" && \
    python -c "import crawl4ai; print('✅ crawl4ai version:', crawl4ai.__version__)" && \
    python -c "import crawl4ai.server; print('✅ crawl4ai.server module found')" && \
    if [ "$INSTALL_TYPE" = "all" ]; then \
        pip install --no-cache-dir \
            torch \
            torchvision \
            torchaudio \
            scikit-learn \
            transformers \
            tokenizers && \
        python -m nltk.downloader punkt stopwords && \
        pip install "/tmp/project/[all]" && \
        python -m crawl4ai.model_loader; \
    elif [ "$INSTALL_TYPE" = "torch" ]; then \
        pip install "/tmp/project/[torch]"; \
    elif [ "$INSTALL_TYPE" = "transformer" ]; then \
        pip install "/tmp/project/[transformer]" && \
        python -m crawl4ai.model_loader; \
    fi

# Install Playwright browser
RUN playwright install --with-deps chromium

# Expose the port Render will use
EXPOSE ${PORT}

# Start the Crawl4AI server
CMD ["python", "-m", "crawl4ai.server", "--host", "0.0.0.0", "--port", "$PORT"]
