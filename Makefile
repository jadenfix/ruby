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

# Start development environment
dev:
	@echo "Starting GemHub development services..."
	docker-compose up -d
	@echo "Services available at:"
	@echo "  API:          http://localhost:4567"
	@echo "  LLM Gateway:  http://localhost:8001"
	@echo "  Vector Store: http://localhost:8002"

# Lane D: Refresh FAISS embeddings (main requirement)
embed:
	@echo "Refreshing FAISS vector embeddings..."
	docker-compose exec vector_store python ingest.py build || \
	docker-compose run --rm vector_store python ingest.py build
	@echo "Embeddings refreshed successfully!"

# Test vector search functionality
search-test:
	@echo "Testing vector search functionality..."
	docker-compose exec vector_store python ingest.py search --query "web framework" --limit 3 || \
	docker-compose run --rm vector_store python ingest.py search --query "web framework" --limit 3

# Build all Docker images
build:
	@echo "Building all GemHub services..."
	docker-compose build --parallel

# Clean up development environment
clean:
	@echo "Cleaning up GemHub development environment..."
	docker-compose down -v
	docker system prune -f
	@echo "Cleanup complete." 