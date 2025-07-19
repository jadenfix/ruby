import React from 'react';
import { useGemContext } from '../context/GemContext';
import './Dashboard.css';

const Dashboard: React.FC = () => {
  const { gems, selectedGem, selectGem } = useGemContext();

  return (
    <div className="dashboard">
      <div className="top-bar">
        <div className="top-left">
          <h1 className="app-title">GEMHUB OPS</h1>
          <span className="version">v2.1.7 CLASSIFIED</span>
        </div>
        <div className="top-center">
          <span className="section-title">TACTICAL COMMAND / OVERVIEW</span>
        </div>
        <div className="top-right">
          <span className="last-update">LAST UPDATE: {new Date().toLocaleString()}</span>
        </div>
      </div>

      <div className="dashboard-content">
        <nav className="sidebar">
          <div className="nav-items">
            <button className="nav-item active">COMMAND CENTER</button>
            <button className="nav-item">SECURITY SCAN</button>
            <button className="nav-item">PERFORMANCE</button>
            <button className="nav-item">INTELLIGENCE</button>
            <button className="nav-item">SYSTEMS</button>
          </div>
          
          <div className="system-status">
            <div className="status-indicator">
              <div className="status-dot online"></div>
              <span>SYSTEM ONLINE</span>
            </div>
            <div className="status-metrics">
              <div className="metric">
                <span>GEMS: {gems.length} ACTIVE</span>
              </div>
            </div>
          </div>
        </nav>

        <main className="main-content">
          <div className="content-grid">
            <div className="grid-row top-row">
              <div className="panel gem-list-panel">
                <div className="panel-header">
                  <h3>GEM ALLOCATION</h3>
                  <div className="panel-stats">
                    <div className="stat">
                      <span className="stat-number">{gems.length}</span>
                      <span className="stat-label">Active Gems</span>
                    </div>
                  </div>
                </div>
                <div className="gem-list">
                  {gems.map((gem) => (
                    <div 
                      key={gem.id} 
                      className={`gem-item ${selectedGem?.id === gem.id ? 'selected' : ''}`}
                      onClick={() => selectGem(gem)}
                    >
                      <div className="gem-header">
                        <div className="gem-name">
                          <span className="gem-code">G-{String(gem.id).padStart(3, '0')}</span>
                          <span className="gem-title">{gem.name.toUpperCase()}</span>
                        </div>
                      </div>
                      <div className="gem-details">
                        <div className="gem-version">v{gem.version}</div>
                        <div className="gem-stats">
                          <div className="stat">
                            <span>Downloads: {gem.downloads.toLocaleString()}</span>
                          </div>
                          <div className="stat">
                            <span>Rating: {gem.rating.toFixed(1)}</span>
                          </div>
                        </div>
                      </div>
                      <div className="gem-description">
                        {gem.description}
                      </div>
                    </div>
                  ))}
                </div>
              </div>

              <div className="panel activity-panel">
                <div className="panel-header">
                  <h3>ACTIVITY LOG</h3>
                </div>
                <div className="activity-log">
                  <div className="activity-item">
                    <div className="activity-header">
                      <div className="activity-time">
                        <span>14:42:33</span>
                      </div>
                    </div>
                    <div className="activity-action">Security scan completed</div>
                    <div className="activity-details">Rails gem - 0 vulnerabilities found</div>
                  </div>
                  <div className="activity-item">
                    <div className="activity-header">
                      <div className="activity-time">
                        <span>14:38:17</span>
                      </div>
                    </div>
                    <div className="activity-action">Performance benchmark</div>
                    <div className="activity-details">Sinatra gem - 2.1M ops/s average</div>
                  </div>
                </div>
              </div>

              <div className="panel security-panel">
                <div className="panel-header">
                  <h3>SECURITY STATUS</h3>
                </div>
                <div className="security-panel">
                  <div className="security-overview">
                    <div className="security-stat">
                      <span>Total Scans: 12</span>
                    </div>
                    <div className="security-stat">
                      <span>Patched: 8</span>
                    </div>
                    <div className="security-stat">
                      <span>Active: 2</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <div className="grid-row bottom-row">
              <div className="panel details-panel">
                <div className="panel-header">
                  <h3>GEM DETAILS</h3>
                </div>
                {selectedGem ? (
                  <div className="gem-details-container">
                    <div className="gem-header-details">
                      <h2 className="gem-name-large">{selectedGem.name}</h2>
                      <span className="gem-version-large">v{selectedGem.version}</span>
                    </div>
                    <div className="gem-description-large">
                      {selectedGem.description}
                    </div>
                    <div className="gem-stats-grid">
                      <div className="stat-card">
                        <div className="stat-content">
                          <span className="stat-value">{selectedGem.downloads.toLocaleString()}</span>
                          <span className="stat-label">Downloads</span>
                        </div>
                      </div>
                      <div className="stat-card">
                        <div className="stat-content">
                          <span className="stat-value">{selectedGem.rating.toFixed(1)}</span>
                          <span className="stat-label">Rating</span>
                        </div>
                      </div>
                    </div>
                  </div>
                ) : (
                  <div className="no-selection">
                    <p>Select a gem to view details</p>
                  </div>
                )}
              </div>

              <div className="panel performance-panel">
                <div className="panel-header">
                  <h3>PERFORMANCE METRICS</h3>
                </div>
                <div className="performance-panel">
                  <div className="performance-overview">
                    <div className="perf-stat">
                      <span>Avg Performance: 2.1M ops/s</span>
                    </div>
                    <div className="perf-stat">
                      <span>Tests Run: 11</span>
                    </div>
                    <div className="perf-stat">
                      <span>Improvement: +15%</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </main>
      </div>
    </div>
  );
};

export default Dashboard;
