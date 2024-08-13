const explorerUrls: {
  [chainId: number]: string;
} = {
  1: "https://etherscan.io",
  42161: "https://arbiscan.io/",
  10: "https://optimistic.etherscan.io",
  8453: "https://basescan.org/",
};

export const getExplorerBaseUrl = (chainId: number): string => {
  const baseUrl = explorerUrls[chainId];

  if (!baseUrl) {
    throw new Error(`Missing explorer url for chain ${chainId}`);
  }

  return baseUrl;
};

export const getExplorerTxUrl = (chainId: number, txHash: string): string => {
  return `${getExplorerBaseUrl(chainId)}/tx/${txHash}`;
};
