export const IntentsEngineAbiArb = [
  {
    type: "constructor",
    inputs: [],
    stateMutability: "payable",
  },
  {
    type: "fallback",
    stateMutability: "payable",
  },
  {
    type: "receive",
    stateMutability: "payable",
  },
  {
    type: "function",
    name: "checkPackedUserOp",
    inputs: [
      {
        name: "intent",
        type: "string",
        internalType: "string",
      },
      {
        name: "userOp",
        type: "tuple",
        internalType: "struct IE.PackedUserOperation",
        components: [
          {
            name: "sender",
            type: "address",
            internalType: "address",
          },
          {
            name: "nonce",
            type: "uint256",
            internalType: "uint256",
          },
          {
            name: "initCode",
            type: "bytes",
            internalType: "bytes",
          },
          {
            name: "callData",
            type: "bytes",
            internalType: "bytes",
          },
          {
            name: "accountGasLimits",
            type: "bytes32",
            internalType: "bytes32",
          },
          {
            name: "preVerificationGas",
            type: "uint256",
            internalType: "uint256",
          },
          {
            name: "gasFees",
            type: "bytes32",
            internalType: "bytes32",
          },
          {
            name: "paymasterAndData",
            type: "bytes",
            internalType: "bytes",
          },
          {
            name: "signature",
            type: "bytes",
            internalType: "bytes",
          },
        ],
      },
    ],
    outputs: [
      {
        name: "",
        type: "bool",
        internalType: "bool",
      },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "checkUserOp",
    inputs: [
      {
        name: "intent",
        type: "string",
        internalType: "string",
      },
      {
        name: "userOp",
        type: "tuple",
        internalType: "struct IE.UserOperation",
        components: [
          {
            name: "sender",
            type: "address",
            internalType: "address",
          },
          {
            name: "nonce",
            type: "uint256",
            internalType: "uint256",
          },
          {
            name: "initCode",
            type: "bytes",
            internalType: "bytes",
          },
          {
            name: "callData",
            type: "bytes",
            internalType: "bytes",
          },
          {
            name: "callGasLimit",
            type: "uint256",
            internalType: "uint256",
          },
          {
            name: "verificationGasLimit",
            type: "uint256",
            internalType: "uint256",
          },
          {
            name: "preVerificationGas",
            type: "uint256",
            internalType: "uint256",
          },
          {
            name: "maxFeePerGas",
            type: "uint256",
            internalType: "uint256",
          },
          {
            name: "maxPriorityFeePerGas",
            type: "uint256",
            internalType: "uint256",
          },
          {
            name: "paymasterAndData",
            type: "bytes",
            internalType: "bytes",
          },
          {
            name: "signature",
            type: "bytes",
            internalType: "bytes",
          },
        ],
      },
    ],
    outputs: [
      {
        name: "",
        type: "bool",
        internalType: "bool",
      },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "command",
    inputs: [
      {
        name: "intent",
        type: "string",
        internalType: "string",
      },
    ],
    outputs: [],
    stateMutability: "payable",
  },
  {
    type: "function",
    name: "previewCommand",
    inputs: [
      {
        name: "intent",
        type: "string",
        internalType: "string",
      },
    ],
    outputs: [
      {
        name: "to",
        type: "address",
        internalType: "address",
      },
      {
        name: "amount",
        type: "uint256",
        internalType: "uint256",
      },
      {
        name: "minAmountOut",
        type: "uint256",
        internalType: "uint256",
      },
      {
        name: "token",
        type: "address",
        internalType: "address",
      },
      {
        name: "callData",
        type: "bytes",
        internalType: "bytes",
      },
      {
        name: "executeCallData",
        type: "bytes",
        internalType: "bytes",
      },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "previewSend",
    inputs: [
      {
        name: "to",
        type: "string",
        internalType: "string",
      },
      {
        name: "amount",
        type: "string",
        internalType: "string",
      },
      {
        name: "token",
        type: "string",
        internalType: "string",
      },
    ],
    outputs: [
      {
        name: "_to",
        type: "address",
        internalType: "address",
      },
      {
        name: "_amount",
        type: "uint256",
        internalType: "uint256",
      },
      {
        name: "_token",
        type: "address",
        internalType: "address",
      },
      {
        name: "callData",
        type: "bytes",
        internalType: "bytes",
      },
      {
        name: "executeCallData",
        type: "bytes",
        internalType: "bytes",
      },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "previewSwap",
    inputs: [
      {
        name: "amountIn",
        type: "string",
        internalType: "string",
      },
      {
        name: "amountOutMinimum",
        type: "string",
        internalType: "string",
      },
      {
        name: "tokenIn",
        type: "string",
        internalType: "string",
      },
      {
        name: "tokenOut",
        type: "string",
        internalType: "string",
      },
    ],
    outputs: [
      {
        name: "_amountIn",
        type: "uint256",
        internalType: "uint256",
      },
      {
        name: "_amountOut",
        type: "uint256",
        internalType: "uint256",
      },
      {
        name: "_tokenIn",
        type: "address",
        internalType: "address",
      },
      {
        name: "_tokenOut",
        type: "address",
        internalType: "address",
      },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "send",
    inputs: [
      {
        name: "to",
        type: "string",
        internalType: "string",
      },
      {
        name: "amount",
        type: "string",
        internalType: "string",
      },
      {
        name: "token",
        type: "string",
        internalType: "string",
      },
    ],
    outputs: [],
    stateMutability: "payable",
  },
  {
    type: "function",
    name: "setName",
    inputs: [
      {
        name: "token",
        type: "address",
        internalType: "address",
      },
      {
        name: "name",
        type: "string",
        internalType: "string",
      },
    ],
    outputs: [],
    stateMutability: "payable",
  },
  {
    type: "function",
    name: "setNameAndTicker",
    inputs: [
      {
        name: "token",
        type: "address",
        internalType: "address",
      },
    ],
    outputs: [],
    stateMutability: "payable",
  },
  {
    type: "function",
    name: "swap",
    inputs: [
      {
        name: "amountIn",
        type: "string",
        internalType: "string",
      },
      {
        name: "amountOutMinimum",
        type: "string",
        internalType: "string",
      },
      {
        name: "tokenIn",
        type: "string",
        internalType: "string",
      },
      {
        name: "tokenOut",
        type: "string",
        internalType: "string",
      },
    ],
    outputs: [],
    stateMutability: "payable",
  },
  {
    type: "function",
    name: "tokens",
    inputs: [
      {
        name: "name",
        type: "string",
        internalType: "string",
      },
    ],
    outputs: [
      {
        name: "",
        type: "address",
        internalType: "address",
      },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "whatIsTheAddressOf",
    inputs: [
      {
        name: "name",
        type: "string",
        internalType: "string",
      },
    ],
    outputs: [
      {
        name: "owner",
        type: "address",
        internalType: "address",
      },
      {
        name: "receiver",
        type: "address",
        internalType: "address",
      },
      {
        name: "node",
        type: "bytes32",
        internalType: "bytes32",
      },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "whatIsTheBalanceOf",
    inputs: [
      {
        name: "name",
        type: "string",
        internalType: "string",
      },
      {
        name: "token",
        type: "string",
        internalType: "string",
      },
    ],
    outputs: [
      {
        name: "balance",
        type: "uint256",
        internalType: "uint256",
      },
      {
        name: "balanceAdjusted",
        type: "uint256",
        internalType: "uint256",
      },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "whatIsTheTotalSupplyOf",
    inputs: [
      {
        name: "token",
        type: "string",
        internalType: "string",
      },
    ],
    outputs: [
      {
        name: "supply",
        type: "uint256",
        internalType: "uint256",
      },
      {
        name: "supplyAdjusted",
        type: "uint256",
        internalType: "uint256",
      },
    ],
    stateMutability: "view",
  },
  {
    type: "event",
    name: "NameSet",
    inputs: [
      {
        name: "token",
        type: "address",
        indexed: true,
        internalType: "address",
      },
      {
        name: "name",
        type: "string",
        indexed: false,
        internalType: "string",
      },
    ],
    anonymous: false,
  },
  {
    type: "error",
    name: "InsufficientSwap",
    inputs: [],
  },
  {
    type: "error",
    name: "InvalidCharacter",
    inputs: [],
  },
  {
    type: "error",
    name: "InvalidSwap",
    inputs: [],
  },
  {
    type: "error",
    name: "InvalidSyntax",
    inputs: [],
  },
  {
    type: "error",
    name: "Overflow",
    inputs: [],
  },
] as const;
