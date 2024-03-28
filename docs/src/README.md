# [`IE`](https://github.com/NaniDAO/IE)  [![License: AGPL-3.0-only](https://img.shields.io/badge/License-AGPL-black.svg)](https://opensource.org/license/agpl-v3/) [![solidity](https://img.shields.io/badge/solidity-%5E0.8.25-black)](https://docs.soliditylang.org/en/v0.8.25/) [![Foundry](https://img.shields.io/badge/Built%20with-Foundry-000000.svg)](https://getfoundry.sh/) ![tests](https://github.com/z0r0z/zenplate/actions/workflows/ci.yml/badge.svg)

The **Intents Engine** (`IE`): A Basic *Text-to-tx* Simulator Contract.

## Deployments

### Mainnet

`V1:` [`0x1E00000000Cf8ba83e0005c59c1Bf1C4682C8E00`](https://etherscan.io/address/0x1e00000000cf8ba83e0005c59c1bf1c4682c8e00#code)

### Arbitrum

`V1.2:` [`0x1e00003a669bb466d6B49800000099E1abDD6600`](https://arbiscan.io/address/0x1e00003a669bb466d6b49800000099e1abdd6600#code)

`Note:` L2 will be used to rapidly prototype a stable and sufficient `IE` for common crypto commands. Many dev resources here will cater to the current L2 prototype until the release of `V2` on L1.

## Uses

From natural language:

- Wallet preview (check tx)
- Security checkpoint (forbid tx)
- Command translation (make tx)

`IE` should deterministically and transparently operate to provide these utilities in an uncensorable medium like a Solidity smart contract.

[`V1`](./src/IE.sol) is a POC of this. [*Short demo and explainer thread on X.*](https://x.com/z0r0zzz/status/1758392014737920209?s=20)

## Command Syntax (⌘)

`IE` is approaching things from first-principles and a "show" rather than "tell" approach. There will be some experimentation.

Some things in `V1` are likely very underoptimized for this particular use case.

The bigger project is to identify syntax and phrasing for common types of onchain transactions in English to start. The following are identified as categories and phrases that should demonstrate this for many if not most natural language commands to generate txs.

------------------------------------

### Send

aliases: *transfer*

#### < A >
*Words: 4*

**[action] [object] [value] [asset]**
> *send vitalik 1 ETH*

#### < B >
*Words: 5*

**[action] [value] [asset] [to/for] [object]**
> *send 1 ETH to/for vitalik*

------------------------------------

### Swap

aliases: *exchange*

#### < A >
*Words: 5*

**[action] [value] [asset] [to/for] [object]**
> *swap 1 ETH to/for DAI*

#### < B >
*Words: 6*

[action] [value] [asset] [to/for] [minOutputAmount] [object]
- **swap 1 ETH to/for 2500 DAI**

aliases: *exchange*

`Note:` In `V1.2` on Arbitrum, a `minOutputAmount` can be specified for swaps. It ensures that you receive a minimum output amount of `object` at the end of the swap, otherwise the transaction will revert. The default value is set to `0`.

------------------------------------

Phrases are provided in the order in which they are most expected. They are "naturalized" to lower case. The `IE` contract automatically does this, but front-ends should nonetheless try and format as close as possible (*i.e.*, through a simple LLM trained or prompted on these examples below).

In terms of usual English, we assume the subject of each command is the user account which is more explicit in the case of checking an ERC4337 userOp (where `sender` is the user). And the `object` receives assets or contract calls. `value` is the token or ETH amount involved in the action and the `asset` is the particular item sent or issued from (initially ETH or ERC20 to cover fungibles and most immediate security needs that could benefit from `IE`).

You **MUST** include spaces in the string provided to `IE` in order for it to understand word separation.

`Note:` `to/for` is an identified filler word common to most of the transactions we will cover so it is highlighted.

As you might notice, there are patterns. Because after all this is typical language and logic we are talking about here. For example, `value` will precede `asset`. `object` will either follow the `action` or be at the end. If at the end, there will be a filler of `for/to`. (Yeah I know this is what people learn in grammar schools but the exercise will likely yield good results.)

Also, let's try and be as helpful as possible at the top of the command funnel. *E.g.*, if there is `msg.value` in a command, then we should assume ETH is involved.

Actions should also have aliases to catch more cases. Though it will be cheaper to use the primary word (for example, 'send' or 'swap' with preference to familiarity, and if there indecision, the shorter), it is helpful to do more and catch different ways of phrasing transactional commands, like "send" can equate to "transfer" when it comes to onchain assets. Adhering to Solidity and smart contract functions themselves in word choice makes the most sense as well (*e.g.*, ETH.*send*/*transfer*, IERC20.*transfer*, UNI.*swap*, CURVE.*exchange*).

## Getting Started

Run: `curl -L https://foundry.paradigm.xyz | bash && source ~/.bashrc && foundryup`

Build the foundry project with `forge build`. Run tests with `forge test`. Measure gas with `forge snapshot`. Format with `forge fmt`.

`Note:` Tests currently run on a virtual blockchain fork to check ENS properly.

## Blueprint

```txt
lib
├─ forge-std — https://github.com/foundry-rs/forge-std
├─ solady — https://github.com/vectorized/solady
src
├─ IE — Intents Engine
test
└─ IE.t - Test Contract
```

## Disclaimer

*These smart contracts and testing suite are being provided as is. No guarantee, representation or warranty is being made, express or implied, as to the safety or correctness of anything provided herein or through related user interfaces. This repository and related code have not been audited and as such there can be no assurance anything will work as intended, and users may experience delays, failures, errors, omissions, loss of transmitted information or loss of funds. The creators are not liable for any of the foregoing. Users should proceed with caution and use at their own risk.*

## License

See [LICENSE](./LICENSE) for more details.
