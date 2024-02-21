"use client";

import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { WagmiProvider } from "wagmi";
import { mainnet, sepolia } from "wagmi/chains";
import { getDefaultConfig, RainbowKitProvider } from "@rainbow-me/rainbowkit";
import { siteConfig } from "@/lib/site";

const config = getDefaultConfig({
  appName: siteConfig.name,
  appDescription: siteConfig.description,
  projectId: process.env.NEXT_PUBLIC_WC_ID!,
  chains: [
    mainnet,
    sepolia
  ],
  ssr: true,
});

const client = new QueryClient();

export function Providers({ children }: { children: React.ReactNode }) {
  return (
    <WagmiProvider config={config}>
      <QueryClientProvider client={client}>
        <RainbowKitProvider>{children}</RainbowKitProvider>
      </QueryClientProvider>
    </WagmiProvider>
  );
}
