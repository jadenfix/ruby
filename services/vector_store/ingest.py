"""
GemHub Vector Store - Lane D
FAISS-based vector search for gem documentation and metadata.
Builds searchable embeddings from gem READMEs and descriptions.
"""

import os
import json
import sqlite3
import logging
import numpy as np
from typing import List, Dict, Any, Optional, Tuple
from pathlib import Path
import asyncio
from datetime import datetime

try:
    import faiss
    import openai
    from sentence_transformers import SentenceTransformer
    HAS_DEPENDENCIES = True
except ImportError as e:
    print(f"Missing dependencies: {e}")
    print("Install with: pip install faiss-cpu sentence-transformers")
    HAS_DEPENDENCIES = False

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class GemVectorStore:
    """
    Vector store for gem documentation using FAISS and sentence transformers.
    Provides semantic search capabilities for gem discovery.
    """
    
    def __init__(self, store_path: str = "vector_store", embedding_model: str = "all-MiniLM-L6-v2"):
        """
        Initialize the vector store.
        
        Args:
            store_path: Directory to store FAISS index and metadata
            embedding_model: Sentence transformer model for embeddings
        """
        self.store_path = Path(store_path)
        self.store_path.mkdir(exist_ok=True)
        
        self.embedding_model_name = embedding_model
        self.embedding_model = None
        self.index = None
        self.metadata_db = None
        self.dimension = 384  # Default for all-MiniLM-L6-v2
        
        # Database for storing gem metadata
        self.db_path = self.store_path / "metadata.db"
        self.index_path = self.store_path / "faiss.index"
        
        self._init_database()
        
    def _init_database(self):
        """Initialize SQLite database for metadata storage."""
        self.metadata_db = sqlite3.connect(str(self.db_path), check_same_thread=False)
        self.metadata_db.execute("""
            CREATE TABLE IF NOT EXISTS gems (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT UNIQUE NOT NULL,
                description TEXT,
                readme_content TEXT,
                keywords TEXT, -- JSON array
                version TEXT,
                homepage TEXT,
                source_code_uri TEXT,
                download_count INTEGER DEFAULT 0,
                stars INTEGER DEFAULT 0,
                last_updated TEXT,
                created_at TEXT DEFAULT CURRENT_TIMESTAMP,
                embedding_vector_id INTEGER -- Index into FAISS
            )
        """)
        
        self.metadata_db.execute("""
            CREATE INDEX IF NOT EXISTS idx_gems_name ON gems(name);
            CREATE INDEX IF NOT EXISTS idx_gems_vector_id ON gems(embedding_vector_id);
        """)
        
        self.metadata_db.commit()
        logger.info("Metadata database initialized")
        
    def load_embedding_model(self):
        """Load the sentence transformer model for embeddings."""
        if not HAS_DEPENDENCIES:
            raise RuntimeError("Required dependencies not installed")
            
        if self.embedding_model is None:
            logger.info(f"Loading embedding model: {self.embedding_model_name}")
            self.embedding_model = SentenceTransformer(self.embedding_model_name)
            self.dimension = self.embedding_model.get_sentence_embedding_dimension()
            logger.info(f"Model loaded with dimension: {self.dimension}")
            
    def load_or_create_index(self):
        """Load existing FAISS index or create a new one."""
        if self.index is None:
            if self.index_path.exists():
                logger.info("Loading existing FAISS index")
                self.index = faiss.read_index(str(self.index_path))
            else:
                logger.info("Creating new FAISS index")
                # Using IndexFlatIP for cosine similarity (inner product with normalized vectors)
                self.index = faiss.IndexFlatIP(self.dimension)
                
    def add_gem(self, gem_data: Dict[str, Any], readme_content: str = "") -> int:
        """
        Add a gem to the vector store.
        
        Args:
            gem_data: Dictionary containing gem metadata
            readme_content: README content for embedding
            
        Returns:
            ID of the added gem
        """
        if not HAS_DEPENDENCIES:
            logger.warning("Dependencies not available, skipping embedding")
            return -1
            
        self.load_embedding_model()
        self.load_or_create_index()
        
        name = gem_data.get("name", "")
        description = gem_data.get("description", "")
        keywords = gem_data.get("keywords", [])
        
        # Create text for embedding
        embedding_text = self._create_embedding_text(name, description, readme_content, keywords)
        
        # Generate embedding
        embedding = self.embedding_model.encode([embedding_text])
        embedding = embedding / np.linalg.norm(embedding)  # Normalize for cosine similarity
        
        # Add to FAISS index
        vector_id = self.index.ntotal
        self.index.add(embedding.astype(np.float32))
        
        # Store metadata in database
        cursor = self.metadata_db.cursor()
        cursor.execute("""
            INSERT OR REPLACE INTO gems 
            (name, description, readme_content, keywords, version, homepage, 
             source_code_uri, download_count, stars, last_updated, embedding_vector_id)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            name,
            description,
            readme_content,
            json.dumps(keywords) if keywords else "[]",
            gem_data.get("version", ""),
            gem_data.get("homepage", ""),
            gem_data.get("source_code_uri", ""),
            gem_data.get("download_count", 0),
            gem_data.get("stars", 0),
            gem_data.get("last_updated", datetime.now().isoformat()),
            vector_id
        ))
        
        gem_id = cursor.lastrowid
        self.metadata_db.commit()
        
        logger.info(f"Added gem '{name}' with vector ID {vector_id}")
        return gem_id
        
    def _create_embedding_text(self, name: str, description: str, readme: str, keywords: List[str]) -> str:
        """Create comprehensive text for embedding generation."""
        parts = []
        
        if name:
            parts.append(f"Gem: {name}")
            
        if description:
            parts.append(f"Description: {description}")
            
        if keywords:
            parts.append(f"Keywords: {', '.join(keywords)}")
            
        if readme:
            # Truncate README to avoid token limits
            readme_truncated = readme[:2000] if len(readme) > 2000 else readme
            parts.append(f"Documentation: {readme_truncated}")
            
        return "\n".join(parts)
        
    def search(self, query: str, k: int = 5) -> List[Dict[str, Any]]:
        """
        Search for gems using semantic similarity.
        
        Args:
            query: Search query
            k: Number of results to return
            
        Returns:
            List of gem metadata with similarity scores
        """
        if not HAS_DEPENDENCIES:
            logger.warning("Dependencies not available, returning empty results")
            return []
            
        if self.index is None or self.index.ntotal == 0:
            logger.warning("No gems in index")
            return []
            
        self.load_embedding_model()
        
        # Generate query embedding
        query_embedding = self.embedding_model.encode([query])
        query_embedding = query_embedding / np.linalg.norm(query_embedding)
        
        # Search FAISS index
        scores, indices = self.index.search(query_embedding.astype(np.float32), k)
        
        # Retrieve metadata for results
        results = []
        cursor = self.metadata_db.cursor()
        
        for i, (score, idx) in enumerate(zip(scores[0], indices[0])):
            if idx == -1:  # FAISS returns -1 for invalid indices
                continue
                
            cursor.execute("""
                SELECT name, description, keywords, version, homepage, 
                       source_code_uri, download_count, stars, last_updated
                FROM gems WHERE embedding_vector_id = ?
            """, (int(idx),))
            
            row = cursor.fetchone()
            if row:
                result = {
                    "name": row[0],
                    "description": row[1],
                    "keywords": json.loads(row[2]) if row[2] else [],
                    "version": row[3],
                    "homepage": row[4],
                    "source_code_uri": row[5],
                    "download_count": row[6],
                    "stars": row[7],
                    "last_updated": row[8],
                    "similarity_score": float(score),
                    "rank": i + 1
                }
                results.append(result)
                
        return results
        
    def save_index(self):
        """Save the FAISS index to disk."""
        if self.index is not None:
            faiss.write_index(self.index, str(self.index_path))
            logger.info(f"Index saved to {self.index_path}")
            
    def get_stats(self) -> Dict[str, Any]:
        """Get statistics about the vector store."""
        cursor = self.metadata_db.cursor()
        cursor.execute("SELECT COUNT(*) FROM gems")
        gem_count = cursor.fetchone()[0]
        
        return {
            "total_gems": gem_count,
            "index_size": self.index.ntotal if self.index else 0,
            "dimension": self.dimension,
            "model": self.embedding_model_name,
            "store_path": str(self.store_path)
        }

def load_sample_gems() -> List[Dict[str, Any]]:
    """Load sample Ruby gems data for testing."""
    return [
        {
            "name": "rails",
            "description": "Ruby on Rails is a web application framework.",
            "keywords": ["web", "framework", "mvc", "activerecord"],
            "version": "7.0.0",
            "homepage": "https://rubyonrails.org",
            "download_count": 500000000,
            "stars": 55000
        },
        {
            "name": "rspec",
            "description": "Behaviour Driven Development framework for Ruby.",
            "keywords": ["testing", "bdd", "spec", "behavior"],
            "version": "3.12.0",
            "homepage": "https://rspec.info",
            "download_count": 300000000,
            "stars": 12000
        },
        {
            "name": "devise",
            "description": "Flexible authentication solution for Rails applications.",
            "keywords": ["authentication", "rails", "security", "user"],
            "version": "4.9.0",
            "homepage": "https://github.com/heartcombo/devise",
            "download_count": 200000000,
            "stars": 23000
        },
        {
            "name": "sidekiq",
            "description": "Efficient background processing framework for Ruby.",
            "keywords": ["background", "jobs", "queue", "redis"],
            "version": "7.0.0",
            "homepage": "https://sidekiq.org",
            "download_count": 150000000,
            "stars": 13000
        },
        {
            "name": "pundit",
            "description": "Minimal authorization through OO design and pure Ruby classes.",
            "keywords": ["authorization", "policy", "security", "rbac"],
            "version": "2.3.0",
            "homepage": "https://github.com/varvet/pundit",
            "download_count": 100000000,
            "stars": 8000
        }
    ]

async def build_index():
    """Build the vector store index with sample data."""
    logger.info("Building vector store index...")
    
    if not HAS_DEPENDENCIES:
        print("Error: Required dependencies not installed")
        print("Install with: pip install faiss-cpu sentence-transformers")
        return
    
    store = GemVectorStore()
    
    # Load sample gems
    sample_gems = load_sample_gems()
    
    for gem in sample_gems:
        # Simulate README content
        readme_content = f"""
# {gem['name']}

{gem['description']}

## Installation

Add this line to your application's Gemfile:

```ruby
gem '{gem['name']}'
```

## Usage

This gem provides {', '.join(gem['keywords'])} functionality for Ruby applications.

## Features

- High performance
- Well documented
- Extensive test coverage
- Active community support

## Contributing

Bug reports and pull requests are welcome on GitHub.
"""
        
        store.add_gem(gem, readme_content)
    
    # Save the index
    store.save_index()
    
    # Print statistics
    stats = store.get_stats()
    logger.info(f"Index built successfully: {stats}")
    
    # Test search
    logger.info("Testing search functionality...")
    results = store.search("web framework", k=3)
    for result in results:
        logger.info(f"Found: {result['name']} (score: {result['similarity_score']:.3f})")

def search_gems(query: str, k: int = 5) -> List[Dict[str, Any]]:
    """
    Utility function for searching gems.
    
    Args:
        query: Search query
        k: Number of results to return
        
    Returns:
        List of matching gems with metadata
    """
    if not HAS_DEPENDENCIES:
        return []
        
    store = GemVectorStore()
    store.load_or_create_index()
    return store.search(query, k)

if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description="GemHub Vector Store Management")
    parser.add_argument("command", choices=["build", "search", "stats"], 
                       help="Command to execute")
    parser.add_argument("--query", type=str, help="Search query (for search command)")
    parser.add_argument("--limit", type=int, default=5, help="Number of results (for search)")
    
    args = parser.parse_args()
    
    if args.command == "build":
        asyncio.run(build_index())
    elif args.command == "search":
        if not args.query:
            print("Error: --query required for search command")
            exit(1)
        results = search_gems(args.query, args.limit)
        print(f"\nSearch results for '{args.query}':")
        for result in results:
            print(f"- {result['name']}: {result['description']} (score: {result['similarity_score']:.3f})")
    elif args.command == "stats":
        store = GemVectorStore()
        stats = store.get_stats()
        print("Vector Store Statistics:")
        for key, value in stats.items():
            print(f"  {key}: {value}") 