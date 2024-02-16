import { ConnectButton } from "@rainbow-me/rainbowkit";
import type { NextPage } from "next";
import Head from "next/head";
import styles from "../styles/Home.module.css";
import { useAccount } from "wagmi";
import { Shell } from "../components/shell";

const Home: NextPage = () => {
  const { isConnected, address, chainId } = useAccount();

  return (
    <div className={"min-h-screen w-screen bg-black"}>
      {isConnected ? <Shell /> : <ConnectButton />}
    </div>
  );
};

export default Home;
