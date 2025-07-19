// API Response Types
export interface ApiResponse<T = any> {
  data?: T;
  error?: string;
  status?: number;
}

// Gem Types
export interface Gem {
  id: number;
  name: string;
  version: string;
  description?: string;
  homepage?: string;
  license?: string;
  downloads: number;
  rating: number;
  created_at: string;
  updated_at: string;
  ratings_count: number;
  badges_count: number;
}

export interface GemsResponse {
  gems: Gem[];
}

export interface GemResponse {
  gem: Gem;
}

export interface CreateGemRequest {
  name: string;
  version: string;
  description?: string;
  homepage?: string;
  license?: string;
}

export interface UpdateGemRequest {
  name?: string;
  version?: string;
  description?: string;
  homepage?: string;
  license?: string;
}

// Rating Types
export interface Rating {
  id: number;
  gem_id: number;
  score: number;
  comment?: string;
  user_id: string;
  created_at: string;
}

export interface RatingsResponse {
  ratings: Rating[];
}

export interface RatingResponse {
  rating: Rating;
}

export interface CreateRatingRequest {
  score: number;
  comment?: string;
  user_id: string;
}

// Badge Types
export type BadgeType = 'security' | 'performance' | 'quality' | 'popularity' | 'maintenance';

export interface Badge {
  id: number;
  gem_id: number;
  type: BadgeType;
  name: string;
  description?: string;
  created_at: string;
}

export interface BadgesResponse {
  badges: Badge[];
}

export interface BadgeResponse {
  badge: Badge;
}

export interface CreateBadgeRequest {
  gem_id: number;
  type: BadgeType;
  name: string;
  description?: string;
}

// Health Check
export interface HealthResponse {
  status: string;
  timestamp: string;
}

// Error Types
export interface ApiError {
  error: string;
  status?: number;
  details?: Record<string, string>;
}

// UI State Types
export interface LoadingState {
  isLoading: boolean;
  error?: string;
}

export interface PaginationState {
  page: number;
  limit: number;
  total: number;
  hasMore: boolean;
}

export interface FilterState {
  search: string;
  sortBy: 'name' | 'rating' | 'downloads' | 'created_at';
  sortOrder: 'asc' | 'desc';
  badgeFilter?: BadgeType;
}

// Component Props Types
export interface GemCardProps {
  gem: Gem;
  onRate?: (gemId: number, rating: number, comment?: string) => void;
  onView?: (gemId: number) => void;
}

export interface RatingStarProps {
  rating: number;
  size?: 'sm' | 'md' | 'lg';
  interactive?: boolean;
  onChange?: (rating: number) => void;
}

export interface BadgeProps {
  badge: Badge;
  size?: 'sm' | 'md' | 'lg';
}

export interface SearchBarProps {
  value: string;
  onChange: (value: string) => void;
  placeholder?: string;
}

export interface FilterPanelProps {
  filters: FilterState;
  onChange: (filters: FilterState) => void;
}

// Form Types
export interface GemFormData {
  name: string;
  version: string;
  description: string;
  homepage: string;
  license: string;
}

export interface RatingFormData {
  score: number;
  comment: string;
}

// Navigation Types
export interface NavItem {
  name: string;
  href: string;
  icon?: React.ComponentType<{ className?: string }>;
  current?: boolean;
}

// Dashboard Stats
export interface DashboardStats {
  totalGems: number;
  totalRatings: number;
  totalBadges: number;
  averageRating: number;
  topRatedGems: Gem[];
  recentGems: Gem[];
  popularGems: Gem[];
}

// Toast Notification Types
export interface ToastMessage {
  id: string;
  type: 'success' | 'error' | 'warning' | 'info';
  title: string;
  message?: string;
  duration?: number;
}

// Modal Types
export interface ModalProps {
  isOpen: boolean;
  onClose: () => void;
  title: string;
  children: React.ReactNode;
}

// API Client Configuration
export interface ApiClientConfig {
  baseURL: string;
  apiToken?: string;
  timeout?: number;
}

// Query Keys for React Query
export const QueryKeys = {
  GEMS: ['gems'] as const,
  GEM: (id: number) => ['gem', id] as const,
  RATINGS: (gemId: number) => ['ratings', gemId] as const,
  BADGES: ['badges'] as const,
  HEALTH: ['health'] as const,
  DASHBOARD_STATS: ['dashboard-stats'] as const,
} as const; 