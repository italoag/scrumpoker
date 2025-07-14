"use client";

import { ReactNode } from "react";
import dynamic from "next/dynamic";

// Componente de loading para mostrar enquanto carrega os providers Web3
const Web3ProvidersLoading = () => (
  <div className="flex items-center justify-center min-h-screen">
    <div className="loading loading-spinner loading-lg"></div>
  </div>
);

// Dynamic import do ScaffoldEthAppWithProviders para evitar SSR
const ScaffoldEthAppWithProviders = dynamic(
  () => import("./ScaffoldEthAppWithProviders").then(mod => ({ default: mod.ScaffoldEthAppWithProviders })),
  {
    ssr: false,
    loading: () => <Web3ProvidersLoading />,
  },
);

export const ClientOnlyWeb3Providers = ({ children }: { children: ReactNode }) => {
  return <ScaffoldEthAppWithProviders>{children}</ScaffoldEthAppWithProviders>;
};
