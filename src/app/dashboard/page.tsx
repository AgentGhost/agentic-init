// src/app/dashboard/page.tsx
'use client';

import React from 'react';
import DashboardWidget from '@/components/DashboardWidget';
import { Box } from '@mui/material';

// Mock fetch function simulating API call to gather widget data
async function fetchDashboardData() {
  // In a real application, this would call a Next.js Route Handler:
  // const res = await fetch('/api/dashboard/metrics');
  // return res.json();
  
  return {
    totalUsers: 15200,
    revenueMTD: "$1.2M",
    openTickets: 45,
    dataFetchTime: new Date().toLocaleTimeString(),
  };
}

/**
 * The main dashboard landing page component.
 * It fetches key metrics and displays them using the DashboardWidget component.
 */
const DashboardPage: React.FC = () => {
  const [metrics, setMetrics] = React.useState<Awaited<ReturnType<typeof fetchDashboardData>> | null>(null);
  const [isLoading, setIsLoading] = React.useState(true);

  React.useEffect(() => {
    async function loadData() {
      try {
        const data = await fetchDashboardData();
        setMetrics(data);
      } catch (error) {
        console.error("Failed to fetch dashboard data:", error);
        setMetrics(null);
      } finally {
        setIsLoading(false);
      }
    }
    loadData();
  }, []);

  if (isLoading) {
    return (
      <Box sx={{ p: 4, textAlign: 'center', minHeight: '50vh' }}>
        <Typography variant="h4">Loading Dashboard Metrics...</Typography>
      </Box>
    );
  }

  if (!metrics) {
    return (
      <Box sx={{ p: 4, textAlign: 'center', minHeight: '50vh' }}>
        <Typography color="error" variant="h4">Error loading data.</Typography>
      </Box>
    );
  }

  return (
    <Box sx={{ p: 4 }}>
      <Typography variant="h3" gutterBottom sx={{ mb: 4 }}>
        🚀 Operational Dashboard Overview
      </Typography>

      {/* Grid of Widgets */}
      <Box 
        sx={{ 
          display: 'flex', 
          flex-wrap: 'wrap', 
          gap: 3, 
          mb: 4', 
          justifyContent: 'space-between' 
        }}
      >
        {/* Widget 1: Total Users */}
        <DashboardWidget 
          title="Total Users" 
          value={metrics.totalUsers} 
          description={`Active users tracked until ${metrics.dataFetchTime}`}
          color="success"
        />
        
        {/* Widget 2: Revenue MTD */}
        <DashboardWidget 
          title="Revenue (MTD)" 
          value={metrics.revenueMTD} 
          description="Month-to-date revenue generated across all channels."
          color="primary"
        />

        {/* Widget 3: Open Tickets */}
        <DashboardWidget 
          title="Open Tickets" 
          value={metrics.openTickets} 
          description="Critical tickets awaiting triage or resolution. (High Priority)"
          color="warning"
        />
      </Box>

      {/* Placeholder for other dashboard sections */}
      <Box sx={{ mt: 6 }}>
        <Typography variant="h4" gutterBottom>
          Recent Activity Feed
        </Typography>
        <p>Detailed charts and activity streams would be integrated here.</p>
      </Box>
    </Box>
  );
};

export default DashboardPage;
export type DashboardMetrics = {
  totalUsers: number;
  revenueMTD: string;
  openTickets: number;
  dataFetchTime: string;
};