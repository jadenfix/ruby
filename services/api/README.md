# GemHub API Service

Core API & Registry service for GemHub platform built with Sinatra 3, Sequel ORM, and SQLite.

## Features

- **Gem Registry**: Full CRUD operations for Ruby gems
- **Rating System**: User ratings and reviews for gems
- **Badge System**: Achievement badges for gems (security, performance, quality, etc.)
- **CVE Scanner Integration**: Security vulnerability scanning (placeholder for Lane C)
- **Authentication**: Simple token-based authentication
- **Health Checks**: Built-in health monitoring
- **Comprehensive Testing**: Full test suite with RSpec

## Quick Start

### Prerequisites
- Ruby 3.3+
- Docker (optional)

### Local Development

1. **Install dependencies**:
   ```bash
   cd services/api
   bundle install
   ```

2. **Set environment variables**:
   ```bash
   export API_TOKEN=your-secret-token
   export DATABASE_URL=sqlite:///gemhub.db
   ```

3. **Run the application**:
   ```bash
   bundle exec ruby app.rb
   ```

4. **Seed the database** (optional):
   ```bash
   bundle exec ruby seed.rb
   ```

### Docker Development

1. **Build and run with Docker Compose**:
   ```bash
   docker compose up api
   ```

2. **Or build the API service only**:
   ```bash
   cd services/api
   docker build -t gemhub-api .
   docker run -p 4567:4567 -e API_TOKEN=your-token gemhub-api
   ```

## API Endpoints

### Authentication
All endpoints (except `/health` and `/docs`) require authentication:
```
Authorization: Bearer your-api-token
```

### Health Check
```
GET /health
```
Returns service health status.

### Gems

#### List all gems
```
GET /gems
```

#### Create a gem
```
POST /gems
Content-Type: application/json

{
  "name": "my-gem",
  "version": "1.0.0",
  "description": "A great gem",
  "homepage": "https://example.com",
  "license": "MIT"
}
```

#### Get a specific gem
```
GET /gems/:id
```

#### Update a gem
```
PUT /gems/:id
Content-Type: application/json

{
  "description": "Updated description"
}
```

#### Delete a gem
```
DELETE /gems/:id
```

### Ratings

#### Get ratings for a gem
```
GET /gems/:id/ratings
```

#### Add a rating to a gem
```
POST /gems/:id/ratings
Content-Type: application/json

{
  "score": 5,
  "comment": "Excellent gem!",
  "user_id": "user123"
}
```

### Badges

#### List all badges
```
GET /badges
```

#### Create a badge
```
POST /badges
Content-Type: application/json

{
  "gem_id": 1,
  "type": "quality",
  "name": "Well-Tested",
  "description": "Comprehensive test coverage"
}
```

### CVE Scanner (Placeholder)

#### Trigger security scan
```
POST /scan
Content-Type: application/json

{
  "gem_name": "my-gem"
}
```

## Testing

### Run all tests
```bash
cd services/api
bundle exec rspec
```

### Run specific test file
```bash
bundle exec rspec spec/api_spec.rb
```

### Test coverage
The test suite covers:
- ✅ All CRUD operations
- ✅ Authentication
- ✅ Validation
- ✅ Error handling
- ✅ Model associations
- ✅ Database operations

## Database Schema

### Gems Table
- `id` (Primary Key)
- `name` (Unique, required)
- `version` (Required)
- `description`
- `homepage`
- `license`
- `downloads` (Default: 0)
- `rating` (Default: 0.0)
- `created_at`
- `updated_at`

### Ratings Table
- `id` (Primary Key)
- `gem_id` (Foreign Key)
- `score` (1-5, required)
- `comment`
- `user_id` (Required)
- `created_at`

### Badges Table
- `id` (Primary Key)
- `gem_id` (Foreign Key)
- `type` (Required: security, performance, quality, popularity, maintenance)
- `name` (Required)
- `description`
- `created_at`

## Development

### Adding new endpoints
1. Add route to `app.rb`
2. Add corresponding test to `spec/api_spec.rb`
3. Update API documentation in `/docs` endpoint

### Database migrations
The application automatically creates tables on startup. For production, consider using proper migrations.

### Environment Variables
- `API_TOKEN`: Authentication token (required)
- `DATABASE_URL`: Database connection string (default: SQLite)
- `RACK_ENV`: Environment (development/production)

## Definition of Done ✅

- [x] `docker compose up api` responds to `GET /gems` with 200 OK
- [x] Full CRUD + validation tests green in CI
- [x] Seed script loads ≥3 sample gems
- [x] API docs auto-generated via `/docs` endpoint
- [x] Health check endpoint working
- [x] Authentication implemented
- [x] All models with validations
- [x] Comprehensive test suite
- [x] Docker containerization
- [x] CVE scanner endpoint (placeholder)

## Integration with Other Lanes

- **Lane A**: Frontend will consume these API endpoints
- **Lane C**: CVE scanner will integrate with `/scan` endpoint
- **Lane D**: LLM gateway may consume gem data for AI features 