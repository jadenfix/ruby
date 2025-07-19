# GemHub Development Guide

Welcome to GemHub - a Ruby Gem Marketplace and Development Platform! This guide will help you get the complete system running locally.

## Quick Start

### 1. Start Development Environment

```bash
./scripts/start-dev.sh
```

This single command will:
- Start the API server on `http://localhost:4567`
- Start the React frontend on `http://localhost:3000`
- Test all connections automatically
- Display status and useful links

### 2. Stop Development Environment

```bash
./scripts/stop-dev.sh
```

This will cleanly stop all services and free up ports.

## System Architecture

```
┌─────────────────────┐    HTTP/REST     ┌─────────────────────┐
│   React Frontend    │ ◄──────────────► │    Ruby API Server  │
│   (localhost:3000)  │                  │   (localhost:4567)  │
│                     │                  │                     │
│ • Dashboard         │                  │ • Gem Registry      │
│ • Marketplace       │                  │ • Authentication    │
│ • Create Gem        │                  │ • CORS Support      │
│ • Sandbox           │                  │ • Health Checks     │
│ • Benchmarks        │                  │                     │
└─────────────────────┘                  └─────────────────────┘
```

## Services Overview

### Frontend (React + TypeScript)
- **Location**: `frontend/`
- **Port**: 3000
- **Features**:
  - Modern React 18 with TypeScript
  - React Query for API state management
  - Tailwind CSS for styling
  - React Router for navigation
  - Real-time API status indicator

### API Server (Ruby)
- **Location**: `services/api/`
- **Port**: 4567
- **Features**:
  - Pure Ruby (no external dependencies)
  - RESTful JSON API
  - Bearer token authentication
  - CORS support for frontend
  - In-memory data store with sample gems

## API Endpoints

### Public Endpoints
- `GET /health` - Health check
- `GET /docs` - API documentation (coming soon)

### Authenticated Endpoints (require `Authorization: Bearer test-token`)
- `GET /gems` - List all gems
- `GET /gems/:id` - Get specific gem
- `POST /gems` - Create new gem
- `PUT /gems/:id` - Update gem
- `DELETE /gems/:id` - Delete gem
- `POST /scan` - CVE security scan (placeholder)

### Example API Usage

```bash
# Health check (no auth required)
curl http://localhost:4567/health

# Get all gems (requires auth)
curl -H "Authorization: Bearer test-token" http://localhost:4567/gems

# Create a new gem
curl -X POST \
  -H "Authorization: Bearer test-token" \
  -H "Content-Type: application/json" \
  -d '{"name": "my-gem", "version": "1.0.0", "description": "My awesome gem"}' \
  http://localhost:4567/gems
```

## Frontend Features

### Dashboard
- Overview of gems, downloads, ratings, and badges
- Statistics cards with real-time data
- Recent gems and trending items

### Marketplace
- Browse all available gems
- Search and filter functionality
- Detailed gem information cards
- Ratings and download counts

### Create Gem
- Interactive form to add new gems
- Validation and error handling
- Integration with API

### Sandbox
- One-click gem testing environment (planned)
- Docker-based isolated environment
- Rails demo app integration

### Benchmarks
- Performance comparison tools (planned)
- Benchmark results visualization
- Historical performance data

## Configuration

### Environment Variables
- `API_TOKEN` - Authentication token for API (default: `test-token`)
- `REACT_APP_API_URL` - API base URL (default: `http://localhost:4567`)
- `REACT_APP_API_TOKEN` - Frontend API token (default: `test-token`)

### Default Configuration
The system works out of the box with these defaults:
- API Token: `test-token`
- API URL: `http://localhost:4567`
- Frontend URL: `http://localhost:3000`

## Development Workflow

### Making Changes

1. **API Changes**: Edit files in `services/api/`
   - Main server: `simple_server.rb`
   - Restart: `./scripts/stop-dev.sh && ./scripts/start-dev.sh`

2. **Frontend Changes**: Edit files in `frontend/src/`
   - React hot-reloading is enabled
   - Changes appear automatically in browser

### Debugging

1. **View Logs**:
   ```bash
   tail -f logs/api.log      # API server logs
   tail -f logs/frontend.log # Frontend logs
   ```

2. **Check Service Status**:
   ```bash
   curl http://localhost:4567/health  # API health
   curl http://localhost:3000         # Frontend status
   ```

3. **Manual Testing**:
   - API: Use curl or Postman
   - Frontend: Open browser developer tools

## Sample Data

The API comes pre-loaded with 5 sample gems:
- **Sinatra** - Web development DSL
- **Rails** - Full-stack framework
- **Sequel** - Database toolkit
- **RSpec** - BDD testing framework
- **Puma** - Concurrent web server

Each gem includes:
- Name, version, description
- Homepage and license
- Download counts and ratings
- Badge counts and timestamps

## Troubleshooting

### Common Issues

1. **Port Already in Use**:
   ```bash
   ./scripts/stop-dev.sh  # Clean up all processes
   lsof -ti:3000 | xargs kill  # Manual cleanup if needed
   lsof -ti:4567 | xargs kill
   ```

2. **API Not Responding**:
   - Check logs: `tail -f logs/api.log`
   - Verify Ruby is working: `ruby --version`
   - Test manually: `cd services/api && ruby simple_server.rb`

3. **Frontend Build Errors**:
   - Clear cache: `cd frontend && rm -rf node_modules package-lock.json`
   - Reinstall: `npm install`
   - Check Node version: `node --version` (requires Node 16+)

4. **CORS Errors**:
   - API should automatically set CORS headers
   - Check browser console for specific errors
   - Verify API token matches frontend configuration

### Getting Help

1. Check this README for common solutions
2. Review logs in the `logs/` directory
3. Test individual components manually
4. Use browser developer tools for frontend issues

## Next Steps

This development setup provides a solid foundation for:

1. **Building Features**: Add new pages, components, and API endpoints
2. **Testing**: Add unit tests, integration tests, and E2E tests
3. **Deployment**: Package for production deployment
4. **Integration**: Connect with additional services (LLM, vector store, etc.)

## Production Deployment

For production deployment, consider:
- Using a production Ruby server (Puma, Unicorn)
- Setting up a proper database (PostgreSQL, MySQL)
- Implementing proper authentication and authorization
- Adding monitoring and logging
- Setting up CI/CD pipelines

---

**Happy coding!** 🚀

The GemHub platform is ready for development. Start building amazing features for the Ruby community! 