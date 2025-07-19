#!/bin/bash

# GemHub Sandbox Orchestrator
# Launches a Rails demo app with the target gem mounted

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
GEM_NAME=""
GEM_PATH=""
RAILS_VERSION="7.0"
PORT="3000"
DEMO_APP_NAME="gemhub-demo"

# Help function
show_help() {
    echo -e "${BLUE}GemHub Sandbox Orchestrator${NC}"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -g, --gem-name NAME     Name of the gem to test"
    echo "  -p, --gem-path PATH     Path to the gem source code"
    echo "  -r, --rails-version V   Rails version to use (default: 7.0)"
    echo "  -P, --port PORT         Port for the demo app (default: 3000)"
    echo "  -n, --name NAME         Demo app name (default: gemhub-demo)"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -g rails -p /path/to/rails"
    echo "  $0 --gem-name sinatra --gem-path ./sinatra --port 3001"
    echo ""
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -g|--gem-name)
            GEM_NAME="$2"
            shift 2
            ;;
        -p|--gem-path)
            GEM_PATH="$2"
            shift 2
            ;;
        -r|--rails-version)
            RAILS_VERSION="$2"
            shift 2
            ;;
        -P|--port)
            PORT="$2"
            shift 2
            ;;
        -n|--name)
            DEMO_APP_NAME="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

# Validate required arguments
if [[ -z "$GEM_NAME" ]]; then
    echo -e "${RED}Error: Gem name is required${NC}"
    show_help
    exit 1
fi

if [[ -z "$GEM_PATH" ]]; then
    echo -e "${YELLOW}Warning: No gem path provided, will use gem from RubyGems${NC}"
fi

# Create sandbox directory
SANDBOX_DIR="$(pwd)/sandbox_${DEMO_APP_NAME}"
mkdir -p "$SANDBOX_DIR"

echo -e "${BLUE}🚀 Launching GemHub Sandbox for: ${GREEN}$GEM_NAME${NC}"
echo -e "${BLUE}📍 Sandbox directory: ${GREEN}$SANDBOX_DIR${NC}"
echo -e "${BLUE}🌐 Demo app will be available at: ${GREEN}http://localhost:$PORT${NC}"

# Generate docker-compose.sandbox.yml
cat > "$SANDBOX_DIR/docker-compose.sandbox.yml" << EOF
version: '3.8'

services:
  rails-demo:
    image: ruby:3.1-slim
    container_name: ${DEMO_APP_NAME}
    working_dir: /app
    ports:
      - "${PORT}:3000"
    volumes:
      - ./demo_app:/app
      - ${GEM_PATH}:/gem_source:ro
    environment:
      - RAILS_ENV=development
      - GEM_NAME=${GEM_NAME}
    command: >
      bash -c "
        apt-get update && apt-get install -y nodejs npm sqlite3 libsqlite3-dev
        gem install rails -v ${RAILS_VERSION}
        rails new . --skip-git --skip-bundle --database=sqlite3
        echo 'gem \"${GEM_NAME}\", path: \"/gem_source\"' >> Gemfile
        bundle install
        rails generate controller Welcome index
        echo 'Rails.application.routes.draw do' > config/routes.rb
        echo '  root \"welcome#index\"' >> config/routes.rb
        echo 'end' >> config/routes.rb
        rails db:create
        rails server -b 0.0.0.0
      "
    networks:
      - gemhub-sandbox

networks:
  gemhub-sandbox:
    driver: bridge
EOF

# Generate teardown script
cat > "$SANDBOX_DIR/teardown.sh" << 'EOF'
#!/bin/bash
echo "🧹 Tearing down GemHub Sandbox..."
docker-compose -f docker-compose.sandbox.yml down
docker-compose -f docker-compose.sandbox.yml rm -f
echo "✅ Sandbox torn down successfully"
EOF

chmod +x "$SANDBOX_DIR/teardown.sh"

# Generate demo app files
mkdir -p "$SANDBOX_DIR/demo_app/app/controllers"
mkdir -p "$SANDBOX_DIR/demo_app/app/views/welcome"
mkdir -p "$SANDBOX_DIR/demo_app/app/views/layouts"

# Create a simple welcome controller
cat > "$SANDBOX_DIR/demo_app/app/controllers/welcome_controller.rb" << EOF
class WelcomeController < ApplicationController
  def index
    @gem_name = ENV['GEM_NAME'] || 'Unknown Gem'
    @gem_info = {
      name: @gem_name,
      version: Gem::Specification.find_by_name(@gem_name)&.version&.to_s || 'Unknown',
      description: Gem::Specification.find_by_name(@gem_name)&.description || 'No description available'
    }
  rescue LoadError, Gem::MissingSpecError
    @gem_info = {
      name: @gem_name,
      version: 'Not installed',
      description: 'Gem not found or not installed'
    }
  end
end
EOF

# Create a simple view
cat > "$SANDBOX_DIR/demo_app/app/views/welcome/index.html.erb" << EOF
<!DOCTYPE html>
<html>
<head>
  <title>GemHub Sandbox - <%= @gem_name %></title>
  <style>
    body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
    .container { max-width: 800px; margin: 0 auto; background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
    .header { text-align: center; margin-bottom: 30px; }
    .gem-info { background: #f8f9fa; padding: 20px; border-radius: 5px; margin: 20px 0; }
    .status { padding: 10px; border-radius: 5px; margin: 10px 0; }
    .success { background: #d4edda; color: #155724; border: 1px solid #c3e6cb; }
    .error { background: #f8d7da; color: #721c24; border: 1px solid #f5c6cb; }
    .warning { background: #fff3cd; color: #856404; border: 1px solid #ffeaa7; }
    .code { background: #f1f1f1; padding: 10px; border-radius: 3px; font-family: monospace; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>🚀 GemHub Sandbox</h1>
      <h2>Testing: <%= @gem_name %></h2>
    </div>
    
    <div class="gem-info">
      <h3>Gem Information</h3>
      <p><strong>Name:</strong> <%= @gem_info[:name] %></p>
      <p><strong>Version:</strong> <%= @gem_info[:version] %></p>
      <p><strong>Description:</strong> <%= @gem_info[:description] %></p>
    </div>
    
    <% if @gem_info[:version] != 'Not installed' %>
      <div class="status success">
        ✅ Gem successfully loaded and available for testing
      </div>
    <% else %>
      <div class="status error">
        ❌ Gem not found or not properly installed
      </div>
    <% end %>
    
    <div class="gem-info">
      <h3>Testing Instructions</h3>
      <p>This Rails demo app is running with the <strong><%= @gem_name %></strong> gem mounted.</p>
      <p>You can:</p>
      <ul>
        <li>Test the gem's functionality in this Rails environment</li>
        <li>Run benchmarks using the GemHub CLI</li>
        <li>Check for security vulnerabilities</li>
        <li>Explore the gem's features</li>
      </ul>
    </div>
    
    <div class="gem-info">
      <h3>Available Commands</h3>
      <div class="code">
        # Run benchmarks<br>
        bin/gemhub benchmark <%= @gem_name %><br><br>
        
        # Check for CVEs<br>
        bin/gemhub scan <%= @gem_name %><br><br>
        
        # View gem details<br>
        bin/gemhub info <%= @gem_name %>
      </div>
    </div>
  </div>
</body>
</html>
EOF

# Create a simple layout
cat > "$SANDBOX_DIR/demo_app/app/views/layouts/application.html.erb" << EOF
<!DOCTYPE html>
<html>
  <head>
    <title>GemHub Sandbox</title>
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>
    <%= stylesheet_link_tag "application", "data-turbo-track": "reload" %>
    <%= javascript_importmap_tags %>
  </head>
  <body>
    <%= yield %>
  </body>
</html>
EOF

echo -e "${GREEN}✅ Sandbox files generated successfully${NC}"

# Launch the sandbox
echo -e "${BLUE}🚀 Starting Rails demo app...${NC}"
cd "$SANDBOX_DIR"

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed or not available${NC}"
    echo -e "${YELLOW}Please install Docker and try again${NC}"
    exit 1
fi

# Check if Docker Compose is available
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}Error: Docker Compose is not installed or not available${NC}"
    echo -e "${YELLOW}Please install Docker Compose and try again${NC}"
    exit 1
fi

# Start the services
docker-compose -f docker-compose.sandbox.yml up -d

echo -e "${GREEN}✅ Rails demo app is starting up...${NC}"
echo -e "${BLUE}⏳ Please wait a moment for the app to be ready...${NC}"

# Wait for the app to be ready
echo -e "${BLUE}🔄 Waiting for Rails app to be ready...${NC}"
sleep 30

# Check if the app is responding
if curl -s http://localhost:$PORT > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Rails demo app is ready!${NC}"
    echo -e "${BLUE}🌐 Open your browser to: ${GREEN}http://localhost:$PORT${NC}"
    echo -e "${BLUE}📁 Sandbox directory: ${GREEN}$SANDBOX_DIR${NC}"
    echo -e "${BLUE}🛑 To stop the sandbox, run: ${GREEN}cd $SANDBOX_DIR && ./teardown.sh${NC}"
else
    echo -e "${YELLOW}⚠️  App might still be starting up...${NC}"
    echo -e "${BLUE}🌐 Try opening: ${GREEN}http://localhost:$PORT${NC}"
    echo -e "${BLUE}📁 Sandbox directory: ${GREEN}$SANDBOX_DIR${NC}"
fi

echo -e "${GREEN}🎉 GemHub Sandbox launched successfully!${NC}" 