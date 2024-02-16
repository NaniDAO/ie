import { useForm } from "react-hook-form";
import { Form, FormControl, FormField, FormItem } from "./ui/form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import {
  BaseError,
  useAccount,
  useWaitForTransactionReceipt,
  useWriteContract,
} from "wagmi";
import { IntentsEngineAbi } from "../lib/abi/IntentsEngineAbi";
import { IE_ADDRESS } from "../lib/constants";
import { parseEther } from "viem";

const formSchema = z.object({
  command: z.string().min(2),
});

export const Shell = () => {
  const form = useForm<z.infer<typeof formSchema>>({
    resolver: zodResolver(formSchema),
    defaultValues: {
      command: "",
    },
  });
  const { address, chain } = useAccount();
  const { data: hash, writeContract, isPending, error } = useWriteContract();
  const { isLoading: isConfirming, isSuccess: isConfirmed } =
    useWaitForTransactionReceipt({
      hash,
    });

  async function onSubmit({ command }: z.infer<typeof formSchema>) {
    try {
      const regex = /(\d+(\.\d+)?)\s*eth/i;
      const match = command.match(regex);
      let value = 0n; // Default value if no match is found

      if (match && match[1]) {
        // Convert the matched value to a number
        value = parseEther(match[1]);
      }

      console.log({ command, value });

      if (command.includes("swap")) {
        // approve the router to spend the token
        
      }

      writeContract({
        address: IE_ADDRESS,
        abi: IntentsEngineAbi,
        functionName: "command",
        value,
        args: [command],
      });
    } catch (error) {
      console.error(error);
    }
  }
  const id = (
    <p className="uppercase">
      {chain?.id}:{address}
      {">"}
    </p>
  );
  return (
    <div className="p-1 h-full text-white font-mono">
      <div className="mb-3">
        <p>Nani Intents Shell {"[ Version 1.0.0 ]"}</p>
        <p>(c) 2024 Nani Kotoba DAO LLC. All rights reserved.</p>
        {chain && <p>Connected to {chain.name}.</p>}
      </div>
      <div>
        {chain ? (
          <div>
            <Form {...form}>
              <form
                onSubmit={form.handleSubmit(onSubmit)}
                className="mb-2 flex flex-row"
              >
                <FormField
                  control={form.control}
                  name="command"
                  render={({ field }) => (
                    <FormItem className="flex flex-row items-center space-x-1 space-y-0">
                      {id}
                      <FormControl>
                        <input
                          className="min-w-[580px] bg-black text-white focus:outline-none w-full"
                          {...field}
                        />
                      </FormControl>
                    </FormItem>
                  )}
                />
                <button className="hidden" type="submit">
                  Submit
                </button>
              </form>
            </Form>
            {hash && (
              <div className="flex flex-row space-x-1">
                {id}
                <p> Transaction Hash: {hash}</p>
              </div>
            )}
            {isConfirming && (
              <div className="flex flex-row space-x-1">
                {id}
                <p>Waiting for confirmation...</p>
              </div>
            )}
            {isConfirmed && (
              <div className="flex flex-row items-center space-x-1">
                {id}
                <p className="text-green-500">Transaction confirmed.</p>
              </div>
            )}
          </div>
        ) : (
          <p>Connect to a network to start</p>
        )}
        {error && (
          <div className="flex flex-row space-x-1">
            {id}
            <p className="text-red-500">Error: {(error as BaseError).shortMessage || error.message}</p>
          </div>
        )}
      </div>
    </div>
  );
};
