export const IntentsEngineAbiOp = [
    {
      "type": "constructor",
      "inputs": [],
      "stateMutability": "payable"
    },
    {
      "type": "fallback",
      "stateMutability": "payable"
    },
    {
      "type": "receive",
      "stateMutability": "payable"
    },
    {
      "type": "function",
      "name": "addresses",
      "inputs": [
        {
          "name": "name",
          "type": "string",
          "internalType": "string"
        }
      ],
      "outputs": [
        {
          "name": "",
          "type": "address",
          "internalType": "address"
        }
      ],
      "stateMutability": "view"
    },
    {
      "type": "function",
      "name": "checkUserOp",
      "inputs": [
        {
          "name": "intent",
          "type": "string",
          "internalType": "string"
        },
        {
          "name": "userOp",
          "type": "tuple",
          "internalType": "struct IEOP.PackedUserOperation",
          "components": [
            {
              "name": "sender",
              "type": "address",
              "internalType": "address"
            },
            {
              "name": "nonce",
              "type": "uint256",
              "internalType": "uint256"
            },
            {
              "name": "initCode",
              "type": "bytes",
              "internalType": "bytes"
            },
            {
              "name": "callData",
              "type": "bytes",
              "internalType": "bytes"
            },
            {
              "name": "accountGasLimits",
              "type": "bytes32",
              "internalType": "bytes32"
            },
            {
              "name": "preVerificationGas",
              "type": "uint256",
              "internalType": "uint256"
            },
            {
              "name": "gasFees",
              "type": "bytes32",
              "internalType": "bytes32"
            },
            {
              "name": "paymasterAndData",
              "type": "bytes",
              "internalType": "bytes"
            },
            {
              "name": "signature",
              "type": "bytes",
              "internalType": "bytes"
            }
          ]
        }
      ],
      "outputs": [
        {
          "name": "intentMatched",
          "type": "bool",
          "internalType": "bool"
        }
      ],
      "stateMutability": "view"
    },
    {
      "type": "function",
      "name": "command",
      "inputs": [
        {
          "name": "intents",
          "type": "string[]",
          "internalType": "string[]"
        }
      ],
      "outputs": [],
      "stateMutability": "payable"
    },
    {
      "type": "function",
      "name": "command",
      "inputs": [
        {
          "name": "intent",
          "type": "string",
          "internalType": "string"
        }
      ],
      "outputs": [],
      "stateMutability": "payable"
    },
    {
      "type": "function",
      "name": "names",
      "inputs": [
        {
          "name": "addresses",
          "type": "address",
          "internalType": "address"
        }
      ],
      "outputs": [
        {
          "name": "",
          "type": "string",
          "internalType": "string"
        }
      ],
      "stateMutability": "view"
    },
    {
      "type": "function",
      "name": "pairs",
      "inputs": [
        {
          "name": "token0",
          "type": "address",
          "internalType": "address"
        },
        {
          "name": "token1",
          "type": "address",
          "internalType": "address"
        }
      ],
      "outputs": [
        {
          "name": "",
          "type": "address",
          "internalType": "address"
        }
      ],
      "stateMutability": "view"
    },
    {
      "type": "function",
      "name": "previewCommand",
      "inputs": [
        {
          "name": "intent",
          "type": "string",
          "internalType": "string"
        }
      ],
      "outputs": [
        {
          "name": "to",
          "type": "address",
          "internalType": "address"
        },
        {
          "name": "amount",
          "type": "uint256",
          "internalType": "uint256"
        },
        {
          "name": "minAmountOut",
          "type": "uint256",
          "internalType": "uint256"
        },
        {
          "name": "token",
          "type": "address",
          "internalType": "address"
        },
        {
          "name": "callData",
          "type": "bytes",
          "internalType": "bytes"
        },
        {
          "name": "executeCallData",
          "type": "bytes",
          "internalType": "bytes"
        }
      ],
      "stateMutability": "view"
    },
    {
      "type": "function",
      "name": "send",
      "inputs": [
        {
          "name": "to",
          "type": "string",
          "internalType": "string"
        },
        {
          "name": "amount",
          "type": "string",
          "internalType": "string"
        },
        {
          "name": "token",
          "type": "string",
          "internalType": "string"
        }
      ],
      "outputs": [],
      "stateMutability": "payable"
    },
    {
      "type": "function",
      "name": "setNAMI",
      "inputs": [
        {
          "name": "NAMI",
          "type": "address",
          "internalType": "contract INAMI"
        }
      ],
      "outputs": [],
      "stateMutability": "payable"
    },
    {
      "type": "function",
      "name": "setName",
      "inputs": [
        {
          "name": "token",
          "type": "address",
          "internalType": "address"
        },
        {
          "name": "name",
          "type": "string",
          "internalType": "string"
        }
      ],
      "outputs": [],
      "stateMutability": "payable"
    },
    {
      "type": "function",
      "name": "setName",
      "inputs": [
        {
          "name": "token",
          "type": "address",
          "internalType": "address"
        }
      ],
      "outputs": [],
      "stateMutability": "payable"
    },
    {
      "type": "function",
      "name": "setPair",
      "inputs": [
        {
          "name": "tokenA",
          "type": "address",
          "internalType": "address"
        },
        {
          "name": "tokenB",
          "type": "address",
          "internalType": "address"
        },
        {
          "name": "pair",
          "type": "address",
          "internalType": "address"
        }
      ],
      "outputs": [],
      "stateMutability": "payable"
    },
    {
      "type": "function",
      "name": "swap",
      "inputs": [
        {
          "name": "amountIn",
          "type": "string",
          "internalType": "string"
        },
        {
          "name": "amountOutMin",
          "type": "string",
          "internalType": "string"
        },
        {
          "name": "tokenIn",
          "type": "string",
          "internalType": "string"
        },
        {
          "name": "tokenOut",
          "type": "string",
          "internalType": "string"
        },
        {
          "name": "receiver",
          "type": "string",
          "internalType": "string"
        }
      ],
      "outputs": [],
      "stateMutability": "payable"
    },
    {
      "type": "function",
      "name": "translateCommand",
      "inputs": [
        {
          "name": "callData",
          "type": "bytes",
          "internalType": "bytes"
        }
      ],
      "outputs": [
        {
          "name": "intent",
          "type": "string",
          "internalType": "string"
        }
      ],
      "stateMutability": "pure"
    },
    {
      "type": "function",
      "name": "translateExecute",
      "inputs": [
        {
          "name": "callData",
          "type": "bytes",
          "internalType": "bytes"
        }
      ],
      "outputs": [
        {
          "name": "intent",
          "type": "string",
          "internalType": "string"
        }
      ],
      "stateMutability": "view"
    },
    {
      "type": "function",
      "name": "translateUserOp",
      "inputs": [
        {
          "name": "userOp",
          "type": "tuple",
          "internalType": "struct IEOP.PackedUserOperation",
          "components": [
            {
              "name": "sender",
              "type": "address",
              "internalType": "address"
            },
            {
              "name": "nonce",
              "type": "uint256",
              "internalType": "uint256"
            },
            {
              "name": "initCode",
              "type": "bytes",
              "internalType": "bytes"
            },
            {
              "name": "callData",
              "type": "bytes",
              "internalType": "bytes"
            },
            {
              "name": "accountGasLimits",
              "type": "bytes32",
              "internalType": "bytes32"
            },
            {
              "name": "preVerificationGas",
              "type": "uint256",
              "internalType": "uint256"
            },
            {
              "name": "gasFees",
              "type": "bytes32",
              "internalType": "bytes32"
            },
            {
              "name": "paymasterAndData",
              "type": "bytes",
              "internalType": "bytes"
            },
            {
              "name": "signature",
              "type": "bytes",
              "internalType": "bytes"
            }
          ]
        }
      ],
      "outputs": [
        {
          "name": "intent",
          "type": "string",
          "internalType": "string"
        }
      ],
      "stateMutability": "view"
    },
    {
      "type": "function",
      "name": "whatIsTheAddressOf",
      "inputs": [
        {
          "name": "name",
          "type": "string",
          "internalType": "string"
        }
      ],
      "outputs": [
        {
          "name": "owner",
          "type": "address",
          "internalType": "address"
        },
        {
          "name": "receiver",
          "type": "address",
          "internalType": "address"
        },
        {
          "name": "node",
          "type": "bytes32",
          "internalType": "bytes32"
        }
      ],
      "stateMutability": "view"
    },
    {
      "type": "event",
      "name": "NameSet",
      "inputs": [
        {
          "name": "token",
          "type": "address",
          "indexed": false,
          "internalType": "address"
        },
        {
          "name": "name",
          "type": "string",
          "indexed": false,
          "internalType": "string"
        }
      ],
      "anonymous": false
    },
    {
      "type": "event",
      "name": "PairSet",
      "inputs": [
        {
          "name": "token0",
          "type": "address",
          "indexed": false,
          "internalType": "address"
        },
        {
          "name": "token1",
          "type": "address",
          "indexed": false,
          "internalType": "address"
        },
        {
          "name": "pair",
          "type": "address",
          "indexed": false,
          "internalType": "address"
        }
      ],
      "anonymous": false
    },
    {
      "type": "error",
      "name": "InsufficientSwap",
      "inputs": []
    },
    {
      "type": "error",
      "name": "InvalidCharacter",
      "inputs": []
    },
    {
      "type": "error",
      "name": "InvalidSelector",
      "inputs": []
    },
    {
      "type": "error",
      "name": "InvalidSwap",
      "inputs": []
    },
    {
      "type": "error",
      "name": "InvalidSyntax",
      "inputs": []
    },
    {
      "type": "error",
      "name": "Overflow",
      "inputs": []
    }
] as const;