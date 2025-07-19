#!/usr/bin/env python3
"""
Simple Mock API Server for GemHub
Provides basic endpoints for frontend testing
"""

from fastapi import FastAPI
import uvicorn
import json

app = FastAPI(title="GemHub Mock API", version="1.0.0")

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
    },
    {
        "id": 3,
        "name": "devise",
        "version": "4.9.0",
        "description": "Flexible authentication solution for Rails",
        "homepage": "https://github.com/plataformatec/devise",
        "license": "MIT",
        "downloads": 200000000,
        "rating": 4.6,
        "created_at": "2023-01-01T00:00:00Z",
        "updated_at": "2023-10-01T00:00:00Z",
        "ratings_count": 12000,
        "badges_count": 4
    }
]

@app.get("/health")
def health_check():
    return {"status": "healthy", "timestamp": "2025-07-19T13:45:00Z"}

@app.get("/gems")
def get_gems():
    return {"gems": MOCK_GEMS}

@app.get("/gems/{gem_id}")
def get_gem(gem_id: int):
    gem = next((g for g in MOCK_GEMS if g["id"] == gem_id), None)
    if gem:
        return {"gem": gem}
    return {"error": "Gem not found"}, 404

@app.post("/gems")
def create_gem(gem_data: dict):
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
    return {"gem": new_gem}

@app.get("/badges")
def get_badges():
    return {
        "badges": [
            {"id": 1, "name": "Popular", "description": "High download count"},
            {"id": 2, "name": "Secure", "description": "No known vulnerabilities"},
            {"id": 3, "name": "Well-Tested", "description": "High test coverage"}
        ]
    }

if __name__ == "__main__":
    print("🚀 Starting GemHub Mock API on http://localhost:4567")
    uvicorn.run(app, host="0.0.0.0", port=4567)
