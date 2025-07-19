import React, { useState, useEffect } from 'react';
import axios from 'axios';
import './App.css';

interface Gem {
  id: number;
  name: string;
  version: string;
  description: string;
  homepage: string;
  license: string;
  downloads: number;
  rating: number;
  ratings_count: number;
  badges_count: number;
  created_at: string;
}

interface GemsResponse {
  gems: Gem[];
}

interface Stats {
  totalGems: number;
  totalDownloads: number;
  averageRating: number;
  totalBadges: number;
}

function App() {
  const [gems, setGems] = useState<Gem[]>([]);
  const [stats, setStats] = useState<Stats>({ totalGems: 0, totalDownloads: 0, averageRating: 0, totalBadges: 0 });
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    fetchGems();
  }, []);

  const fetchGems = async () => {
    try {
      setLoading(true);
      const response = await axios.get<GemsResponse>('http://localhost:4567/gems', {
        headers: {
          'Authorization': 'Bearer test-token'
        }
      });
      
      const gemData = response.data.gems;
      setGems(gemData);
      
      // Calculate stats
      const totalDownloads = gemData.reduce((sum, gem) => sum + gem.downloads, 0);
      const totalRatings = gemData.reduce((sum, gem) => sum + gem.ratings_count, 0);
      const totalRatingPoints = gemData.reduce((sum, gem) => sum + (gem.rating * gem.ratings_count), 0);
      const averageRating = totalRatings > 0 ? totalRatingPoints / totalRatings : 0;
      const totalBadges = gemData.reduce((sum, gem) => sum + gem.badges_count, 0);
      
      setStats({
        totalGems: gemData.length,
        totalDownloads,
        averageRating,
        totalBadges
      });
      
    } catch (err) {
      setError('Failed to fetch gems from API');
      console.error('Error fetching gems:', err);
    } finally {
      setLoading(false);
    }
  };

  const formatNumber = (num: number): string => {
    if (num >= 1000000) {
      return `${(num / 1000000).toFixed(1)}M`;
    }
    if (num >= 1000) {
      return `${(num / 1000).toFixed(1)}K`;
    }
    return num.toString();
  };

  const formatRating = (rating: number): string => {
    return rating.toFixed(1);
  };

  if (loading) {
    return (
      <div className="App">
        <div className="loading">
          <h2>Loading GemHub...</h2>
          <div className="spinner"></div>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="App">
        <div className="error">
          <h2>❌ {error}</h2>
          <p>Make sure the API server is running on http://localhost:4567</p>
          <button onClick={fetchGems} className="retry-btn">Retry</button>
        </div>
      </div>
    );
  }

  return (
    <div className="App">
      <header className="App-header">
        <h1>💎 GemHub - Ruby Gem Marketplace</h1>
        <p>Discover, create, and manage Ruby gems with our comprehensive platform</p>
      </header>

      {/* Stats Dashboard */}
      <section className="stats-section">
        <div className="stats-grid">
          <div className="stat-card">
            <div className="stat-icon">📦</div>
            <div className="stat-info">
              <h3>{stats.totalGems}</h3>
              <p>Total Gems</p>
            </div>
          </div>
          
          <div className="stat-card">
            <div className="stat-icon">⬇️</div>
            <div className="stat-info">
              <h3>{formatNumber(stats.totalDownloads)}</h3>
              <p>Total Downloads</p>
            </div>
          </div>
          
          <div className="stat-card">
            <div className="stat-icon">⭐</div>
            <div className="stat-info">
              <h3>{formatRating(stats.averageRating)}</h3>
              <p>Average Rating</p>
            </div>
          </div>
          
          <div className="stat-card">
            <div className="stat-icon">🏆</div>
            <div className="stat-info">
              <h3>{stats.totalBadges}</h3>
              <p>Quality Badges</p>
            </div>
          </div>
        </div>
      </section>

      {/* Gems Grid */}
      <section className="gems-section">
        <h2>🔍 Available Gems</h2>
        <div className="gems-grid">
          {gems.map((gem) => (
            <div key={gem.id} className="gem-card">
              <div className="gem-header">
                <h3>{gem.name}</h3>
                <span className="version">v{gem.version}</span>
              </div>
              
              <p className="description">{gem.description}</p>
              
              <div className="gem-stats">
                <div className="stat">
                  <span className="label">⭐ Rating:</span>
                  <span className="value">{formatRating(gem.rating)} ({gem.ratings_count})</span>
                </div>
                
                <div className="stat">
                  <span className="label">⬇️ Downloads:</span>
                  <span className="value">{formatNumber(gem.downloads)}</span>
                </div>
                
                <div className="stat">
                  <span className="label">🏆 Badges:</span>
                  <span className="value">{gem.badges_count}</span>
                </div>
                
                <div className="stat">
                  <span className="label">📄 License:</span>
                  <span className="value">{gem.license}</span>
                </div>
              </div>
              
              {gem.homepage && (
                <div className="gem-actions">
                  <a 
                    href={gem.homepage} 
                    target="_blank" 
                    rel="noopener noreferrer"
                    className="homepage-link"
                  >
                    🔗 Visit Homepage
                  </a>
                </div>
              )}
            </div>
          ))}
        </div>
      </section>

      {/* API Status */}
      <footer className="api-status">
        <div className="status-indicator">
          <span className="status-dot active"></span>
          <span>API Connected - http://localhost:4567</span>
        </div>
      </footer>
    </div>
  );
}

export default App;
