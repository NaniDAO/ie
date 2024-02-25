"use client";
import { useAccount } from "wagmi";

const versions: {
  [key: number]: string;
} = {
  1: "1.0.0",
  42161: "1.0.1 (nightly)",
};

export const Version = () => {
  const { chain } = useAccount();

  return <span>{`[ Version ${versions[chain ? chain.id : 1]} ]`}</span>;
};
