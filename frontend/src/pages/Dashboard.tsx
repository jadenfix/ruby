import React from 'react';
import { useQuery } from 'react-query';
import { Link } from 'react-router-dom';
import {
  CubeIcon,
  StarIcon,
  ShieldCheckIcon,
  ArrowTrendingUpIcon,
  EyeIcon,
  CalendarIcon,
} from '@heroicons/react/24/outline';
import apiClient, { apiKeys, formatDownloads, formatRating, formatDate } from '../api/client';
import { Gem } from '../types';

function Dashboard() {
  // Fetch dashboard stats
  const { data: stats, isLoading: statsLoading, error: statsError } = useQuery({
    queryKey: apiKeys.dashboardStats(),
    queryFn: () => apiClient.getDashboardStats(),
  });

  // Fetch recent gems
  const { data: gemsData, isLoading: gemsLoading } = useQuery({
    queryKey: apiKeys.gems(),
    queryFn: () => apiClient.getGems({ limit: 6 }),
  });

  const StatCard = ({ title, value, icon: Icon, color, description }: {
    title: string;
    value: string | number;
    icon: React.ComponentType<{ className?: string }>;
    color: string;
    description?: string;
  }) => (
    <div className="card p-6">
      <div className="flex items-center">
        <div className={`flex h-12 w-12 items-center justify-center rounded-lg ${color}`}>
          <Icon className="h-6 w-6 text-white" />
        </div>
        <div className="ml-4">
          <p className="text-sm font-medium text-gray-600">{title}</p>
          <p className="text-2xl font-bold text-gray-900">{value}</p>
          {description && (
            <p className="text-xs text-gray-500">{description}</p>
          )}
        </div>
      </div>
    </div>
  );

  const GemCard = ({ gem }: { gem: Gem }) => (
    <Link to={`/gems/${gem.id}`} className="card-hover p-6 block">
      <div className="flex items-start justify-between">
        <div className="flex-1">
          <h3 className="text-lg font-semibold text-gray-900 mb-1">
            {gem.name}
          </h3>
          <p className="text-sm text-gray-600 mb-2">v{gem.version}</p>
          <p className="text-sm text-gray-500 mb-3 line-clamp-2">
            {gem.description || 'No description available'}
          </p>
        </div>
      </div>
      
      <div className="flex items-center justify-between">
        <div className="flex items-center space-x-4 text-sm text-gray-500">
          <div className="flex items-center">
            <StarIcon className="h-4 w-4 text-yellow-400 mr-1" />
            <span>{formatRating(gem.rating)}</span>
            <span className="ml-1">({gem.ratings_count})</span>
          </div>
          <div className="flex items-center">
            <ArrowTrendingUpIcon className="h-4 w-4 mr-1" />
            <span>{formatDownloads(gem.downloads)}</span>
          </div>
        </div>
        
        <div className="flex items-center space-x-1">
          {gem.badges_count > 0 && (
            <div className="flex items-center text-xs text-green-600">
              <ShieldCheckIcon className="h-3 w-3 mr-1" />
              <span>{gem.badges_count}</span>
            </div>
          )}
        </div>
      </div>
    </Link>
  );

  if (statsError) {
    return (
      <div className="text-center py-12">
        <div className="max-w-md mx-auto">
          <h2 className="text-2xl font-bold text-gray-900 mb-4">
            Unable to load dashboard
          </h2>
          <p className="text-gray-600 mb-6">
            There was an error connecting to the API. Please check that the server is running.
          </p>
          <button
            onClick={() => window.location.reload()}
            className="btn-primary"
          >
            Retry
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-8">
      {/* Welcome Header */}
      <div className="text-center">
        <h1 className="text-3xl font-bold gradient-text mb-4">
          Welcome to GemHub
        </h1>
        <p className="text-lg text-gray-600 max-w-2xl mx-auto">
          Discover, create, and manage Ruby gems with our comprehensive marketplace platform.
          Connect with the Ruby community and find the perfect gems for your projects.
        </p>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard
          title="Total Gems"
          value={statsLoading ? '...' : (stats?.totalGems || 0)}
          icon={CubeIcon}
          color="bg-blue-500"
          description="Available packages"
        />
        <StatCard
          title="Total Ratings"
          value={statsLoading ? '...' : (stats?.totalRatings || 0)}
          icon={StarIcon}
          color="bg-yellow-500"
          description="Community reviews"
        />
        <StatCard
          title="Quality Badges"
          value={statsLoading ? '...' : (stats?.totalBadges || 0)}
          icon={ShieldCheckIcon}
          color="bg-green-500"
          description="Verified achievements"
        />
        <StatCard
          title="Avg Rating"
          value={statsLoading ? '...' : (stats?.averageRating ? formatRating(stats.averageRating) : '0.0')}
          icon={StarIcon}
          color="bg-purple-500"
          description="Community score"
        />
      </div>

      {/* Top Rated Gems */}
      {stats?.topRatedGems && stats.topRatedGems.length > 0 && (
        <section>
          <div className="flex items-center justify-between mb-6">
            <h2 className="text-2xl font-bold text-gray-900">Top Rated Gems</h2>
            <Link to="/marketplace" className="text-ruby-600 hover:text-ruby-700 font-medium">
              View all →
            </Link>
          </div>
          <div className="grid grid-cols-1 gap-6 md:grid-cols-2 lg:grid-cols-3">
            {stats.topRatedGems.slice(0, 3).map((gem) => (
              <GemCard key={gem.id} gem={gem} />
            ))}
          </div>
        </section>
      )}

      {/* Recent Gems */}
      <section>
        <div className="flex items-center justify-between mb-6">
          <h2 className="text-2xl font-bold text-gray-900">Recent Gems</h2>
          <Link to="/marketplace" className="text-ruby-600 hover:text-ruby-700 font-medium">
            Browse marketplace →
          </Link>
        </div>
        
        {gemsLoading ? (
          <div className="grid grid-cols-1 gap-6 md:grid-cols-2 lg:grid-cols-3">
            {[...Array(6)].map((_, i) => (
              <div key={i} className="card p-6 animate-pulse">
                <div className="h-4 bg-gray-200 rounded mb-2"></div>
                <div className="h-3 bg-gray-200 rounded mb-4 w-1/3"></div>
                <div className="h-3 bg-gray-200 rounded mb-2"></div>
                <div className="h-3 bg-gray-200 rounded mb-4 w-2/3"></div>
                <div className="flex justify-between">
                  <div className="h-3 bg-gray-200 rounded w-1/4"></div>
                  <div className="h-3 bg-gray-200 rounded w-1/6"></div>
                </div>
              </div>
            ))}
          </div>
        ) : gemsData?.gems && gemsData.gems.length > 0 ? (
          <div className="grid grid-cols-1 gap-6 md:grid-cols-2 lg:grid-cols-3">
            {gemsData.gems.map((gem) => (
              <GemCard key={gem.id} gem={gem} />
            ))}
          </div>
        ) : (
          <div className="text-center py-12 card">
            <CubeIcon className="mx-auto h-12 w-12 text-gray-400" />
            <h3 className="mt-2 text-sm font-medium text-gray-900">No gems found</h3>
            <p className="mt-1 text-sm text-gray-500">
              Get started by creating your first gem.
            </p>
            <div className="mt-6">
              <Link to="/create-gem" className="btn-primary">
                Create Gem
              </Link>
            </div>
          </div>
        )}
      </section>

      {/* Quick Actions */}
      <section className="bg-gradient-to-r from-ruby-50 to-gem-50 rounded-xl p-8">
        <h2 className="text-2xl font-bold text-gray-900 mb-6">Quick Actions</h2>
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
          <Link
            to="/create-gem"
            className="flex items-center p-4 bg-white rounded-lg shadow-sm hover:shadow-md transition-shadow"
          >
            <CubeIcon className="h-8 w-8 text-ruby-600 mr-3" />
            <div>
              <p className="font-medium text-gray-900">Create Gem</p>
              <p className="text-sm text-gray-500">Build a new package</p>
            </div>
          </Link>
          
          <Link
            to="/marketplace"
            className="flex items-center p-4 bg-white rounded-lg shadow-sm hover:shadow-md transition-shadow"
          >
            <EyeIcon className="h-8 w-8 text-blue-600 mr-3" />
            <div>
              <p className="font-medium text-gray-900">Browse Gems</p>
              <p className="text-sm text-gray-500">Explore marketplace</p>
            </div>
          </Link>
          
          <Link
            to="/sandbox"
            className="flex items-center p-4 bg-white rounded-lg shadow-sm hover:shadow-md transition-shadow"
          >
            <CalendarIcon className="h-8 w-8 text-green-600 mr-3" />
            <div>
              <p className="font-medium text-gray-900">Launch Sandbox</p>
              <p className="text-sm text-gray-500">Test environments</p>
            </div>
          </Link>
          
          <Link
            to="/benchmarks"
            className="flex items-center p-4 bg-white rounded-lg shadow-sm hover:shadow-md transition-shadow"
          >
            <ArrowTrendingUpIcon className="h-8 w-8 text-purple-600 mr-3" />
            <div>
              <p className="font-medium text-gray-900">Run Benchmarks</p>
              <p className="text-sm text-gray-500">Performance testing</p>
            </div>
          </Link>
        </div>
      </section>
    </div>
  );
}

export default Dashboard; 