"""
Unit tests for GemHub Vector Store Service - Lane D
Tests FAISS indexing, search functionality, and database operations
"""

import pytest
import tempfile
import shutil
import sqlite3
from pathlib import Path
from unittest.mock import patch, MagicMock
import json
import numpy as np

# Import the module under test
import sys
sys.path.append('..')

try:
    from ingest import GemVectorStore, load_sample_gems, search_gems
    DEPENDENCIES_AVAILABLE = True
except ImportError:
    DEPENDENCIES_AVAILABLE = False

@pytest.mark.skipif(not DEPENDENCIES_AVAILABLE, reason="Dependencies not available")
class TestGemVectorStore:
    """Test suite for GemVectorStore class."""
    
    def setup_method(self):
        """Setup for each test method."""
        # Create temporary directory for testing
        self.temp_dir = Path(tempfile.mkdtemp())
        self.store = GemVectorStore(store_path=str(self.temp_dir))
        
    def teardown_method(self):
        """Cleanup after each test method."""
        if hasattr(self, 'temp_dir') and self.temp_dir.exists():
            shutil.rmtree(self.temp_dir)

    def test_initialization(self):
        """Test vector store initialization."""
        assert self.store.store_path == self.temp_dir
        assert self.store.embedding_model_name == "all-MiniLM-L6-v2"
        assert self.store.dimension == 384
        assert self.store.db_path == self.temp_dir / "metadata.db"
        assert self.store.index_path == self.temp_dir / "faiss.index"
        
        # Check database was created
        assert self.store.db_path.exists()
        
        # Check tables were created
        cursor = self.store.metadata_db.cursor()
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
        tables = [row[0] for row in cursor.fetchall()]
        assert "gems" in tables

    @patch('ingest.faiss')
    @patch('ingest.SentenceTransformer')
    def test_load_embedding_model(self, mock_transformer, mock_faiss):
        """Test loading the embedding model."""
        # Mock the sentence transformer
        mock_model = MagicMock()
        mock_model.get_sentence_embedding_dimension.return_value = 384
        mock_transformer.return_value = mock_model
        
        self.store.load_embedding_model()
        
        assert self.store.embedding_model == mock_model
        mock_transformer.assert_called_once_with("all-MiniLM-L6-v2")

    @patch('ingest.faiss')
    def test_load_or_create_index_new(self, mock_faiss):
        """Test creating a new FAISS index."""
        # Mock FAISS
        mock_index = MagicMock()
        mock_faiss.IndexFlatIP.return_value = mock_index
        
        self.store.load_or_create_index()
        
        assert self.store.index == mock_index
        mock_faiss.IndexFlatIP.assert_called_once_with(384)

    @patch('ingest.faiss')
    def test_load_or_create_index_existing(self, mock_faiss):
        """Test loading an existing FAISS index."""
        # Create a dummy index file
        index_path = self.temp_dir / "faiss.index"
        index_path.touch()
        
        mock_index = MagicMock()
        mock_faiss.read_index.return_value = mock_index
        
        self.store.load_or_create_index()
        
        assert self.store.index == mock_index
        mock_faiss.read_index.assert_called_once_with(str(index_path))

    @patch('ingest.faiss')
    @patch('ingest.SentenceTransformer')
    def test_add_gem(self, mock_transformer, mock_faiss):
        """Test adding a gem to the vector store."""
        # Setup mocks
        mock_model = MagicMock()
        mock_model.encode.return_value = np.array([[0.1, 0.2, 0.3, 0.4] * 96])  # 384 dimensions
        mock_transformer.return_value = mock_model
        
        mock_index = MagicMock()
        mock_index.ntotal = 0
        mock_faiss.IndexFlatIP.return_value = mock_index
        
        # Test data
        gem_data = {
            "name": "test_gem",
            "description": "A test gem",
            "keywords": ["test", "gem"],
            "version": "1.0.0",
            "stars": 100
        }
        readme_content = "# Test Gem\nThis is a test gem."
        
        # Add gem
        gem_id = self.store.add_gem(gem_data, readme_content)
        
        # Verify database insertion
        cursor = self.store.metadata_db.cursor()
        cursor.execute("SELECT * FROM gems WHERE id = ?", (gem_id,))
        row = cursor.fetchone()
        
        assert row is not None
        assert row[1] == "test_gem"  # name
        assert row[2] == "A test gem"  # description
        assert row[3] == readme_content  # readme_content
        assert json.loads(row[4]) == ["test", "gem"]  # keywords

    def test_create_embedding_text(self):
        """Test creation of embedding text from gem data."""
        name = "rails"
        description = "Web framework"
        readme = "# Rails\nA web framework"
        keywords = ["web", "framework"]
        
        result = self.store._create_embedding_text(name, description, readme, keywords)
        
        assert "Gem: rails" in result
        assert "Description: Web framework" in result
        assert "Keywords: web, framework" in result
        assert "Documentation: # Rails" in result

    @patch('ingest.faiss')
    @patch('ingest.SentenceTransformer')
    def test_search_gems(self, mock_transformer, mock_faiss):
        """Test searching for gems."""
        # Setup mocks
        mock_model = MagicMock()
        mock_model.encode.return_value = np.array([[0.1, 0.2, 0.3, 0.4] * 96])
        mock_transformer.return_value = mock_model
        
        mock_index = MagicMock()
        mock_index.ntotal = 1
        mock_index.search.return_value = (
            np.array([[0.8]]),  # scores
            np.array([[0]])     # indices
        )
        mock_faiss.read_index.return_value = mock_index
        
        # Add a test gem to database first
        cursor = self.store.metadata_db.cursor()
        cursor.execute("""
            INSERT INTO gems 
            (name, description, keywords, version, stars, embedding_vector_id)
            VALUES (?, ?, ?, ?, ?, ?)
        """, ("test_gem", "Test description", '["test"]', "1.0.0", 100, 0))
        self.store.metadata_db.commit()
        
        # Create the index file to trigger loading existing index
        index_path = self.temp_dir / "faiss.index"
        index_path.touch()
        
        # Perform search
        results = self.store.search("test query", k=1)
        
        assert len(results) == 1
        assert results[0]["name"] == "test_gem"
        assert results[0]["description"] == "Test description"
        assert results[0]["similarity_score"] == 0.8
        assert results[0]["rank"] == 1

    def test_search_empty_index(self):
        """Test searching with empty index."""
        results = self.store.search("test query")
        assert results == []

    @patch('ingest.faiss')
    def test_save_index(self, mock_faiss):
        """Test saving the FAISS index."""
        mock_index = MagicMock()
        self.store.index = mock_index
        
        self.store.save_index()
        
        mock_faiss.write_index.assert_called_once_with(mock_index, str(self.store.index_path))

    def test_get_stats(self):
        """Test getting vector store statistics."""
        # Add a test gem
        cursor = self.store.metadata_db.cursor()
        cursor.execute("""
            INSERT INTO gems (name, description) VALUES (?, ?)
        """, ("test_gem", "Test description"))
        self.store.metadata_db.commit()
        
        stats = self.store.get_stats()
        
        assert stats["total_gems"] == 1
        assert stats["index_size"] == 0  # No index loaded
        assert stats["dimension"] == 384
        assert stats["model"] == "all-MiniLM-L6-v2"
        assert stats["store_path"] == str(self.temp_dir)

    def test_database_operations(self):
        """Test direct database operations."""
        cursor = self.store.metadata_db.cursor()
        
        # Test insertion
        cursor.execute("""
            INSERT INTO gems 
            (name, description, keywords, version, homepage, stars, download_count)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        """, ("test_gem", "Description", '["test"]', "1.0.0", "https://example.com", 50, 1000))
        
        self.store.metadata_db.commit()
        
        # Test retrieval
        cursor.execute("SELECT * FROM gems WHERE name = ?", ("test_gem",))
        row = cursor.fetchone()
        
        assert row is not None
        assert row[1] == "test_gem"
        assert row[7] == "https://example.com"  # homepage
        assert row[9] == 50  # stars
        assert row[8] == 1000  # download_count


class TestUtilityFunctions:
    """Test utility functions."""
    
    def test_load_sample_gems(self):
        """Test loading sample gems data."""
        gems = load_sample_gems()
        
        assert len(gems) == 5
        assert gems[0]["name"] == "rails"
        assert gems[1]["name"] == "rspec"
        
        # Check required fields are present
        for gem in gems:
            assert "name" in gem
            assert "description" in gem
            assert "keywords" in gem
            assert "version" in gem
            assert "homepage" in gem
            assert "download_count" in gem
            assert "stars" in gem

    @patch('ingest.GemVectorStore')
    def test_search_gems_utility(self, mock_store_class):
        """Test the search_gems utility function."""
        # Mock the vector store
        mock_store = MagicMock()
        mock_store.search.return_value = [
            {"name": "rails", "description": "Web framework", "similarity_score": 0.9}
        ]
        mock_store_class.return_value = mock_store
        
        results = search_gems("web framework", k=1)
        
        assert len(results) == 1
        assert results[0]["name"] == "rails"
        mock_store.load_or_create_index.assert_called_once()
        mock_store.search.assert_called_once_with("web framework", 1)

    @patch('ingest.HAS_DEPENDENCIES', False)
    def test_search_gems_no_dependencies(self):
        """Test search_gems when dependencies are not available."""
        results = search_gems("test query")
        assert results == []


@pytest.mark.skipif(not DEPENDENCIES_AVAILABLE, reason="Dependencies not available")
class TestVectorStoreIntegration:
    """Integration tests for the vector store."""
    
    def setup_method(self):
        """Setup for integration tests."""
        self.temp_dir = Path(tempfile.mkdtemp())
        
    def teardown_method(self):
        """Cleanup after integration tests."""
        if hasattr(self, 'temp_dir') and self.temp_dir.exists():
            shutil.rmtree(self.temp_dir)

    @patch('ingest.faiss')
    @patch('ingest.SentenceTransformer')
    def test_full_workflow(self, mock_transformer, mock_faiss):
        """Test the complete workflow: add gems, search, get stats."""
        # Setup mocks
        mock_model = MagicMock()
        mock_model.encode.return_value = np.array([[0.1, 0.2, 0.3, 0.4] * 96])
        mock_model.get_sentence_embedding_dimension.return_value = 384
        mock_transformer.return_value = mock_model
        
        mock_index = MagicMock()
        mock_index.ntotal = 0
        mock_index.search.return_value = (
            np.array([[0.9, 0.7]]),
            np.array([[0, 1]])
        )
        mock_faiss.IndexFlatIP.return_value = mock_index
        
        # Create vector store
        store = GemVectorStore(store_path=str(self.temp_dir))
        
        # Add some gems
        sample_gems = load_sample_gems()[:2]  # Just use first 2
        
        for gem in sample_gems:
            store.add_gem(gem, f"README for {gem['name']}")
        
        # Update mock to reflect added gems
        mock_index.ntotal = 2
        
        # Search
        results = store.search("web framework", k=2)
        
        # Verify results structure
        assert len(results) <= 2
        for result in results:
            assert "name" in result
            assert "similarity_score" in result
            assert "rank" in result
        
        # Get stats
        stats = store.get_stats()
        assert stats["total_gems"] == 2

    def test_database_schema(self):
        """Test that the database schema is created correctly."""
        store = GemVectorStore(store_path=str(self.temp_dir))
        
        cursor = store.metadata_db.cursor()
        
        # Check table exists
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='gems'")
        assert cursor.fetchone() is not None
        
        # Check columns
        cursor.execute("PRAGMA table_info(gems)")
        columns = [row[1] for row in cursor.fetchall()]
        
        expected_columns = [
            'id', 'name', 'description', 'readme_content', 'keywords', 
            'version', 'homepage', 'source_code_uri', 'download_count', 
            'stars', 'last_updated', 'created_at', 'embedding_vector_id'
        ]
        
        for col in expected_columns:
            assert col in columns

    def test_error_handling(self):
        """Test error handling in various scenarios."""
        store = GemVectorStore(store_path=str(self.temp_dir))
        
        # Test with invalid gem data
        with pytest.raises(Exception):
            store.add_gem({}, "")  # Missing required 'name' field might cause issues
        
        # Test search with no model loaded
        results = store.search("test query")
        # Should return empty list or handle gracefully


if __name__ == "__main__":
    pytest.main([__file__, "-v"]) 