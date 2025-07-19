import React from 'react';
import { GemProvider } from './context/GemContext';
import Dashboard from './components/Dashboard';
import './App.css';

function App() {
  return (
    <GemProvider>
      <Dashboard />
    </GemProvider>
  );
}

export default App;
