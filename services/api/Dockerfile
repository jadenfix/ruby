FROM ruby:3.3-slim

# Install system dependencies
RUN apt-get update -qq && apt-get install -y \
    build-essential \
    sqlite3 \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy Gemfile and install dependencies
COPY Gemfile Gemfile.lock* ./
RUN bundle install --jobs 4 --retry 3

# Copy application code
COPY . .

# Create database directory
RUN mkdir -p /app/db

# Expose port
EXPOSE 4567

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:4567/health || exit 1

# Set environment variables
ENV RACK_ENV=production
ENV DATABASE_URL=sqlite:///app/db/gemhub.db

# Run the application
CMD ["bundle", "exec", "ruby", "app.rb"] 