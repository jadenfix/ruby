#!/usr/bin/env python3
"""
Simple HTTP API Server for GemHub
Uses built-in Python HTTP server
"""

from http.server import HTTPServer, BaseHTTPRequestHandler
import json
import urllib.parse as urlparse

# Mock data
MOCK_GEMS = [
    {
        "id": 1,
        "name": "rails",
        "version": "7.0.4",
        "description": "Full-stack web application framework",
        "homepage": "https://rubyonrails.org",
        "license": "MIT",
        "downloads": 500000000,
        "rating": 4.8,
        "created_at": "2023-01-01T00:00:00Z",
        "updated_at": "2023-12-01T00:00:00Z",
        "ratings_count": 15000,
        "badges_count": 3
    },
    {
        "id": 2,
        "name": "sinatra",
        "version": "3.0.0",
        "description": "Lightweight web application DSL",
        "homepage": "https://sinatrarb.com",
        "license": "MIT",
        "downloads": 100000000,
        "rating": 4.5,
        "created_at": "2023-01-01T00:00:00Z",
        "updated_at": "2023-11-01T00:00:00Z",
        "ratings_count": 8000,
        "badges_count": 2
    }
]

class APIHandler(BaseHTTPRequestHandler):
    def _send_response(self, status_code, data):
        self.send_response(status_code)
        self.send_header('Content-type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization')
        self.end_headers()
        self.wfile.write(json.dumps(data).encode())

    def do_GET(self):
        path = urlparse.urlparse(self.path).path
        
        if path == '/health':
            self._send_response(200, {"status": "healthy", "timestamp": "2025-07-19T13:45:00Z"})
        elif path == '/gems':
            self._send_response(200, {"gems": MOCK_GEMS})
        elif path.startswith('/gems/'):
            try:
                gem_id = int(path.split('/')[-1])
                gem = next((g for g in MOCK_GEMS if g["id"] == gem_id), None)
                if gem:
                    self._send_response(200, {"gem": gem})
                else:
                    self._send_response(404, {"error": "Gem not found"})
            except ValueError:
                self._send_response(400, {"error": "Invalid gem ID"})
        else:
            self._send_response(404, {"error": "Not found"})

    def do_POST(self):
        if self.path == '/gems':
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)
            try:
                gem_data = json.loads(post_data.decode('utf-8'))
                new_gem = {
                    "id": len(MOCK_GEMS) + 1,
                    "name": gem_data.get("name", "unknown"),
                    "version": gem_data.get("version", "1.0.0"),
                    "description": gem_data.get("description", ""),
                    "homepage": gem_data.get("homepage", ""),
                    "license": gem_data.get("license", "MIT"),
                    "downloads": 0,
                    "rating": 0.0,
                    "created_at": "2025-07-19T13:45:00Z",
                    "updated_at": "2025-07-19T13:45:00Z",
                    "ratings_count": 0,
                    "badges_count": 0
                }
                MOCK_GEMS.append(new_gem)
                self._send_response(201, {"gem": new_gem})
            except json.JSONDecodeError:
                self._send_response(400, {"error": "Invalid JSON"})
        else:
            self._send_response(404, {"error": "Not found"})

    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization')
        self.end_headers()

    def log_message(self, format, *args):
        # Suppress default logging
        pass

if __name__ == "__main__":
    server_address = ('', 4567)
    httpd = HTTPServer(server_address, APIHandler)
    print("🚀 GemHub Mock API running on http://localhost:4567")
    print("✅ Endpoints: /health, /gems, /gems/{id}")
    httpd.serve_forever()
