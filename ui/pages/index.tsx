import { useConnectModal } from "@rainbow-me/rainbowkit";
import type { NextPage } from "next";
import { useAccount } from "wagmi";
import { Shell } from "../components/shell";

const Home: NextPage = () => {
  const { isConnected } = useAccount();
  const { openConnectModal, connectModalOpen } = useConnectModal();

  return (
    <main className="font-mono min-h-screen min-w-screen bg-black">
      {isConnected ? (
        <Shell />
      ) : (
        <div className="flex flex-row space-x-1 text-white animate-pulse hover:animate-none">
          <p className="uppercase">{"unknown:\\user>"}</p>
          <button className="" onClick={openConnectModal}>
            {connectModalOpen ? "Connecting" : "Click here to connect"}
          </button>
        </div>
      )}
    </main>
  );
};

export default Home;
