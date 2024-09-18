# IETH
[Git Source](https://github.com/NaniDAO/ie/blob/58175fad32cfeea89f1d83e288aec227fe545300/src/IETH.sol)

**Author:**
nani.eth (https://github.com/NaniDAO/ie)

Simple helper contract for turning transactional intents into executable code.

*V1 simulates typical commands (sending and swapping tokens) and includes execution.
IE also has a workflow to verify the intent of ERC4337 account userOps against calldata.
Example commands include "send nani 100 dai" or "swap usdc for 1 eth" and such variants.*


## State Variables
### DAO
========================= CONSTANTS ========================= ///

*The governing DAO address.*


```solidity
address internal constant DAO = 0xDa000000000000d2885F108500803dfBAaB2f2aA;
```


### ETH
*The conventional ERC7528 ETH address.*


```solidity
address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
```


### WETH
*The canonical wrapped ETH address.*


```solidity
address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
```


### WBTC
*The popular wrapped BTC address.*


```solidity
address internal constant WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
```


### USDC
*The Circle USD stablecoin address.*


```solidity
address internal constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
```


### USDT
*The Tether USD stablecoin address.*


```solidity
address internal constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
```


### DAI
*The Maker DAO USD stablecoin address.*


```solidity
address internal constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
```


### WSTETH
*The Lido Wrapped Staked ETH token address.*


```solidity
address internal constant WSTETH = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
```


### RETH
*The Rocket Pool Staked ETH token address.*


```solidity
address internal constant RETH = 0xae78736Cd615f374D3085123A210448E74Fc6393;
```


### UNISWAP_V3_FACTORY
*The address of the Uniswap V3 Factory.*


```solidity
address internal constant UNISWAP_V3_FACTORY = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
```


### UNISWAP_V3_POOL_INIT_CODE_HASH
*The Uniswap V3 Pool `initcodehash`.*


```solidity
bytes32 internal constant UNISWAP_V3_POOL_INIT_CODE_HASH =
    0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;
```


### MIN_SQRT_RATIO_PLUS_ONE
*The minimum value that can be returned from `getSqrtRatioAtTick` (plus one).*


```solidity
uint160 internal constant MIN_SQRT_RATIO_PLUS_ONE = 4295128740;
```


### MAX_SQRT_RATIO_MINUS_ONE
*The maximum value that can be returned from `getSqrtRatioAtTick` (minus one).*


```solidity
uint160 internal constant MAX_SQRT_RATIO_MINUS_ONE =
    1461446703485210103287273052203988822378723970341;
```


### ENS_REGISTRY
*ENS fallback registry contract.*


```solidity
IENSHelper internal constant ENS_REGISTRY = IENSHelper(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);
```


### ENS_WRAPPER
*ENS name wrapper token contract.*


```solidity
IENSHelper internal constant ENS_WRAPPER = IENSHelper(0xD4416b13d2b3a9aBae7AcD5D6C2BbDBE25686401);
```


### ASCII_MAP
*String mapping for `ENSAsciiNormalizer` logic.*


```solidity
bytes internal constant ASCII_MAP =
    hex"2d00020101000a010700016101620163016401650166016701680169016a016b016c016d016e016f0170017101720173017401750176017701780179017a06001a010500";
```


### addresses
========================== STORAGE ========================== ///

*DAO-governed token names to addresses.*


```solidity
mapping(string name => address) public addresses;
```


### names
*DAO-governed token addresses to names.*


```solidity
mapping(address addresses => string) public names;
```


### pairs
*DAO-governed token swap pool routing on Uniswap V3.*


```solidity
mapping(address token0 => mapping(address token1 => address)) public pairs;
```


### _idnamap
*Each index in idnamap refers to an ascii code point.
If idnamap[char] > 2, char maps to a valid ascii character.
Otherwise, idna[char] returns Rule.DISALLOWED or Rule.VALID.
Modified from `ENSAsciiNormalizer` deployed by royalfork.eth
(0x4A5cae3EC0b144330cf1a6CeAD187D8F6B891758).*


```solidity
bytes1[] internal _idnamap;
```


## Functions
### constructor

======================== CONSTRUCTOR ======================== ///

*Constructs this IE on Ethereum with ENS `ASCII_MAP`.*


```solidity
constructor() payable;
```

### previewCommand

====================== COMMAND PREVIEW ====================== ///

*Preview natural language smart contract command.
The `send` syntax uses ENS naming: 'send vitalik 20 DAI'.
`swap` syntax uses common format: 'swap 100 DAI for WETH'.*


```solidity
function previewCommand(string calldata intent)
    public
    view
    virtual
    returns (
        address to,
        uint256 amount,
        uint256 minAmountOut,
        address token,
        bytes memory callData,
        bytes memory executeCallData
    );
```

### _previewSend

*Previews a `send` command from the parts of a matched intent string.*


```solidity
function _previewSend(bytes memory to, bytes memory amount, bytes memory token)
    internal
    view
    virtual
    returns (
        address _to,
        uint256 _amount,
        address _token,
        bytes memory callData,
        bytes memory executeCallData
    );
```

### _previewSwap

*Previews a `swap` command from the parts of a matched intent string.*


```solidity
function _previewSwap(
    bytes memory amountIn,
    bytes memory amountOutMin,
    bytes memory tokenIn,
    bytes memory tokenOut,
    bytes memory receiver
)
    internal
    view
    virtual
    returns (
        uint256 _amountIn,
        uint256 _amountOut,
        address _tokenIn,
        address _tokenOut,
        address _receiver
    );
```

### checkUserOp

*Checks packed ERC4337 userOp against the output of the command intent.*


```solidity
function checkUserOp(string calldata intent, PackedUserOperation calldata userOp)
    public
    view
    virtual
    returns (bool intentMatched);
```

### _returnTokenConstants

*Checks and returns the canonical token address constant for a matched intent string.*


```solidity
function _returnTokenConstants(bytes32 token)
    internal
    pure
    virtual
    returns (address _token, uint256 _decimals);
```

### _returnTokenAliasConstants

*Checks and returns the canonical token string constant for a matched address.*


```solidity
function _returnTokenAliasConstants(address token)
    internal
    pure
    virtual
    returns (string memory _token, uint256 _decimals);
```

### _returnPoolConstants

*Checks and returns popular pool pairs for WETH swaps.*


```solidity
function _returnPoolConstants(address token0, address token1)
    internal
    pure
    virtual
    returns (address pool);
```

### command

===================== COMMAND EXECUTION ===================== ///

*Executes a text command from an `intent` string.*


```solidity
function command(string calldata intent) public payable virtual;
```

### command

*Executes batch of text commands from an `intents` string.*


```solidity
function command(string[] calldata intents) public payable virtual;
```

### send

*Executes a `send` command from the parts of a matched intent string.*


```solidity
function send(string memory to, string memory amount, string memory token) public payable virtual;
```

### swap

*Executes a `swap` command from the parts of a matched intent string.*


```solidity
function swap(
    string memory amountIn,
    string memory amountOutMin,
    string memory tokenIn,
    string memory tokenOut,
    string memory receiver
) public payable virtual;
```

### fallback

*Fallback `uniswapV3SwapCallback`.
If ETH is swapped, WETH is forwarded.*


```solidity
fallback() external payable virtual;
```

### _computePoolAddress

*Computes the create2 address for given token pair.
note: This process checks all available pools for price.*


```solidity
function _computePoolAddress(address tokenA, address tokenB)
    internal
    view
    virtual
    returns (address pool, bool zeroForOne);
```

### _computePairHash

*Computes the create2 deployment hash for a given token pair.*


```solidity
function _computePairHash(address token0, address token1, uint24 fee)
    internal
    pure
    virtual
    returns (address pool);
```

### _hash

*Returns `keccak256(abi.encode(value0, value1, value2))`.*


```solidity
function _hash(address value0, address value1, uint24 value2)
    internal
    pure
    virtual
    returns (bytes32 result);
```

### _wrapETH

*Wraps an `amount` of ETH to WETH and funds pool caller for swap.*


```solidity
function _wrapETH(uint256 amount) internal virtual;
```

### _unwrapETH

*Unwraps an `amount` of ETH from WETH for return.*


```solidity
function _unwrapETH(uint256 amount) internal virtual;
```

### _balanceOf

*Returns the amount of ERC20 `token` owned by `account`.*


```solidity
function _balanceOf(address token, address account)
    internal
    view
    virtual
    returns (uint256 amount);
```

### receive

*ETH receiver fallback.
Only canonical WETH can call.*


```solidity
receive() external payable virtual;
```

### translateCommand

==================== COMMAND TRANSLATION ==================== ///

*Translates an `intent` from raw `command()` calldata.*


```solidity
function translateCommand(bytes calldata callData)
    public
    pure
    virtual
    returns (string memory intent);
```

### translateExecute

*Translates an `intent` for send action from the solution `callData` of standard `execute()`.
note: The function selector technically doesn't need to be `execute()` but params should match.*


```solidity
function translateExecute(bytes calldata callData)
    public
    view
    virtual
    returns (string memory intent);
```

### translateUserOp

*Translate packed ERC4337 userOp `callData` into readable `intent`.*


```solidity
function translateUserOp(PackedUserOperation calldata userOp)
    public
    view
    virtual
    returns (string memory intent);
```

### whatIsTheAddressOf

====================== ENS VERIFICATION ====================== ///

*Returns ENS name ownership details.
note: The `receiver` should be already set,
or, the command should use the raw address.*


```solidity
function whatIsTheAddressOf(string memory name)
    public
    view
    virtual
    returns (address owner, address receiver, bytes32 node);
```

### _namehash

*Computes an ENS domain namehash.*


```solidity
function _namehash(string memory domain) internal view virtual returns (bytes32 node);
```

### _labelhash

*Computes an ENS domain labelhash given its start and end.*


```solidity
function _labelhash(string memory domain, uint256 start, uint256 end)
    internal
    pure
    virtual
    returns (bytes32 hash);
```

### setName

========================= GOVERNANCE ========================= ///

*Sets a public `name` tag for a given `token` address. Governed by DAO.*


```solidity
function setName(address token, string calldata name) public payable virtual;
```

### setName

*Sets a public `name` and ticker for a given `token` address. Open.*


```solidity
function setName(address token) public payable virtual;
```

### setPair

*Sets a public pool `pair` for swapping tokens. Governed by DAO.*


```solidity
function setPair(address tokenA, address tokenB, address pair) public payable virtual;
```

### _lowercase

===================== STRING OPERATIONS ===================== ///

*Returns copy of string in lowercase.
Modified from Solady LibString `toCase`.*


```solidity
function _lowercase(bytes memory subject) internal pure virtual returns (bytes memory result);
```

### _extraction

*Extracts the first word (action) as bytes32.*


```solidity
function _extraction(bytes memory normalizedIntent)
    internal
    pure
    virtual
    returns (bytes32 result);
```

### _extractSend

*Extract the key words of normalized `send` intent.*


```solidity
function _extractSend(bytes memory normalizedIntent)
    internal
    pure
    virtual
    returns (bytes memory to, bytes memory amount, bytes memory token);
```

### _extractSwap

*Extract the key words of normalized `swap` intent.*


```solidity
function _extractSwap(bytes memory normalizedIntent)
    internal
    pure
    virtual
    returns (
        bytes memory amountIn,
        bytes memory amountOutMin,
        bytes memory tokenIn,
        bytes memory tokenOut,
        bytes memory receiver
    );
```

### _isNumber

*Validate whether given bytes string is number, percentage or 'all'.*


```solidity
function _isNumber(bytes memory s) internal pure virtual returns (bool);
```

### _split

*Splits a string into parts based on a delimiter.*


```solidity
function _split(bytes memory base, bytes1 delimiter)
    internal
    pure
    virtual
    returns (StringPart[] memory parts);
```

### _getPart

*Converts a `StringPart` into its compact bytes.*


```solidity
function _getPart(bytes memory base, StringPart memory part)
    internal
    pure
    virtual
    returns (bytes memory);
```

### _toUint

*Convert string to decimalized numerical value.*


```solidity
function _toUint(bytes memory s, uint256 decimals, address token)
    internal
    view
    virtual
    returns (uint256 result);
```

### _toAddress

*Converts a hexadecimal string to its `address` representation.*


```solidity
function _toAddress(bytes memory s) internal pure virtual returns (address addr);
```

### _toAsciiString

*Convert an address to an ASCII string representation.*


```solidity
function _toAsciiString(address x) internal pure virtual returns (string memory);
```

### _char

*Convert a single byte to a character in the ASCII string.*


```solidity
function _char(bytes1 b) internal pure virtual returns (bytes1 c);
```

### _convertWeiToString

*Convert number to string and insert decimal point.*


```solidity
function _convertWeiToString(uint256 weiAmount, uint256 decimals)
    internal
    pure
    virtual
    returns (string memory);
```

### _removeTrailingZeros

*Remove any trailing zeroes from bytes.*


```solidity
function _removeTrailingZeros(bytes memory str) internal pure virtual returns (string memory);
```

### _toString

*Returns the base 10 decimal representation of `value`.
Modified from (https://github.com/Vectorized/solady/blob/main/src/utils/LibString.sol)*


```solidity
function _toString(uint256 value) internal pure virtual returns (string memory str);
```

## Events
### NameSet
=========================== EVENTS =========================== ///

*Logs the setting of a token name.*


```solidity
event NameSet(address token, string name);
```

### PairSet
*Logs the setting of a swap pool pair on Uniswap V3.*


```solidity
event PairSet(address token0, address token1, address pair);
```

## Errors
### Overflow
======================= LIBRARY USAGE ======================= ///

*Token transfer library.*

*Token metadata reader library.
======================= CUSTOM ERRORS ======================= ///*

*Bad math.*


```solidity
error Overflow();
```

### InvalidSwap
*0-liquidity.*


```solidity
error InvalidSwap();
```

### InvalidSyntax
*Invalid command.*


```solidity
error InvalidSyntax();
```

### InvalidReceiver
*Invalid out receiver.*


```solidity
error InvalidReceiver();
```

### InvalidCharacter
*Non-numeric character.*


```solidity
error InvalidCharacter();
```

### InsufficientSwap
*Insufficient swap output.*


```solidity
error InsufficientSwap();
```

### InvalidSelector
*Invalid selector for spend.*


```solidity
error InvalidSelector();
```

## Structs
### PackedUserOperation
========================== STRUCTS ========================== ///

*The packed ERC4337 user operation (userOp) struct.*


```solidity
struct PackedUserOperation {
    address sender;
    uint256 nonce;
    bytes initCode;
    bytes callData;
    bytes32 accountGasLimits;
    uint256 preVerificationGas;
    bytes32 gasFees;
    bytes paymasterAndData;
    bytes signature;
}
```

### SwapInfo
*The `swap()` command information struct.*


```solidity
struct SwapInfo {
    bool ETHIn;
    bool ETHOut;
    address tokenIn;
    address tokenOut;
    uint256 amountIn;
}
```

### SwapLiq
*The `swap()` pool liquidity struct.*


```solidity
struct SwapLiq {
    address pool;
    uint256 liq;
}
```

### StringPart
*The string start and end indices.*


```solidity
struct StringPart {
    uint256 start;
    uint256 end;
}
```

## Enums
### Rule
=========================== ENUMS =========================== ///

*`ENSAsciiNormalizer` rules.*


```solidity
enum Rule {
    DISALLOWED,
    VALID
}
```
