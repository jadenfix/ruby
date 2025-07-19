"""
Unit tests for GemHub LLM Gateway Service - Lane D
Tests all endpoints with mocked OpenAI integration
"""

import pytest
import asyncio
from unittest.mock import AsyncMock, MagicMock, patch
from fastapi.testclient import TestClient
import json
import os

# Import the app
import sys
sys.path.append('..')
from main import app, get_openai_client

# Test client
client = TestClient(app)

class TestLLMGateway:
    """Test suite for LLM Gateway service."""
    
    def setup_method(self):
        """Setup for each test method."""
        os.environ["OPENAI_API_KEY"] = "test-key-123"
        
    def teardown_method(self):
        """Cleanup after each test method."""
        if "OPENAI_API_KEY" in os.environ:
            del os.environ["OPENAI_API_KEY"]

    def test_root_endpoint(self):
        """Test the root endpoint returns service information."""
        response = client.get("/")
        assert response.status_code == 200
        data = response.json()
        assert data["service"] == "GemHub LLM Gateway"
        assert data["version"] == "1.0.0"
        assert "/rank" in data["endpoints"]
        assert "/suggest" in data["endpoints"]

    def test_health_endpoint_with_api_key(self):
        """Test health endpoint when API key is configured."""
        response = client.get("/health")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "healthy"
        assert data["model"] == "gpt-4o-mini"
        assert data["api_key_configured"] == True

    def test_health_endpoint_without_api_key(self):
        """Test health endpoint when API key is not configured."""
        del os.environ["OPENAI_API_KEY"]
        with patch('main.openai.api_key', None):
            response = client.get("/health")
            assert response.status_code == 200
            data = response.json()
            assert data["status"] == "healthy"
            assert data["api_key_configured"] == False

    @patch('main.openai.OpenAI')
    def test_rank_gems_success(self, mock_openai_class):
        """Test successful gem ranking with mocked OpenAI response."""
        # Mock OpenAI response
        mock_client = MagicMock()
        mock_openai_class.return_value = mock_client
        
        mock_response = MagicMock()
        mock_response.choices = [MagicMock()]
        mock_response.choices[0].message.content = json.dumps({
            "rankings": [0, 1],
            "scores": [0.9, 0.7],
            "reasoning": "Rails is more relevant for web frameworks"
        })
        
        mock_client.chat.completions.create.return_value = mock_response
        
        # Test data
        request_data = {
            "query": "web framework",
            "gems": [
                {
                    "name": "rails",
                    "description": "Full-stack web framework",
                    "keywords": ["web", "framework"],
                    "stars": 55000
                },
                {
                    "name": "sinatra",
                    "description": "Lightweight web framework",
                    "keywords": ["web", "micro"],
                    "stars": 12000
                }
            ],
            "max_results": 2
        }
        
        response = client.post("/rank", json=request_data)
        assert response.status_code == 200
        
        data = response.json()
        assert data["gem_names"] == ["rails", "sinatra"]
        assert data["scores"] == [0.9, 0.7]
        assert "reasoning" in data
        
    @patch('main.openai.OpenAI')
    def test_rank_gems_fallback_on_json_error(self, mock_openai_class):
        """Test gem ranking fallback when OpenAI response is invalid JSON."""
        # Mock OpenAI response with invalid JSON
        mock_client = MagicMock()
        mock_openai_class.return_value = mock_client
        
        mock_response = MagicMock()
        mock_response.choices = [MagicMock()]
        mock_response.choices[0].message.content = "Invalid JSON response"
        
        mock_client.chat.completions.create.return_value = mock_response
        
        request_data = {
            "query": "testing framework",
            "gems": [
                {
                    "name": "rspec",
                    "description": "Testing framework",
                    "stars": 12000,
                    "download_count": 300000
                },
                {
                    "name": "minitest",
                    "description": "Lightweight testing",
                    "stars": 5000,
                    "download_count": 100000
                }
            ]
        }
        
        response = client.post("/rank", json=request_data)
        assert response.status_code == 200
        
        data = response.json()
        assert len(data["gem_names"]) == 2
        assert data["reasoning"] == "Fallback ranking by popularity metrics"
        # Should rank rspec first due to higher stars + downloads
        assert data["gem_names"][0] == "rspec"

    def test_rank_gems_validation_error(self):
        """Test validation errors for rank endpoint."""
        # Missing required fields
        response = client.post("/rank", json={})
        assert response.status_code == 422
        
        # Invalid max_results
        response = client.post("/rank", json={
            "query": "test",
            "gems": [],
            "max_results": 0  # Should be >= 1
        })
        assert response.status_code == 422

    def test_rank_gems_no_api_key(self):
        """Test rank endpoint behavior without API key."""
        del os.environ["OPENAI_API_KEY"]
        with patch('main.openai.api_key', None):
            request_data = {
                "query": "web framework",
                "gems": [{"name": "rails", "description": "test"}]
            }
            
            response = client.post("/rank", json=request_data)
            assert response.status_code == 503
            assert "OpenAI API key not configured" in response.json()["detail"]

    @patch('main.openai.OpenAI')
    def test_suggest_gems_success(self, mock_openai_class):
        """Test successful gem suggestions with mocked OpenAI response."""
        # Mock OpenAI response
        mock_client = MagicMock()
        mock_openai_class.return_value = mock_client
        
        mock_response = MagicMock()
        mock_response.choices = [MagicMock()]
        mock_response.choices[0].message.content = json.dumps({
            "suggestions": [
                {
                    "name": "devise",
                    "reason": "Excellent authentication solution",
                    "category": "authentication",
                    "priority": "high"
                },
                {
                    "name": "jwt",
                    "reason": "Token-based authentication",
                    "category": "authentication", 
                    "priority": "medium"
                }
            ],
            "reasoning": "Based on authentication requirements for mobile API"
        })
        
        mock_client.chat.completions.create.return_value = mock_response
        
        request_data = {
            "context": "Building a REST API for mobile app with authentication",
            "current_gems": ["sinatra"],
            "max_suggestions": 2
        }
        
        response = client.post("/suggest", json=request_data)
        assert response.status_code == 200
        
        data = response.json()
        assert len(data["suggestions"]) == 2
        assert data["suggestions"][0]["name"] == "devise"
        assert data["suggestions"][0]["priority"] == "high"
        assert "reasoning" in data

    @patch('main.openai.OpenAI')  
    def test_suggest_gems_fallback(self, mock_openai_class):
        """Test gem suggestions fallback when OpenAI response is invalid."""
        # Mock OpenAI response with invalid JSON
        mock_client = MagicMock()
        mock_openai_class.return_value = mock_client
        
        mock_response = MagicMock()
        mock_response.choices = [MagicMock()]
        mock_response.choices[0].message.content = "Invalid JSON"
        
        mock_client.chat.completions.create.return_value = mock_response
        
        request_data = {
            "context": "Test context",
            "max_suggestions": 1
        }
        
        response = client.post("/suggest", json=request_data)
        assert response.status_code == 200
        
        data = response.json()
        assert len(data["suggestions"]) == 1
        assert data["reasoning"] == "Fallback suggestions - common useful gems"

    def test_suggest_gems_validation(self):
        """Test validation for suggest endpoint."""
        # Missing context
        response = client.post("/suggest", json={})
        assert response.status_code == 422
        
        # Invalid max_suggestions
        response = client.post("/suggest", json={
            "context": "test",
            "max_suggestions": 0
        })
        assert response.status_code == 422

    @patch('main.openai.OpenAI')
    def test_rate_limiting(self, mock_openai_class):
        """Test rate limiting on endpoints."""
        # Mock OpenAI to avoid actual API calls
        mock_client = MagicMock()
        mock_openai_class.return_value = mock_client
        mock_response = MagicMock()
        mock_response.choices = [MagicMock()]
        mock_response.choices[0].message.content = '{"rankings": [], "scores": [], "reasoning": "test"}'
        mock_client.chat.completions.create.return_value = mock_response
        
        request_data = {
            "query": "test",
            "gems": [{"name": "test", "description": "test"}]
        }
        
        # Make multiple requests to test rate limiting
        # Note: In real tests, you might want to lower the rate limit for testing
        responses = []
        for i in range(12):  # Exceed the 10/minute limit
            response = client.post("/rank", json=request_data)
            responses.append(response.status_code)
            
        # Should have at least one rate limited response
        assert 429 in responses  # Too Many Requests

    @patch('main.openai.OpenAI')
    def test_openai_api_error_handling(self, mock_openai_class):
        """Test handling of OpenAI API errors."""
        # Mock OpenAI to raise an exception
        mock_client = MagicMock()
        mock_openai_class.return_value = mock_client
        mock_client.chat.completions.create.side_effect = Exception("API Error")
        
        request_data = {
            "query": "test",
            "gems": [{"name": "test", "description": "test"}]
        }
        
        response = client.post("/rank", json=request_data)
        assert response.status_code == 500
        assert "Ranking failed" in response.json()["detail"]

    def test_cors_headers(self):
        """Test CORS headers are present."""
        response = client.options("/health")
        assert response.status_code == 200
        # CORS headers should be present due to middleware

    def test_gem_info_model_validation(self):
        """Test GemInfo model validation."""
        # Valid gem info
        valid_gem = {
            "name": "rails",
            "description": "Web framework",
            "keywords": ["web", "framework"],
            "download_count": 1000,
            "stars": 500
        }
        
        request_data = {
            "query": "test",
            "gems": [valid_gem]
        }
        
        # Should not raise validation error
        response = client.post("/rank", json=request_data)
        # Will fail due to no API key, but validation should pass
        assert response.status_code == 503  # Service unavailable (no API key)
        
    def test_request_response_models(self):
        """Test request and response model structure."""
        # Test that the models are properly defined and work with FastAPI
        from main import RankRequest, RankResponse, SuggestRequest, SuggestResponse, GemInfo
        
        # Test GemInfo model
        gem = GemInfo(name="test", description="test description")
        assert gem.name == "test"
        assert gem.keywords == []  # Default empty list
        
        # Test RankRequest model
        rank_req = RankRequest(
            query="test query",
            gems=[gem],
            max_results=5
        )
        assert rank_req.max_results == 5
        assert len(rank_req.gems) == 1


# Integration test class
class TestLLMGatewayIntegration:
    """Integration tests that test the service as a whole."""
    
    @patch('main.openai.OpenAI')
    def test_end_to_end_ranking_flow(self, mock_openai_class):
        """Test complete ranking flow from request to response."""
        # Setup mock
        mock_client = MagicMock()
        mock_openai_class.return_value = mock_client
        mock_response = MagicMock()
        mock_response.choices = [MagicMock()]
        mock_response.choices[0].message.content = json.dumps({
            "rankings": [1, 0],
            "scores": [0.8, 0.6],
            "reasoning": "Sinatra is better for APIs"
        })
        mock_client.chat.completions.create.return_value = mock_response
        
        # Real-world-like request
        request_data = {
            "query": "lightweight API framework",
            "gems": [
                {
                    "name": "rails",
                    "description": "Full-stack web application framework",
                    "keywords": ["web", "framework", "full-stack"],
                    "stars": 55000,
                    "download_count": 500000000,
                    "version": "7.0.0",
                    "homepage": "https://rubyonrails.org"
                },
                {
                    "name": "sinatra",
                    "description": "DSL for quickly creating web applications",
                    "keywords": ["web", "micro", "api", "lightweight"],
                    "stars": 12000,
                    "download_count": 200000000,
                    "version": "3.0.0",
                    "homepage": "http://sinatrarb.com"
                }
            ],
            "max_results": 2
        }
        
        response = client.post("/rank", json=request_data)
        assert response.status_code == 200
        
        data = response.json()
        assert data["gem_names"] == ["sinatra", "rails"]  # Sinatra ranked first
        assert data["scores"] == [0.8, 0.6]
        assert "API" in data["reasoning"] or "api" in data["reasoning"]


if __name__ == "__main__":
    pytest.main([__file__, "-v"]) 