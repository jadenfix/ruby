# GemHub Vector Store Service - Lane D
# FAISS-based semantic search with sentence transformers
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install system dependencies for FAISS and ML libraries
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first for better caching
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Create necessary directories
RUN mkdir -p /app/data /app/models /app/vector_store

# Set environment variables
ENV PYTHONPATH=/app
ENV PYTHONUNBUFFERED=1
ENV VECTOR_STORE_PATH=/app/data

# Expose port (if running as HTTP service)
EXPOSE 8002

# Health check - verify FAISS is working
HEALTHCHECK --interval=60s --timeout=30s --start-period=30s --retries=3 \
    CMD python -c "import faiss; print('FAISS OK')" || exit 1

# Default command - build index
CMD ["python", "ingest.py", "build"] 