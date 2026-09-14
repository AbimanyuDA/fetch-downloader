'use client';

import dynamic from 'next/dynamic';

const MainApp = dynamic(() => import('@/components/MainApp'), {
  ssr: false,
  loading: () => (
    <div className="min-h-screen bg-[#090a0f] flex items-center justify-center">
      <div className="w-10 h-10 border-2 border-indigo-500 border-t-transparent rounded-full animate-spin" />
    </div>
  ),
});

export default function Page() {
  return <MainApp />;
}
