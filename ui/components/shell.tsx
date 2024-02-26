"use client";
import { useForm } from "react-hook-form";
import { Form, FormControl, FormField, FormItem } from "./ui/form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import {
  serialize,
  useAccount,
  useEnsName,
  usePublicClient,
  useWriteContract,
} from "wagmi";
import { ETH_ADDRESS, IE_ADDRESS } from "../lib/constants";
import {
  erc20Abi,
  isAddress,
  isAddressEqual,
  maxUint256,
  zeroAddress,
} from "viem";
import { arbitrum, mainnet } from "viem/chains";
import useShellStore from "@/lib/use-shell-store";
import { ShellHistory } from "./shell-history";
import { cn } from "@/lib/utils";
import { IntentsEngineAbi } from "@/lib/abi/IntentsEngineAbi";
import { IntentsEngineAbiArb } from "@/lib/abi/IntentsEngineAbiArb";

const formSchema = z.object({
  command: z.string().min(2),
});

const createId = (chainId?: number, user?: string) => {
  return (
    <p className="uppercase">
      {chainId ? chainId : <span className="animate-spin">☼</span>}:\
      {!user ? (
        <span className="animate-spin">☼</span>
      ) : !isAddress(user) ? (
        user.slice(0, -4)
      ) : (
        user
      )}
      {">"}
    </p>
  );
};

export const Shell = () => {
  const form = useForm<z.infer<typeof formSchema>>({
    resolver: zodResolver(formSchema),
    defaultValues: {
      command: "",
    },
  });
  const { address, isConnected, chain } = useAccount();
  const { data: name } = useEnsName({
    address,
    chainId: mainnet.id,
  });
  const { writeContractAsync } = useWriteContract();

  const client = usePublicClient({
    chainId: chain ? chain.id : mainnet.id,
  });

  const addLine = useShellStore((state) => state.addLine);

  const addCommand = ({
    chainId,
    user,
    command,
  }: {
    chainId?: number;
    user?: string;
    command: string;
  }) => {
    addLine(
      <div className="flex flex-row items-center space-x-1">
        {createId(chainId, user)}
        <p>{command}</p>
      </div>,
    );
  };

  const addError = (error: Error) => {
    addLine(<p className="text-[orange]">{error.message}</p>);
  };

  const addPreview = (preview: any) => {
    addLine(<p>Preview: {serialize(preview)}</p>);
  };

  async function handleArbCommand(command: string) {
    if (!client) throw new Error("No client available");
    if (!address) throw new Error("No wallet connected");

    const ieAddress = IE_ADDRESS[arbitrum.id];

    let value = 0n;

    const preview = await client.readContract({
      address: ieAddress,
      abi: IntentsEngineAbiArb,
      functionName: "previewCommand",
      args: [command],
    });
    const previewedToken = preview[3];

    addPreview(preview);

    if (isAddressEqual(previewedToken, zeroAddress)) {
      // invalid token
      throw new Error(
        "This token is not supported by the Intents Engine. Did you misspell the token symbol?",
      );
    }

    if (isAddressEqual(previewedToken, ETH_ADDRESS)) {
      // sending ether directly
      value = preview[1];
    } else {
      // consent to spend tokens
      const allowance = await client.readContract({
        address: previewedToken,
        abi: erc20Abi,
        functionName: "allowance",
        args: [address, ieAddress],
      });

      if (allowance < preview[1]) {
        // we do a lil approve dance
        const approveTxHash = await writeContractAsync({
          address: previewedToken,
          abi: erc20Abi,
          functionName: "approve",
          args: [ieAddress, maxUint256],
        });

        addLine(
          <p>
            Approve TX Hash:{" "}
            <a
              href={`https://etherscan.io/tx/${approveTxHash}`}
              target="_blank"
              rel="noreferrer"
            >
              {approveTxHash}
            </a>
          </p>,
        );

        const allowanceReceipt = await client.waitForTransactionReceipt({
          hash: approveTxHash,
          confirmations: 1,
        });

        addLine(<p>Allowance Set. Receipt: {serialize(allowanceReceipt)}</p>);
      }
    }

    const commandTxHash = await writeContractAsync({
      address: ieAddress,
      abi: IntentsEngineAbiArb,
      functionName: "command",
      value,
      args: [command],
    });

    addLine(
      <p>
        Command TX Hash:{" "}
        <a
          href={`https://etherscan.io/tx/${commandTxHash}`}
          target="_blank"
          rel="noreferrer"
        >
          {commandTxHash}
        </a>
      </p>,
    );

    const commandReceipt = await client.waitForTransactionReceipt({
      hash: commandTxHash,
      confirmations: 1,
    });

    addLine(<p>Command Executed. Receipt: {serialize(commandReceipt)}</p>);
  }

  async function handleMainnetCommand(command: string) {
    if (!client) throw new Error("No client available");
    if (!address) throw new Error("No wallet connected");

    const ieAddress = IE_ADDRESS[mainnet.id];

    let value = 0n;

    const preview = await client.readContract({
      address: ieAddress,
      abi: IntentsEngineAbi,
      functionName: "previewCommand",
      args: [command],
    });

    addLine(<p>Preview: {serialize(preview)}</p>);

    if (isAddressEqual(preview[2], zeroAddress)) {
      // invalid token
      throw new Error(
        "This token is not supported by the Intents Engine. Did you misspell the token symbol?",
      );
    }

    if (isAddressEqual(preview[2], ETH_ADDRESS)) {
      // sending ether directly
      value = preview[1];
    } else {
      // consent to spend tokens
      const allowance = await client.readContract({
        address: preview[2],
        abi: erc20Abi,
        functionName: "allowance",
        args: [address, ieAddress],
      });

      if (allowance < preview[1]) {
        // we do a lil approve dance
        const approveTxHash = await writeContractAsync({
          address: preview[2],
          abi: erc20Abi,
          functionName: "approve",
          args: [ieAddress, maxUint256],
        });

        addLine(
          <p>
            Approve TX Hash:{" "}
            <a
              href={`https://etherscan.io/tx/${approveTxHash}`}
              target="_blank"
              rel="noreferrer"
            >
              {approveTxHash}
            </a>
          </p>,
        );

        const allowanceReceipt = await client.waitForTransactionReceipt({
          hash: approveTxHash,
          confirmations: 1,
        });

        addLine(<p>Allowance Set. Receipt: {serialize(allowanceReceipt)}</p>);
      }
    }

    const commandTxHash = await writeContractAsync({
      address: ieAddress,
      abi: IntentsEngineAbi,
      functionName: "command",
      value,
      args: [command],
    });

    addLine(
      <p>
        Command TX Hash:{" "}
        <a
          href={`https://etherscan.io/tx/${commandTxHash}`}
          target="_blank"
          rel="noreferrer"
        >
          {commandTxHash}
        </a>
      </p>,
    );

    const commandReceipt = await client.waitForTransactionReceipt({
      hash: commandTxHash,
      confirmations: 1,
    });

    addLine(<p>Command Executed. Receipt: {serialize(commandReceipt)}</p>);
  }

  async function onSubmit({ command }: z.infer<typeof formSchema>) {
    try {
      form.reset();
      addCommand({ chainId: chain?.id, user: name ?? address, command });
      if (!client) throw new Error("No client available");
      if (!address) throw new Error("No wallet connected");
      if (!chain) throw new Error("No chain connected");

      switch (chain.id) {
        case arbitrum.id:
          await handleArbCommand(command);
          break;
        case mainnet.id:
          await handleMainnetCommand(command);
          break;
        default:
          throw new Error("Unsupported chain");
      }
    } catch (error) {
      console.error(error);
      error instanceof Error
        ? addError(error)
        : addError(new Error("Unknown error"));
    }
  }

  const id = createId(chain?.id, name ?? address);

  if (!isConnected || !address || !chain) return null;

  return (
    <div>
      <ShellHistory />
      <Form {...form}>
        <form
          onSubmit={form.handleSubmit(onSubmit)}
          className="mb-2 w-screen flex flex-row"
        >
          <FormField
            control={form.control}
            name="command"
            render={({ field }) => (
              <FormItem className="w-full flex flex-row items-center space-x-1 space-y-0">
                {id}
                <FormControl>
                  <input
                    className={cn(
                      "command-prompt-input",
                      " min-w-3/4 focus:outline-none w-full",
                    )}
                    {...field}
                  />
                </FormControl>
              </FormItem>
            )}
          />
          <button className="hidden" type="submit" disabled={!client}>
            Submit
          </button>
        </form>
      </Form>
    </div>
  );
};
