"use client";

import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { WagmiProvider } from "wagmi";
import { mainnet, arbitrum, optimism } from "wagmi/chains";
import {
  Chain,
  getDefaultConfig,
  RainbowKitProvider,
} from "@rainbow-me/rainbowkit";
import { siteConfig } from "@/lib/site";

const ANKR_API_KEY = process.env.NEXT_PUBLIC_ANKR_KEY;

if (!ANKR_API_KEY) {
  throw new Error("Missing ANKR_API_KEY");
}

const chains = [
  {
    ...mainnet,
    rpcUrls: {
      default: {
        http: ["https://rpc.ankr.com/eth/" + ANKR_API_KEY],
        webSocket: ["wss://rpc.ankr.com/eth/ws/" + ANKR_API_KEY],
      },
    },
  },
  {
    ...arbitrum,
    rpcUrls: {
      default: {
        http: ["https://rpc.ankr.com/arbitrum/" + ANKR_API_KEY],
        webSocket: ["wss://rpc.ankr.com/arbitrum/ws/" + ANKR_API_KEY],
      },
    },
  },
  {
    ...optimism,
    rpcUrls: {
      default: {
        http: ["https://rpc.ankr.com/optimism/" + ANKR_API_KEY],
        webSocket: ["wss://rpc.ankr.com/optimism/ws/" + ANKR_API_KEY],
      },
    },
  },
] as const satisfies Chain[];

const config = getDefaultConfig({
  appName: siteConfig.name,
  appDescription: siteConfig.description,
  projectId: process.env.NEXT_PUBLIC_WC_ID!,
  chains,
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
