"use client";
import { useConnectModal } from "@rainbow-me/rainbowkit";
import { useAccount, useSwitchChain } from "wagmi";

export const Account = () => {
  const { isConnected, isReconnecting, chain } = useAccount();
  const { chains, switchChain } = useSwitchChain();
  const { openConnectModal, connectModalOpen } = useConnectModal();

  if (!isConnected)
    return (
      <button
        className="italic hover:underline focus:outline-none"
        onClick={openConnectModal}
      >
        Connect
      </button>
    );

  if (connectModalOpen) return <p className="animate-spin">⧗</p>;

  if (isReconnecting) return <p>Reconnecting...</p>;

  return (
    <p>
      Connected to{" "}
      <select
        defaultValue={chain?.id}
        className="text-black"
        onChange={(e) => switchChain({ chainId: Number(e.target.value) })}
      >
        {chains.map((chain) => (
          <option key={chain.id} value={chain.id}>
            {chain.name}
          </option>
        ))}
      </select>
    </p>
  );
};
