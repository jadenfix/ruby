#!/bin/bash
# GemHub Local Launch Script
# Starts all services locally without Docker

set -e

# Configuration
export RUBY_PATH="/opt/homebrew/opt/ruby/bin"
export API_TOKEN="test-token"
export DATABASE_URL="sqlite://gemhub.db"
export GEMHUB_API_URL="http://localhost:4567"
export GEMHUB_API_TOKEN="$API_TOKEN"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Current directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Help function
show_help() {
    cat << EOF
GemHub Local Launch Script

Usage: $0 [COMMAND] [OPTIONS]

COMMANDS:
    start       Start all services (default)
    stop        Stop all services
    restart     Restart all services
    status      Show status of all services
    test        Run end-to-end tests
    api         Start only the API server
    cli         Test CLI commands
    help        Show this help message

OPTIONS:
    --seed      Seed the database with sample data (for start/restart)
    --no-seed   Skip database seeding
    --port PORT Set API port (default: 4567)

EXAMPLES:
    $0 start --seed     # Start all services and seed database
    $0 test             # Run end-to-end tests
    $0 status           # Check status of services
    $0 stop             # Stop all running services

EOF
}

# Function to check if a port is in use
check_port() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null ; then
        return 0
    else
        return 1
    fi
}

# Function to wait for service to be ready
wait_for_service() {
    local url=$1
    local name=$2
    local max_attempts=30
    local attempt=1
    
    log_info "Waiting for $name to be ready..."
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s -f "$url" > /dev/null 2>&1; then
            log_success "$name is ready!"
            return 0
        fi
        
        echo -n "."
        sleep 1
        attempt=$((attempt + 1))
    done
    
    log_error "$name failed to start within $max_attempts seconds"
    return 1
}

# Function to check Ruby environment
check_ruby_env() {
    log_info "Checking Ruby environment..."
    
    if [ ! -f "$RUBY_PATH/ruby" ]; then
        log_error "Ruby not found at $RUBY_PATH"
        log_error "Please install Ruby via Homebrew: brew install ruby"
        return 1
    fi
    
    export PATH="$RUBY_PATH:$PATH"
    
    local ruby_version=$(ruby --version)
    log_success "Ruby environment: $ruby_version"
    
    # Check if bundler is available
    if ! command -v bundle &> /dev/null; then
        log_error "Bundler not found. Installing..."
        gem install bundler
    fi
    
    return 0
}

# Function to install dependencies
install_dependencies() {
    log_info "Installing dependencies..."
    
    # API dependencies
    log_info "Installing API dependencies..."
    cd "$PROJECT_ROOT/services/api"
    bundle check || bundle install
    
    # CLI dependencies
    log_info "Installing CLI dependencies..."
    cd "$PROJECT_ROOT/cli"
    bundle check || bundle install
    
    # Extension dependencies
    log_info "Installing extension dependencies..."
    cd "$PROJECT_ROOT/extension"
    if [ -f package.json ]; then
        npm install
    fi
    
    log_success "All dependencies installed"
}

# Function to seed database
seed_database() {
    log_info "Seeding database with sample data..."
    cd "$PROJECT_ROOT/services/api"
    export PATH="$RUBY_PATH:$PATH"
    bundle exec ruby seed.rb
    log_success "Database seeded successfully"
}

# Function to start API server
start_api() {
    local port=${1:-4567}
    
    log_info "Starting API server on port $port..."
    
    if check_port $port; then
        log_warning "Port $port is already in use"
        local pid=$(lsof -ti:$port)
        log_info "Process using port $port: $pid"
        return 1
    fi
    
    cd "$PROJECT_ROOT/services/api"
    export PATH="$RUBY_PATH:$PATH"
    export API_TOKEN="$API_TOKEN"
    export DATABASE_URL="$DATABASE_URL"
    
    # Start API server in background
    nohup bundle exec ruby app.rb > api.log 2>&1 &
    local api_pid=$!
    echo $api_pid > api.pid
    
    # Wait for API to be ready
    if wait_for_service "http://localhost:$port/health" "API server"; then
        log_success "API server started with PID $api_pid"
        log_info "API logs: $PROJECT_ROOT/services/api/api.log"
        return 0
    else
        log_error "Failed to start API server"
        return 1
    fi
}

# Function to stop services
stop_services() {
    log_info "Stopping services..."
    
    # Stop API server
    if [ -f "$PROJECT_ROOT/services/api/api.pid" ]; then
        local api_pid=$(cat "$PROJECT_ROOT/services/api/api.pid")
        if kill -0 $api_pid 2>/dev/null; then
            log_info "Stopping API server (PID: $api_pid)"
            kill $api_pid
            rm -f "$PROJECT_ROOT/services/api/api.pid"
            log_success "API server stopped"
        else
            log_warning "API server was not running"
            rm -f "$PROJECT_ROOT/services/api/api.pid"
        fi
    fi
    
    # Kill any remaining processes on port 4567
    if check_port 4567; then
        local pid=$(lsof -ti:4567)
        log_info "Killing process on port 4567: $pid"
        kill $pid 2>/dev/null || true
    fi
}

# Function to show service status
show_status() {
    log_info "Service Status:"
    echo ""
    
    # API Status
    if check_port 4567; then
        local pid=$(lsof -ti:4567)
        log_success "API Server: Running (PID: $pid, Port: 4567)"
        
        # Test API health
        if curl -s -f "http://localhost:4567/health" > /dev/null 2>&1; then
            log_success "  Health check: PASSED"
        else
            log_warning "  Health check: FAILED"
        fi
    else
        log_warning "API Server: Not running"
    fi
    
    # CLI Status
    cd "$PROJECT_ROOT/cli"
    export PATH="$RUBY_PATH:$PATH"
    if bundle exec ruby bin/gemhub help >/dev/null 2>&1; then
        log_success "CLI: Available"
    else
        log_warning "CLI: Not working"
    fi
    
    # Extension Status
    if [ -f "$PROJECT_ROOT/extension/dist/extension.js" ]; then
        log_success "Extension: Built"
    else
        log_warning "Extension: Not built"
    fi
    
    echo ""
}

# Function to test CLI
test_cli() {
    log_info "Testing CLI commands..."
    
    cd "$PROJECT_ROOT/cli"
    export PATH="$RUBY_PATH:$PATH"
    export GEMHUB_API_URL="$GEMHUB_API_URL"
    export GEMHUB_API_TOKEN="$GEMHUB_API_TOKEN"
    
    log_info "Running 'gemhub list'..."
    if bundle exec ruby bin/gemhub list; then
        log_success "CLI list command works"
    else
        log_error "CLI list command failed"
        return 1
    fi
    
    log_info "Running 'gemhub help'..."
    if bundle exec ruby bin/gemhub help >/dev/null; then
        log_success "CLI help command works"
    else
        log_error "CLI help command failed"
        return 1
    fi
}

# Function to run end-to-end tests
run_e2e_tests() {
    log_info "Running end-to-end tests..."
    
    # Check if API is running
    if ! check_port 4567; then
        log_error "API server is not running. Start it first with: $0 api"
        return 1
    fi
    
    # Run tests
    cd "$PROJECT_ROOT"
    export PATH="$RUBY_PATH:$PATH"
    
    if ruby test/e2e_test.rb; then
        log_success "All end-to-end tests passed!"
    else
        log_error "Some end-to-end tests failed"
        return 1
    fi
}

# Function to build extension
build_extension() {
    log_info "Building VS Code extension..."
    
    cd "$PROJECT_ROOT/extension"
    if npm run build; then
        log_success "Extension built successfully"
    else
        log_error "Extension build failed"
        return 1
    fi
}

# Main command processing
COMMAND=${1:-start}
SEED_DB=true
API_PORT=4567

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --seed)
            SEED_DB=true
            shift
            ;;
        --no-seed)
            SEED_DB=false
            shift
            ;;
        --port)
            API_PORT="$2"
            shift 2
            ;;
        -h|--help|help)
            show_help
            exit 0
            ;;
        start|stop|restart|status|test|api|cli)
            COMMAND="$1"
            shift
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# ASCII Art Banner
cat << 'EOF'
   ____                _   _       _     
  / ___| ___ _ __ ___ | | | |_   _| |__  
 | |  _ / _ \ '_ ` _ \| |_| | | | | '_ \ 
 | |_| |  __/ | | | | |  _  | |_| | |_) |
  \____|\___|_| |_| |_|_| |_|\__,_|_.__/ 
                                        
  Ruby Gem Marketplace & Development Platform
EOF

echo ""
log_info "GemHub Local Launch Script"
log_info "Project root: $PROJECT_ROOT"
echo ""

# Execute command
case $COMMAND in
    start)
        log_info "Starting GemHub platform..."
        check_ruby_env
        install_dependencies
        
        if [ "$SEED_DB" = true ]; then
            seed_database
        fi
        
        start_api $API_PORT
        build_extension
        
        echo ""
        log_success "🚀 GemHub platform started successfully!"
        log_info "📡 API Server: http://localhost:$API_PORT"
        log_info "🔑 API Token: $API_TOKEN"
        log_info "💎 CLI: gemhub (in cli/ directory)"
        log_info "🧩 Extension: built in extension/dist/"
        echo ""
        log_info "To test the platform:"
        log_info "  $0 test"
        log_info "  $0 cli"
        log_info "  $0 status"
        ;;
        
    stop)
        stop_services
        log_success "GemHub platform stopped"
        ;;
        
    restart)
        log_info "Restarting GemHub platform..."
        stop_services
        sleep 2
        
        check_ruby_env
        install_dependencies
        
        if [ "$SEED_DB" = true ]; then
            seed_database
        fi
        
        start_api $API_PORT
        build_extension
        
        log_success "🚀 GemHub platform restarted successfully!"
        ;;
        
    status)
        show_status
        ;;
        
    test)
        run_e2e_tests
        ;;
        
    api)
        check_ruby_env
        cd "$PROJECT_ROOT/services/api"
        bundle check || bundle install
        
        if [ "$SEED_DB" = true ]; then
            seed_database
        fi
        
        start_api $API_PORT
        ;;
        
    cli)
        test_cli
        ;;
        
    *)
        log_error "Unknown command: $COMMAND"
        show_help
        exit 1
        ;;
esac 