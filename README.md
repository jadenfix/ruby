# GemHub

A lean-but-impressive gem discovery platform that layers on top of Continue.dev. GemHub provides AI-powered gem recommendations, semantic search, sandbox environments, and quality analytics for Ruby developers.

## Architecture Overview

GemHub is built as a microservices architecture with the following components:

### Lane A - Developer-Facing UX
- **VS Code Extension**: Continue.dev integration with sidebar panels
- **CLI Tools**: Thor-based command line interface
- **Frontend**: React + TypeScript panels for marketplace, sandbox, benchmarks

### Lane B - Core API & Registry  
- **Sinatra API**: Lightweight Ruby API with SQLite storage
- **Gem Registry**: CRUD operations for gem metadata
- **Rating System**: Community-driven gem ratings and badges

### Lane C - Sandbox & Quality Gates
- **Sandbox Orchestrator**: One-click Rails demo environments
- **Benchmark Runner**: Performance testing with benchmark-ips
- **CVE Scanner**: Security vulnerability detection via RubySec

### Lane D - AI Layer & Observability ⭐ (Current Focus)
- **LLM Gateway**: FastAPI service with OpenAI integration
- **Vector Store**: FAISS-based semantic search for gem discovery
- **Metrics Dashboard**: D3.js visualizations of performance data

## Lane D Components (AI & Vector Search)

### LLM Gateway (`services/llm_gateway/`)

FastAPI service providing AI-powered gem ranking and suggestions:

- **`/rank`**: Rank gems by relevance to search queries
- **`/suggest`**: Get contextual gem recommendations  
- **`/health`**: Service health monitoring

**Features:**
- OpenAI GPT-4o-mini integration
- Rate limiting via SlowAPI
- Async processing for performance
- Fallback responses when AI unavailable

### Vector Store (`services/vector_store/`)

FAISS-based semantic search engine:

- **Embedding Generation**: Uses sentence-transformers for gem documentation
- **Similarity Search**: Fast vector search with cosine similarity
- **Metadata Storage**: SQLite database for gem information
- **Index Management**: Persistent FAISS index with refresh capabilities

**Key Features:**
- Semantic search across gem names, descriptions, and READMEs
- Support for 5-second similarity searches across 100+ gems
- Automatic embedding generation from gem documentation
- CLI tools for index management and testing

## Quick Start

### Prerequisites

- Docker & Docker Compose
- OpenAI API key (for AI features)
- Git

### Setup

1. **Clone and Setup**
   ```bash
   git clone https://github.com/jadenfix/ruby && cd gemhub
   make setup
   ```

2. **Configure Environment**
   ```bash
   cp .env.example .env
   # Edit .env with your OpenAI API key
   ```

3. **Start Development Environment**
   ```bash
   make dev
   ```

4. **Initialize Vector Search (Lane D)**
   ```bash
   make embed
   ```

### Verify Installation

The following services will be available:

- **API Server**: http://localhost:4567
- **LLM Gateway**: http://localhost:8001  
- **Vector Store**: http://localhost:8002
- **CVE Scanner**: http://localhost:8003

Test the AI components:
```bash
# Test LLM Gateway
curl http://localhost:8001/health

# Test vector search
make search-test
```

## Development Workflow

### Lane D Development

For AI and vector search development:

```bash
# Refresh embeddings after adding new gems
make embed

# Test search functionality
make search-test

# View vector store statistics
make vector-stats

# Test LLM endpoints
make llm-test
```

### Available Commands

```bash
make help           # Show all available commands
make dev            # Start development environment  
make build          # Build all Docker images
make test           # Run test suite
make clean          # Clean up containers and volumes
make embed          # Refresh FAISS embeddings ⭐
make deploy-dev     # Full deployment with health checks
make logs           # View service logs
```

## API Examples

### LLM Gateway - Rank Gems

```bash
curl -X POST http://localhost:8001/rank \
  -H "Content-Type: application/json" \
  -d '{
    "query": "web framework for API development",
    "gems": [
      {
        "name": "rails",
        "description": "Full-stack web framework",
        "keywords": ["web", "framework", "mvc"],
        "stars": 55000
      },
      {
        "name": "sinatra", 
        "description": "Lightweight web framework",
        "keywords": ["web", "micro", "api"],
        "stars": 12000
      }
    ],
    "max_results": 5
  }'
```

### LLM Gateway - Get Suggestions

```bash
curl -X POST http://localhost:8001/suggest \
  -H "Content-Type: application/json" \
  -d '{
    "context": "Building a REST API for a mobile app with user authentication",
    "current_gems": ["sinatra", "json"],
    "max_suggestions": 3
  }'
```

### Vector Store - Semantic Search

```bash
# Using the CLI
docker-compose exec vector_store python ingest.py search \
  --query "authentication library" --limit 5

# Results show semantic matches even without exact keywords
```

## Testing

### Unit Tests

```bash
# Test all services
make test

# Test specific service
docker-compose run --rm llm_gateway python -m pytest
docker-compose run --rm vector_store python -m pytest
```

### Integration Tests

```bash
# End-to-end workflow test
make deploy-dev
make search-test
make llm-test
```

## Environment Configuration

Create `.env` file with the following variables:

```bash
# Required for Lane D AI features
OPENAI_API_KEY=your_openai_api_key_here
MODEL=gpt-4o-mini

# API security
API_TOKEN=dev-token-123

# Database
POSTGRES_PASSWORD=dev-password

# Development
RACK_ENV=development
PYTHONPATH=/app
```

## Project Structure

```
gemhub/
├── services/
│   ├── api/                 # Lane B - Sinatra API
│   ├── llm_gateway/         # Lane D - FastAPI + OpenAI ⭐
│   ├── vector_store/        # Lane D - FAISS search ⭐
│   ├── sandbox_orch/        # Lane C - Docker orchestration
│   └── cve_scanner/         # Lane C - Security scanning
├── extension/               # Lane A - VS Code extension
├── cli/                     # Lane A - Thor CLI
├── docker-compose.yml       # Service orchestration
├── Makefile                 # Development automation ⭐
├── highlevel.md            # Architecture documentation
└── main.md                 # Lane specifications
```

## Lane D Definition of Done Checklist

- [x] LLM Gateway (`services/llm_gateway`) - FastAPI app with `/rank`, `/suggest` routes
- [x] Vector Store - FAISS index builds in <30s for 100 docs  
- [x] Docker Compose integration - llm_gateway & vector_store services
- [x] Makefile target `make embed` to refresh FAISS ⭐
- [ ] Charts render in sidebar with real data (pending Lane A integration)
- [ ] Gateway unit tests mock OpenAI and fully pass
- [x] Rate limiting via SlowAPI implemented
- [x] OpenAI 1.x client integration

## Contributing

1. **Branch Naming**: Use `lane-d/*` for Lane D features
2. **Testing**: Ensure all tests pass before commits
3. **Documentation**: Update README for new features
4. **Docker**: Test all services work in containers

## License

MIT License - see LICENSE file for details.

## Support

For issues or questions:
- Create GitHub issues for bugs
- Check service logs: `make logs`
- Verify environment: `make health` 