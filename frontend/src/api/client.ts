import axios, { AxiosInstance, AxiosError, AxiosResponse } from 'axios';
import {
  ApiClientConfig,
  ApiError,
  Gem,
  GemsResponse,
  GemResponse,
  CreateGemRequest,
  UpdateGemRequest,
  Rating,
  RatingsResponse,
  RatingResponse,
  CreateRatingRequest,
  Badge,
  BadgesResponse,
  BadgeResponse,
  CreateBadgeRequest,
  HealthResponse,
} from '../types';

class ApiClient {
  private client: AxiosInstance;
  private apiToken?: string;

  constructor(config: ApiClientConfig) {
    this.apiToken = config.apiToken;
    
    this.client = axios.create({
      baseURL: config.baseURL,
      timeout: config.timeout || 10000,
      headers: {
        'Content-Type': 'application/json',
      },
    });

    // Request interceptor to add auth token
    this.client.interceptors.request.use(
      (config) => {
        if (this.apiToken) {
          config.headers.Authorization = `Bearer ${this.apiToken}`;
        }
        return config;
      },
      (error) => Promise.reject(error)
    );

    // Response interceptor for error handling
    this.client.interceptors.response.use(
      (response: AxiosResponse) => response,
      (error: AxiosError) => {
        const apiError: ApiError = {
          error: 'An unexpected error occurred',
          status: error.response?.status,
        };

        if (error.response?.data) {
          const data = error.response.data as any;
          apiError.error = data.error || data.message || apiError.error;
          apiError.details = data.details;
        } else if (error.message) {
          apiError.error = error.message;
        }

        return Promise.reject(apiError);
      }
    );
  }

  // Update API token
  setApiToken(token: string) {
    this.apiToken = token;
  }

  // Health Check
  async checkHealth(): Promise<HealthResponse> {
    const response = await this.client.get<HealthResponse>('/health');
    return response.data;
  }

  // Gems API
  async getGems(params?: {
    limit?: number;
    search?: string;
    offset?: number;
  }): Promise<GemsResponse> {
    const response = await this.client.get<GemsResponse>('/gems', { params });
    return response.data;
  }

  async getGem(id: number): Promise<GemResponse> {
    const response = await this.client.get<GemResponse>(`/gems/${id}`);
    return response.data;
  }

  async createGem(gemData: CreateGemRequest): Promise<GemResponse> {
    const response = await this.client.post<GemResponse>('/gems', gemData);
    return response.data;
  }

  async updateGem(id: number, gemData: UpdateGemRequest): Promise<GemResponse> {
    const response = await this.client.put<GemResponse>(`/gems/${id}`, gemData);
    return response.data;
  }

  async deleteGem(id: number): Promise<{ message: string }> {
    const response = await this.client.delete(`/gems/${id}`);
    return response.data;
  }

  // Ratings API
  async getRatings(gemId: number): Promise<RatingsResponse> {
    const response = await this.client.get<RatingsResponse>(`/gems/${gemId}/ratings`);
    return response.data;
  }

  async createRating(gemId: number, ratingData: CreateRatingRequest): Promise<RatingResponse> {
    const response = await this.client.post<RatingResponse>(`/gems/${gemId}/ratings`, ratingData);
    return response.data;
  }

  // Badges API
  async getBadges(): Promise<BadgesResponse> {
    const response = await this.client.get<BadgesResponse>('/badges');
    return response.data;
  }

  async createBadge(badgeData: CreateBadgeRequest): Promise<BadgeResponse> {
    const response = await this.client.post<BadgeResponse>('/badges', badgeData);
    return response.data;
  }

  // CVE Scanner
  async scanGem(gemName: string): Promise<any> {
    const response = await this.client.post('/scan', { gem_name: gemName });
    return response.data;
  }

  // Dashboard Stats (computed from existing endpoints)
  async getDashboardStats(): Promise<{
    totalGems: number;
    totalRatings: number;
    totalBadges: number;
    averageRating: number;
    topRatedGems: Gem[];
    recentGems: Gem[];
    popularGems: Gem[];
  }> {
    const [gemsResponse, badgesResponse] = await Promise.all([
      this.getGems({ limit: 100 }), // Get more gems for stats
      this.getBadges(),
    ]);

    const gems = gemsResponse.gems;
    const badges = badgesResponse.badges;

    // Calculate total ratings
    const totalRatings = gems.reduce((sum, gem) => sum + gem.ratings_count, 0);

    // Calculate average rating
    const totalRatingPoints = gems.reduce((sum, gem) => sum + (gem.rating * gem.ratings_count), 0);
    const averageRating = totalRatings > 0 ? totalRatingPoints / totalRatings : 0;

    // Sort gems for different categories
    const topRatedGems = [...gems]
      .filter(gem => gem.ratings_count > 0)
      .sort((a, b) => b.rating - a.rating)
      .slice(0, 5);

    const recentGems = [...gems]
      .sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime())
      .slice(0, 5);

    const popularGems = [...gems]
      .sort((a, b) => b.downloads - a.downloads)
      .slice(0, 5);

    return {
      totalGems: gems.length,
      totalRatings,
      totalBadges: badges.length,
      averageRating,
      topRatedGems,
      recentGems,
      popularGems,
    };
  }
}

// Create and export a singleton instance
const apiClient = new ApiClient({
  baseURL: process.env.REACT_APP_API_URL || 'http://localhost:4567',
  apiToken: process.env.REACT_APP_API_TOKEN || 'test-token',
  timeout: 10000,
});

export default apiClient;

// Export the class for testing or custom instances
export { ApiClient };

// Export convenience hooks for React Query
export const apiKeys = {
  health: () => ['health'] as const,
  gems: () => ['gems'] as const,
  gem: (id: number) => ['gems', id] as const,
  ratings: (gemId: number) => ['gems', gemId, 'ratings'] as const,
  badges: () => ['badges'] as const,
  dashboardStats: () => ['dashboard-stats'] as const,
};

// Utility functions for error handling
export const isApiError = (error: any): error is ApiError => {
  return error && typeof error.error === 'string';
};

export const getErrorMessage = (error: unknown): string => {
  if (isApiError(error)) {
    return error.error;
  }
  if (error instanceof Error) {
    return error.message;
  }
  return 'An unexpected error occurred';
};

// Format functions for display
export const formatGemName = (gem: Gem): string => {
  return `${gem.name} (${gem.version})`;
};

export const formatRating = (rating: number): string => {
  return rating.toFixed(1);
};

export const formatDownloads = (downloads: number): string => {
  if (downloads >= 1000000) {
    return `${(downloads / 1000000).toFixed(1)}M`;
  }
  if (downloads >= 1000) {
    return `${(downloads / 1000).toFixed(1)}K`;
  }
  return downloads.toString();
};

export const formatDate = (dateString: string): string => {
  const date = new Date(dateString);
  return date.toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
  });
};

export const formatDateTime = (dateString: string): string => {
  const date = new Date(dateString);
  return date.toLocaleString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  });
}; 