#!/bin/bash

# GemHub Development Stop Script
# This script stops both the API server and frontend development server

echo "🛑 Stopping GemHub Development Environment"
echo "===========================================" 

# Stop API server
if [ -f api.pid ]; then
    API_PID=$(cat api.pid)
    if kill -0 $API_PID 2>/dev/null; then
        echo "📡 Stopping API server (PID: $API_PID)..."
        kill $API_PID
        rm api.pid
        echo "   ✅ API server stopped"
    else
        echo "   ⚠️  API server was not running"
        rm api.pid
    fi
else
    echo "📡 No API server PID file found"
fi

# Stop frontend
if [ -f frontend.pid ]; then
    FRONTEND_PID=$(cat frontend.pid)
    if kill -0 $FRONTEND_PID 2>/dev/null; then
        echo "🌐 Stopping frontend server (PID: $FRONTEND_PID)..."
        kill $FRONTEND_PID
        rm frontend.pid
        echo "   ✅ Frontend server stopped"
    else
        echo "   ⚠️  Frontend server was not running"
        rm frontend.pid
    fi
else
    echo "🌐 No frontend server PID file found"
fi

# Kill any remaining processes on the ports
echo "🔍 Cleaning up any remaining processes..."

# Kill anything on port 4567 (API)
API_PROCESSES=$(lsof -ti:4567 2>/dev/null || true)
if [ ! -z "$API_PROCESSES" ]; then
    echo "   Killing remaining processes on port 4567..."
    echo "$API_PROCESSES" | xargs kill 2>/dev/null || true
fi

# Kill anything on port 3000 (Frontend)
FRONTEND_PROCESSES=$(lsof -ti:3000 2>/dev/null || true)
if [ ! -z "$FRONTEND_PROCESSES" ]; then
    echo "   Killing remaining processes on port 3000..."
    echo "$FRONTEND_PROCESSES" | xargs kill 2>/dev/null || true
fi

echo ""
echo "✅ All GemHub development services stopped"
echo "   You can now run ./scripts/start-dev.sh to restart" 