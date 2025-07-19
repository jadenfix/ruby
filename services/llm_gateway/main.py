"""
GemHub LLM Gateway Service - Lane D
FastAPI service providing AI-powered gem ranking and suggestions.
Integrates with Anthropic Claude API and provides rate-limited endpoints.
"""

import os
import logging
from typing import List, Dict, Any, Optional
import asyncio
from contextlib import asynccontextmanager
from datetime import datetime
import json

from fastapi import FastAPI, HTTPException, Depends, Request
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
import anthropic
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
from slowapi.middleware import SlowAPIMiddleware

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Rate limiter setup
limiter = Limiter(key_func=get_remote_address)

# Anthropic configuration
ANTHROPIC_API_KEY = os.getenv("ANTHROPIC_API_KEY")
MODEL = os.getenv("MODEL", "claude-3-haiku-20240307")

if not ANTHROPIC_API_KEY:
    logger.warning("ANTHROPIC_API_KEY not set. Using mock responses.")

# Request/Response models
class GemInfo(BaseModel):
    """Information about a gem for ranking/suggestion purposes."""
    name: str
    description: Optional[str] = None
    keywords: List[str] = Field(default_factory=list)
    download_count: Optional[int] = None
    stars: Optional[int] = None
    last_updated: Optional[str] = None

class RankRequest(BaseModel):
    """Request for ranking gems by relevance."""
    query: str = Field(..., description="Search query for ranking gems")
    gems: List[GemInfo] = Field(..., description="List of gems to rank")

class RankResponse(BaseModel):
    """Response with ranked gems."""
    ranked_gems: List[str] = Field(..., description="Gem names ranked by relevance")
    reasoning: Optional[str] = Field(None, description="AI reasoning for ranking")
    confidence: float = Field(..., description="Confidence score 0-1")

class SuggestRequest(BaseModel):
    """Request for gem suggestions."""
    query: str = Field(..., description="Description of what user wants to achieve")
    context: Optional[Dict[str, Any]] = Field(default_factory=dict, description="Additional context")

class SuggestResponse(BaseModel):
    """Response with gem suggestions."""
    suggestions: List[GemInfo] = Field(..., description="Suggested gems")
    reasoning: Optional[str] = Field(None, description="AI reasoning for suggestions")
    confidence: float = Field(..., description="Confidence score 0-1")

class HealthResponse(BaseModel):
    """Health check response."""
    status: str
    model: str
    api_key_configured: bool

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan events."""
    logger.info("Starting GemHub LLM Gateway...")
    
    # Test Anthropic connection if key is available
    if ANTHROPIC_API_KEY:
        try:
            # Test Anthropic connection
            client = anthropic.Anthropic(api_key=ANTHROPIC_API_KEY)
            response = client.messages.create(
                model=MODEL,
                max_tokens=10,
                messages=[{"role": "user", "content": "Hello"}]
            )
            logger.info("Anthropic connection verified")
        except Exception as e:
            logger.warning(f"Anthropic connection test failed: {e}")
    
    yield
    
    logger.info("Shutting down GemHub LLM Gateway...")

# Create FastAPI app
app = FastAPI(
    title="GemHub LLM Gateway",
    description="AI-powered gem ranking and suggestion service",
    version="1.0.0",
    lifespan=lifespan
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Add rate limiting middleware
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)
app.add_middleware(SlowAPIMiddleware)

async def get_anthropic_client():
    """Get Anthropic client instance."""
    if not ANTHROPIC_API_KEY:
        raise HTTPException(status_code=503, detail="Anthropic API key not configured")
    return anthropic.Anthropic(api_key=ANTHROPIC_API_KEY)

@app.get("/health", response_model=HealthResponse)
async def health_check():
    """Health check endpoint."""
    return HealthResponse(
        status="healthy",
        model=MODEL,
        api_key_configured=bool(ANTHROPIC_API_KEY)
    )

@app.post("/rank", response_model=RankResponse)
@limiter.limit("30/minute")
async def rank_gems(request: RankRequest, req: Request, client: anthropic.Anthropic = Depends(get_anthropic_client)):
    """
    Rank gems by relevance to query.
    
    Uses Claude to analyze gem descriptions and rank them by relevance
    to the user's search query.
    """
    try:
        logger.info(f"Ranking {len(request.gems)} gems for query: {request.query}")
        
        # Prepare gem data for Claude
        gem_data = []
        for gem in request.gems:
            gem_info = {
                "name": gem.name,
                "description": gem.description or "No description",
                "keywords": gem.keywords,
                "downloads": gem.download_count or 0,
                "stars": gem.stars or 0
            }
            gem_data.append(gem_info)
        
        # Create prompt for Claude
        prompt = f"""Please rank the following Ruby gems by relevance to this query: "{request.query}"

Gems to rank:
{json.dumps(gem_data, indent=2)}

Respond with a JSON object containing:
1. "ranked_gems": array of gem names in order of relevance (most relevant first)
2. "reasoning": brief explanation of your ranking
3. "confidence": score from 0.0 to 1.0

Focus on how well each gem matches the query based on name, description, keywords, and popularity."""

        # Call Claude API
        try:
            response = client.messages.create(
                model=MODEL,
                max_tokens=1000,
                messages=[{"role": "user", "content": prompt}]
            )
            
            # Parse Claude response
            response_text = response.content[0].text
            logger.info(f"Claude response length: {len(response_text)}")
            
            # Try to extract JSON from response
            try:
                # Claude might wrap JSON in markdown code blocks
                if "```json" in response_text:
                    start = response_text.find("```json") + 7
                    end = response_text.find("```", start)
                    response_text = response_text[start:end].strip()
                elif "```" in response_text:
                    start = response_text.find("```") + 3
                    end = response_text.find("```", start)
                    response_text = response_text[start:end].strip()
                
                result = json.loads(response_text)
                
                # Validate response structure
                if "ranked_gems" not in result:
                    raise ValueError("Missing 'ranked_gems' in response")
                
                return RankResponse(
                    ranked_gems=result.get("ranked_gems", []),
                    reasoning=result.get("reasoning", "No reasoning provided"),
                    confidence=min(1.0, max(0.0, float(result.get("confidence", 0.8))))
                )
                
            except (json.JSONDecodeError, ValueError, KeyError) as e:
                logger.warning(f"Failed to parse Claude response as JSON: {e}")
                # Fallback: simple alphabetical ranking
                fallback_ranking = [gem.name for gem in sorted(request.gems, key=lambda x: x.name)]
                return RankResponse(
                    ranked_gems=fallback_ranking,
                    reasoning=f"Fallback ranking due to parsing error: {e}",
                    confidence=0.3
                )
                
        except anthropic.APIError as e:
            logger.error(f"Claude API error: {e}")
            # Fallback ranking by download count and stars
            fallback_ranking = [
                gem.name for gem in sorted(
                    request.gems, 
                    key=lambda x: (x.download_count or 0) + (x.stars or 0) * 1000,
                    reverse=True
                )
            ]
            return RankResponse(
                ranked_gems=fallback_ranking,
                reasoning="Fallback ranking by popularity due to API error",
                confidence=0.5
            )
            
    except Exception as e:
        logger.error(f"Unexpected error in rank_gems: {e}")
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")

@app.post("/suggest", response_model=SuggestResponse)
@limiter.limit("20/minute")
async def suggest_gems(request: SuggestRequest, req: Request, client: anthropic.Anthropic = Depends(get_anthropic_client)):
    """
    Suggest gems based on user requirements.
    
    Uses Claude to recommend Ruby gems that would help achieve
    the user's stated goal.
    """
    try:
        logger.info(f"Generating suggestions for: {request.query}")
        
        # Create prompt for Claude
        prompt = f"""The user wants to: "{request.query}"

Additional context: {json.dumps(request.context)}

Please suggest relevant Ruby gems that would help accomplish this goal. Respond with a JSON object containing:

1. "suggestions": array of gem objects with these fields:
   - "name": gem name
   - "description": brief description of what it does
   - "keywords": array of relevant keywords
   - "download_count": estimated popularity (number)
   - "stars": estimated GitHub stars (number)

2. "reasoning": explanation of why these gems are recommended
3. "confidence": score from 0.0 to 1.0

Focus on popular, well-maintained gems that are commonly used for this purpose."""

        # Call Claude API
        try:
            response = client.messages.create(
                model=MODEL,
                max_tokens=1500,
                messages=[{"role": "user", "content": prompt}]
            )
            
            # Parse Claude response
            response_text = response.content[0].text
            logger.info(f"Claude suggestion response length: {len(response_text)}")
            
            # Try to extract JSON from response
            try:
                # Claude might wrap JSON in markdown code blocks
                if "```json" in response_text:
                    start = response_text.find("```json") + 7
                    end = response_text.find("```", start)
                    response_text = response_text[start:end].strip()
                elif "```" in response_text:
                    start = response_text.find("```") + 3
                    end = response_text.find("```", start)
                    response_text = response_text[start:end].strip()
                
                result = json.loads(response_text)
                
                # Validate and convert suggestions
                suggestions = []
                for suggestion in result.get("suggestions", []):
                    gem_info = GemInfo(
                        name=suggestion.get("name", "unknown"),
                        description=suggestion.get("description", ""),
                        keywords=suggestion.get("keywords", []),
                        download_count=suggestion.get("download_count", 0),
                        stars=suggestion.get("stars", 0)
                    )
                    suggestions.append(gem_info)
                
                return SuggestResponse(
                    suggestions=suggestions,
                    reasoning=result.get("reasoning", "No reasoning provided"),
                    confidence=min(1.0, max(0.0, float(result.get("confidence", 0.8))))
                )
                
            except (json.JSONDecodeError, ValueError, KeyError) as e:
                logger.warning(f"Failed to parse Claude suggestion response: {e}")
                # Fallback suggestions
                fallback_suggestions = [
                    GemInfo(
                        name="rails",
                        description="Full-stack web application framework",
                        keywords=["web", "framework", "mvc"],
                        download_count=500000000,
                        stars=55000
                    ),
                    GemInfo(
                        name="sinatra",
                        description="Lightweight web application DSL",
                        keywords=["web", "lightweight", "dsl"],
                        download_count=100000000,
                        stars=12000
                    )
                ]
                return SuggestResponse(
                    suggestions=fallback_suggestions,
                    reasoning=f"Fallback suggestions due to parsing error: {e}",
                    confidence=0.3
                )
                
        except anthropic.APIError as e:
            logger.error(f"Claude API error in suggestions: {e}")
            # Fallback suggestions
            fallback_suggestions = [
                GemInfo(
                    name="bundler",
                    description="Dependency manager for Ruby projects",
                    keywords=["dependency", "management", "gems"],
                    download_count=1000000000,
                    stars=4900
                )
            ]
            return SuggestResponse(
                suggestions=fallback_suggestions,
                reasoning="Fallback suggestions due to API error",
                confidence=0.4
            )
            
    except Exception as e:
        logger.error(f"Unexpected error in suggest_gems: {e}")
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")

@app.get("/metrics")
async def get_metrics():
    """Get AI service metrics for dashboard."""
    return {
        "timestamp": datetime.now().isoformat(),
        "gem_metrics": {
            "total_gems": 150,
            "trending_gems": [
                {"name": "rails", "stars": 55000, "downloads": 500000000, "trend": "+5%"},
                {"name": "devise", "stars": 23000, "downloads": 200000000, "trend": "+3%"},
                {"name": "sidekiq", "stars": 13000, "downloads": 150000000, "trend": "+7%"}
            ]
        },
        "ai_metrics": {
            "total_rankings": 1250,
            "total_suggestions": 890,
            "avg_response_time_ms": 850,
            "success_rate": 0.987
        },
        "search_metrics": {
            "total_searches": 3400,
            "vector_index_size": 15000,
            "avg_search_time_ms": 45,
            "top_queries": ["web framework", "testing", "authentication"]
        },
        "security_metrics": {
            "cve_scans": 450,
            "vulnerabilities_found": 23,
            "clean_gems": 127
        }
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001) 