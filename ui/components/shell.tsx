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
import { IntentsEngineAbi } from "../lib/abi/IntentsEngineAbi";
import { ETH_ADDRESS, IE_ADDRESS } from "../lib/constants";
import {
  erc20Abi,
  isAddress,
  isAddressEqual,
  maxUint256,
  parseEther,
} from "viem";
import { mainnet } from "viem/chains";
import useShellStore from "@/lib/use-shell-store";
import { ShellHistory } from "./shell-history";

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
  const client = usePublicClient();

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
    addLine(<p className="text-[red]">{error.message}</p>);
  };

  async function onSubmit({ command }: z.infer<typeof formSchema>) {
    try {
      form.reset();
      addCommand({ chainId: chain?.id, user: name ?? address, command });
      if (!client) throw new Error("No client available");
      if (!address) throw new Error("No wallet connected");

      const regex = /(\d+(\.\d+)?)\s*eth/i;
      const match = command.match(regex);
      let value = 0n; // Default value if no match is found

      if (match && match[1]) {
        // Convert the matched value to a number
        value = parseEther(match[1]);
      }

      console.log({ command, value });

      const preview = await client.readContract({
        address: IE_ADDRESS,
        abi: IntentsEngineAbi,
        functionName: "previewCommand",
        args: [command],
      });

      addLine(<p>Preview: {serialize(preview)}</p>);

      if (!isAddressEqual(preview[2], ETH_ADDRESS)) {
        // consent to spend tokens
        const allowance = await client.readContract({
          address: preview[2],
          abi: erc20Abi,
          functionName: "allowance",
          args: [address, IE_ADDRESS],
        });

        console.log({ allowance });

        if (allowance < preview[1]) {
          // we do a lil approve dance
          const approveTxHash = await writeContractAsync({
            address: preview[2],
            abi: erc20Abi,
            functionName: "approve",
            args: [IE_ADDRESS, maxUint256],
          });

          addLine(<p>Approve TX Hash: {approveTxHash}</p>);

          const allowanceReceipt = await client.waitForTransactionReceipt({
            hash: approveTxHash,
            confirmations: 1,
          });

          addLine(<p>Allowance Set. Receipt: {serialize(allowanceReceipt)}</p>);
        }
      }

      const commandTxHash = await writeContractAsync({
        address: IE_ADDRESS,
        abi: IntentsEngineAbi,
        functionName: "command",
        value,
        args: [command],
      });

      addLine(<p>Command TX Hash: {commandTxHash}</p>);

      const commandReceipt = await client.waitForTransactionReceipt({
        hash: commandTxHash,
        confirmations: 1,
      });

      addLine(
        <p>Command Executed. Receipt: {JSON.stringify(commandReceipt)}</p>,
      );
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
                    className="min-w-3/4 bg-black text-white focus:outline-none w-full"
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
