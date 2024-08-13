"use client";
import { useAccount } from "wagmi";

const versions: {
  [key: number]: string;
} = {
  1: "2.0.0",
  42161: "2.0.0 (nightly)",
  10: "2.0.0",
};

export const Version = () => {
  const { chain } = useAccount();

  return <span>{`[ Version ${versions[chain ? chain.id : 1]} ]`}</span>;
};
