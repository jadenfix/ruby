import React, { useState } from 'react';
import { Link, useLocation } from 'react-router-dom';
import {
  HomeIcon,
  CubeIcon,
  PlusCircleIcon,
  BeakerIcon,
  ChartBarIcon,
  Bars3Icon,
  XMarkIcon,
} from '@heroicons/react/24/outline';
import { useQuery } from 'react-query';
import apiClient, { apiKeys } from '../api/client';

interface LayoutProps {
  children: React.ReactNode;
}

const navigation = [
  { name: 'Dashboard', href: '/dashboard', icon: HomeIcon },
  { name: 'Marketplace', href: '/marketplace', icon: CubeIcon },
  { name: 'Create Gem', href: '/create-gem', icon: PlusCircleIcon },
  { name: 'Sandbox', href: '/sandbox', icon: BeakerIcon },
  { name: 'Benchmarks', href: '/benchmarks', icon: ChartBarIcon },
];

function Layout({ children }: LayoutProps) {
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const location = useLocation();

  // Health check query to show API status
  const { data: health, isError: healthError } = useQuery({
    queryKey: apiKeys.health(),
    queryFn: () => apiClient.checkHealth(),
    refetchInterval: 30000, // Check every 30 seconds
  });

  return (
    <div className="flex h-screen bg-gray-50">
      {/* Mobile sidebar overlay */}
      {sidebarOpen && (
        <div className="fixed inset-0 z-40 flex lg:hidden">
          <div className="fixed inset-0 bg-gray-600 bg-opacity-75" onClick={() => setSidebarOpen(false)} />
          <div className="relative flex w-full max-w-xs flex-1 flex-col bg-white">
            <div className="absolute top-0 right-0 -mr-12 pt-2">
              <button
                type="button"
                className="ml-1 flex h-10 w-10 items-center justify-center rounded-full focus:outline-none focus:ring-2 focus:ring-inset focus:ring-white"
                onClick={() => setSidebarOpen(false)}
              >
                <XMarkIcon className="h-6 w-6 text-white" />
              </button>
            </div>
            <SidebarContent />
          </div>
        </div>
      )}

      {/* Desktop sidebar */}
      <div className="hidden lg:fixed lg:inset-y-0 lg:flex lg:w-64 lg:flex-col">
        <SidebarContent />
      </div>

      {/* Main content */}
      <div className="flex flex-1 flex-col lg:pl-64">
        {/* Top navigation */}
        <div className="sticky top-0 z-10 flex h-16 shrink-0 items-center gap-x-4 border-b border-gray-200 bg-white px-4 shadow-sm sm:gap-x-6 sm:px-6 lg:px-8">
          <button
            type="button"
            className="-m-2.5 p-2.5 text-gray-700 lg:hidden"
            onClick={() => setSidebarOpen(true)}
          >
            <Bars3Icon className="h-6 w-6" />
          </button>

          {/* Separator */}
          <div className="h-6 w-px bg-gray-200 lg:hidden" />

          <div className="flex flex-1 gap-x-4 self-stretch lg:gap-x-6">
            <div className="flex flex-1 items-center">
              <h1 className="text-lg font-semibold text-gray-900">
                {navigation.find(item => item.href === location.pathname)?.name || 'GemHub'}
              </h1>
            </div>
            <div className="flex items-center gap-x-4 lg:gap-x-6">
              {/* API Status */}
              <div className="flex items-center gap-x-2">
                <div className={`h-2 w-2 rounded-full ${
                  healthError ? 'bg-red-500' : health ? 'bg-green-500' : 'bg-yellow-500'
                }`} />
                <span className="text-sm text-gray-500">
                  API {healthError ? 'Offline' : health ? 'Online' : 'Checking...'}
                </span>
              </div>
            </div>
          </div>
        </div>

        {/* Page content */}
        <main className="flex-1 overflow-auto">
          <div className="px-4 py-8 sm:px-6 lg:px-8">
            {children}
          </div>
        </main>
      </div>
    </div>
  );

  function SidebarContent() {
    return (
      <div className="flex grow flex-col gap-y-5 overflow-y-auto border-r border-gray-200 bg-white px-6 pb-4">
        {/* Logo */}
        <div className="flex h-16 shrink-0 items-center">
          <div className="flex items-center gap-x-3">
            <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-gradient-to-br from-ruby-500 to-gem-500">
              <CubeIcon className="h-5 w-5 text-white" />
            </div>
            <span className="text-xl font-bold gradient-text">GemHub</span>
          </div>
        </div>

        {/* Navigation */}
        <nav className="flex flex-1 flex-col">
          <ul role="list" className="flex flex-1 flex-col gap-y-7">
            <li>
              <ul role="list" className="-mx-2 space-y-1">
                {navigation.map((item) => {
                  const current = location.pathname === item.href;
                  return (
                    <li key={item.name}>
                      <Link
                        to={item.href}
                        className={`nav-link ${
                          current ? 'nav-link-active' : 'nav-link-inactive'
                        }`}
                      >
                        <item.icon className="h-5 w-5 mr-3" />
                        {item.name}
                      </Link>
                    </li>
                  );
                })}
              </ul>
            </li>

            {/* API Status */}
            <li className="mt-auto">
              <div className="rounded-lg bg-gray-50 p-4">
                <div className="flex items-center gap-x-3">
                  <div className={`h-3 w-3 rounded-full ${
                    healthError ? 'bg-red-500' : health ? 'bg-green-500 animate-pulse' : 'bg-yellow-500'
                  }`} />
                  <div>
                    <p className="text-sm font-medium text-gray-900">
                      API Status
                    </p>
                    <p className="text-xs text-gray-500">
                      {healthError 
                        ? 'Disconnected' 
                        : health 
                          ? `Connected (${health.status})`
                          : 'Connecting...'
                      }
                    </p>
                  </div>
                </div>
              </div>
            </li>
          </ul>
        </nav>
      </div>
    );
  }
}

export default Layout; 