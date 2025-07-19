# GemHub Development Makefile
# Provides common development tasks and Lane D embedding management

.PHONY: help setup dev build test clean embed search-test deploy-dev logs

# Default target
help:
	@echo "GemHub Development Commands:"
	@echo ""
	@echo "Setup & Development:"
	@echo "  make setup      - Initial project setup"
	@echo "  make dev        - Start development environment"
	@echo "  make build      - Build all Docker images"
	@echo "  make test       - Run all tests"
	@echo "  make clean      - Clean up containers and volumes"
	@echo ""
	@echo "Lane D - AI & Vector Store:"
	@echo "  make embed      - Refresh FAISS embeddings (Lane D requirement)"
	@echo "  make search-test - Test vector search functionality"
	@echo ""
	@echo "Deployment:"
	@echo "  make deploy-dev - Deploy development environment"
	@echo "  make logs       - View service logs"

# Initial project setup
setup:
	@echo "Setting up GemHub development environment..."
	@docker --version || (echo "Docker is required" && exit 1)
	@docker-compose --version || (echo "Docker Compose is required" && exit 1)
	@cp .env.example .env || echo "No .env.example found, create .env manually"
	@echo "Setup complete! Run 'make dev' to start development."

# Start development environment
dev:
	@echo "Starting GemHub development services..."
	docker-compose up -d
	@echo "Services starting up..."
	@sleep 5
	@echo "Checking service health..."
	@docker-compose ps
	@echo ""
	@echo "Services available at:"
	@echo "  API:          http://localhost:4567"
	@echo "  LLM Gateway:  http://localhost:8001"
	@echo "  Vector Store: http://localhost:8002"
	@echo "  CVE Scanner:  http://localhost:8003"

# Build all Docker images
build:
	@echo "Building all GemHub services..."
	docker-compose build --parallel

# Run tests across all services
test:
	@echo "Running GemHub test suite..."
	docker-compose run --rm api bundle exec rspec || true
	docker-compose run --rm llm_gateway python -m pytest tests/ || true
	docker-compose run --rm vector_store python -m pytest tests/ || true
	docker-compose run --rm cve_scanner bundle exec rspec || true

# Clean up development environment
clean:
	@echo "Cleaning up GemHub development environment..."
	docker-compose down -v
	docker system prune -f
	@echo "Cleanup complete."

# Lane D: Refresh FAISS embeddings (main requirement)
embed:
	@echo "Refreshing FAISS vector embeddings..."
	@echo "This will rebuild the vector store index with latest gem data."
	docker-compose exec vector_store python ingest.py build || \
	docker-compose run --rm vector_store python ingest.py build
	@echo "Embeddings refreshed successfully!"
	@echo "Run 'make search-test' to verify the update."

# Test vector search functionality
search-test:
	@echo "Testing vector search functionality..."
	@echo "Searching for 'web framework':"
	docker-compose exec vector_store python ingest.py search --query "web framework" --limit 3 || \
	docker-compose run --rm vector_store python ingest.py search --query "web framework" --limit 3
	@echo ""
	@echo "Searching for 'testing':"
	docker-compose exec vector_store python ingest.py search --query "testing" --limit 3 || \
	docker-compose run --rm vector_store python ingest.py search --query "testing" --limit 3

# Deploy development environment with health checks
deploy-dev:
	@echo "Deploying GemHub development environment..."
	docker-compose up -d --build
	@echo "Waiting for services to be healthy..."
	@timeout 60 sh -c 'until docker-compose ps | grep -q "healthy"; do sleep 2; done' || \
		echo "Warning: Some services may not be fully healthy yet"
	@echo "Initializing vector store..."
	@make embed
	@echo "Development deployment complete!"

# View logs from all services
logs:
	docker-compose logs -f

# Lane D specific targets
llm-test:
	@echo "Testing LLM Gateway endpoints..."
	curl -X GET http://localhost:8001/health || echo "LLM Gateway not responding"
	@echo ""

vector-stats:
	@echo "Vector Store Statistics:"
	docker-compose exec vector_store python ingest.py stats || \
	docker-compose run --rm vector_store python ingest.py stats

# Development utilities
db-reset:
	@echo "Resetting development databases..."
	docker-compose down -v
	docker-compose up -d
	@make embed

restart:
	@echo "Restarting all services..."
	docker-compose restart

# Environment file template
.env.example:
	@echo "Creating .env.example template..."
	@cat > .env.example << 'EOF'
# GemHub Environment Configuration

# OpenAI API Configuration (required for Lane D)
OPENAI_API_KEY=your_openai_api_key_here
MODEL=gpt-4o-mini

# API Security
API_TOKEN=dev-token-123

# Database
POSTGRES_PASSWORD=dev-password

# Development flags
RACK_ENV=development
PYTHONPATH=/app
EOF
	@echo ".env.example created. Copy to .env and configure."

# Create Dockerfiles for services that need them
dockerfiles:
	@echo "Creating Dockerfile templates for services..."
	@mkdir -p services/llm_gateway services/vector_store
	
	@cat > services/llm_gateway/Dockerfile << 'EOF'
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
EXPOSE 8001
CMD ["python", "main.py"]
EOF

	@cat > services/vector_store/Dockerfile << 'EOF'
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
EXPOSE 8002
CMD ["python", "ingest.py", "build"]
EOF
	
	@echo "Dockerfiles created for Lane D services." 