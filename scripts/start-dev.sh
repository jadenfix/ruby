#!/bin/bash

# GemHub Development Startup Script
# This script starts both the API server and frontend development server

set -e

echo "🚀 Starting GemHub Development Environment"
echo "=========================================="

# Function to check if a port is in use
check_port() {
    local port=$1
    if lsof -ti:$port > /dev/null 2>&1; then
        echo "⚠️  Port $port is already in use"
        return 0
    else
        return 1
    fi
}

# Function to start API server
start_api() {
    echo "📡 Starting API Server..."
    
    if check_port 4567; then
        echo "   API server already running on port 4567"
    else
        echo "   Starting simple API server..."
        cd services/api
        API_TOKEN=test-token ruby simple_server.rb > ../../logs/api.log 2>&1 &
        API_PID=$!
        echo $API_PID > ../../api.pid
        cd ../..
        
        # Wait for API to start
        sleep 3
        
        if curl -s http://localhost:4567/health > /dev/null; then
            echo "   ✅ API server started successfully on http://localhost:4567"
            echo "   🔑 API Token: test-token"
        else
            echo "   ❌ API server failed to start"
            exit 1
        fi
    fi
}

# Function to start frontend
start_frontend() {
    echo "🌐 Starting Frontend..."
    
    if check_port 3000; then
        echo "   Frontend already running on port 3000"
    else
        echo "   Installing frontend dependencies..."
        cd frontend
        npm install > ../logs/frontend-install.log 2>&1
        
        echo "   Starting React development server..."
        npm start > ../logs/frontend.log 2>&1 &
        FRONTEND_PID=$!
        echo $FRONTEND_PID > ../frontend.pid
        cd ..
        
        # Wait for frontend to start
        echo "   Waiting for frontend to start..."
        for i in {1..30}; do
            if curl -s http://localhost:3000 > /dev/null; then
                echo "   ✅ Frontend started successfully on http://localhost:3000"
                break
            fi
            sleep 2
            if [ $i -eq 30 ]; then
                echo "   ❌ Frontend failed to start within 60 seconds"
                exit 1
            fi
        done
    fi
}

# Function to test the connection
test_connection() {
    echo "🧪 Testing API Connection..."
    
    # Test health endpoint
    if curl -s http://localhost:4567/health | grep -q "healthy"; then
        echo "   ✅ Health check passed"
    else
        echo "   ❌ Health check failed"
        return 1
    fi
    
    # Test CORS
    if curl -s -X OPTIONS -H "Origin: http://localhost:3000" -H "Access-Control-Request-Method: GET" http://localhost:4567/gems -o /dev/null -w "%{http_code}" | grep -q "200"; then
        echo "   ✅ CORS preflight check passed"
    else
        echo "   ❌ CORS preflight check failed"
        return 1
    fi
    
    # Test authenticated endpoint
    if curl -s -H "Authorization: Bearer test-token" http://localhost:4567/gems | grep -q "gems"; then
        echo "   ✅ Authenticated API access works"
    else
        echo "   ❌ Authenticated API access failed"
        return 1
    fi
}

# Create logs directory
mkdir -p logs

# Start services
start_api
start_frontend

# Test everything works
if test_connection; then
    echo ""
    echo "🎉 GemHub Development Environment is ready!"
    echo ""
    echo "📍 Services:"
    echo "   • Frontend: http://localhost:3000"
    echo "   • API:      http://localhost:4567"
    echo "   • API Docs: http://localhost:4567/docs"
    echo ""
    echo "🔧 Commands:"
    echo "   • Stop all: ./scripts/stop-dev.sh"
    echo "   • View logs: tail -f logs/*.log"
    echo ""
    echo "Press Ctrl+C to stop all services"
    
    # Keep script running and handle cleanup
    cleanup() {
        echo ""
        echo "🛑 Stopping services..."
        if [ -f api.pid ]; then
            kill $(cat api.pid) 2>/dev/null || true
            rm api.pid
        fi
        if [ -f frontend.pid ]; then
            kill $(cat frontend.pid) 2>/dev/null || true
            rm frontend.pid
        fi
        echo "✅ All services stopped"
        exit 0
    }
    
    trap cleanup INT TERM
    
    # Wait indefinitely
    while true; do
        sleep 1
    done
else
    echo "❌ Development environment setup failed"
    exit 1
fi 