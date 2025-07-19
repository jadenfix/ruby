import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';

export interface Gem {
  id: number;
  name: string;
  version: string;
  description: string;
  homepage?: string;
  license?: string;
  downloads: number;
  rating: number;
  created_at: string;
  updated_at: string;
  ratings_count: number;
  badges_count: number;
}

export interface CVE {
  id: string;
  title: string;
  description: string;
  severity: 'low' | 'medium' | 'high' | 'critical';
  status: 'active' | 'patched';
}

export interface Benchmark {
  gem_name: string;
  operations: {
    string_operations: Record<string, number>;
    array_operations: Record<string, number>;
    hash_operations: Record<string, number>;
  };
  timestamp: string;
}

interface GemContextType {
  gems: Gem[];
  selectedGem: Gem | null;
  cveData: CVE[];
  benchmarkData: Benchmark | null;
  loading: boolean;
  error: string | null;
  fetchGems: () => Promise<void>;
  selectGem: (gem: Gem) => void;
  fetchCVE: (gemName: string) => Promise<void>;
  fetchBenchmark: (gemName: string) => Promise<void>;
}

const GemContext = createContext<GemContextType | undefined>(undefined);

export const useGemContext = () => {
  const context = useContext(GemContext);
  if (!context) {
    throw new Error('useGemContext must be used within a GemProvider');
  }
  return context;
};

interface GemProviderProps {
  children: ReactNode;
}

export const GemProvider: React.FC<GemProviderProps> = ({ children }) => {
  const [gems, setGems] = useState<Gem[]>([]);
  const [selectedGem, setSelectedGem] = useState<Gem | null>(null);
  const [cveData, setCveData] = useState<CVE[]>([]);
  const [benchmarkData, setBenchmarkData] = useState<Benchmark | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const API_BASE = 'http://localhost:4567';
  const API_TOKEN = 'test-token';

  const fetchGems = async () => {
    setLoading(true);
    setError(null);
    try {
      const response = await fetch(`${API_BASE}/gems`, {
        headers: {
          'Authorization': `Bearer ${API_TOKEN}`,
        },
      });
      
      if (!response.ok) {
        throw new Error('Failed to fetch gems');
      }
      
      const data = await response.json();
      const transformedGems = data.gems.map((gem: any) => ({
        ...gem,
        downloads: gem.downloads || 0,
        rating: gem.rating || 0,
        ratings_count: gem.ratings_count || 0,
        badges_count: gem.badges_count || 0,
      }));
      setGems(transformedGems);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Unknown error');
      console.error('API Error:', err);
      setGems([
        {
          id: 1,
          name: 'rails',
          version: '7.0.4',
          description: 'Web framework for Ruby',
          downloads: 15000000,
          rating: 4.8,
          created_at: '2025-07-19T14:11:24-07:00',
          updated_at: '2025-07-19T14:11:24-07:00',
          ratings_count: 1250,
          badges_count: 3,
        },
        {
          id: 2,
          name: 'sinatra',
          version: '2.2.0',
          description: 'Lightweight web framework',
          downloads: 8500000,
          rating: 4.6,
          created_at: '2025-07-19T14:13:39-07:00',
          updated_at: '2025-07-19T14:13:39-07:00',
          ratings_count: 890,
          badges_count: 2,
        },
        {
          id: 3,
          name: 'nokogiri',
          version: '1.13.9',
          description: 'HTML/XML parser for Ruby',
          downloads: 12000000,
          rating: 4.7,
          created_at: '2025-07-19T14:15:00-07:00',
          updated_at: '2025-07-19T14:15:00-07:00',
          ratings_count: 1100,
          badges_count: 4,
        },
      ]);
    } finally {
      setLoading(false);
    }
  };

  const selectGem = (gem: Gem) => {
    setSelectedGem(gem);
  };

  const fetchCVE = async (gemName: string) => {
    setLoading(true);
    try {
      const mockCVE: CVE[] = [
        {
          id: 'CVE-2023-1234',
          title: 'SQL Injection Vulnerability (FIXED)',
          description: 'A SQL injection vulnerability that has been patched in recent versions.',
          severity: 'high',
          status: 'patched',
        },
      ];
      setCveData(mockCVE);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to fetch CVE data');
    } finally {
      setLoading(false);
    }
  };

  const fetchBenchmark = async (gemName: string) => {
    setLoading(true);
    try {
      const mockBenchmark: Benchmark = {
        gem_name: gemName,
        operations: {
          string_operations: {
            'string_interpolation': 6126877.7,
            'string_concat': 1961456.4,
            'string_format': 1117765.0,
          },
          array_operations: {
            'array_map': 138801.6,
            'array_select': 120667.7,
            'array_reduce': 105406.9,
          },
          hash_operations: {
            'hash_access': 12328844.9,
            'hash_merge': 2497960.3,
            'hash_transform': 1860951.6,
          },
        },
        timestamp: new Date().toISOString(),
      };
      setBenchmarkData(mockBenchmark);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to fetch benchmark data');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchGems();
  }, []);

  const value: GemContextType = {
    gems,
    selectedGem,
    cveData,
    benchmarkData,
    loading,
    error,
    fetchGems,
    selectGem,
    fetchCVE,
    fetchBenchmark,
  };

  return (
    <GemContext.Provider value={value}>
      {children}
    </GemContext.Provider>
  );
};
