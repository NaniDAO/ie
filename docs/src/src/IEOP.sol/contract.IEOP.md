# IEOP
[Git Source](https://github.com/NaniDAO/ie/blob/87f24a80c565d9fdfa4a7b43f9b34962aa8f6bca/src/IEOP.sol)

**Author:**
nani.eth (https://github.com/NaniDAO/ie)

Simple helper contract for turning transactional intents into executable code.

*V1 simulates typical commands (sending and swapping tokens) and includes execution.
IE also has a workflow to verify the intent of ERC4337 account userOps against calldata.*


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
address internal constant WETH = 0x4200000000000000000000000000000000000006;
```


### WBTC
*The popular wrapped BTC address.*


```solidity
address internal constant WBTC = 0x68f180fcCe6836688e9084f035309E29Bf0A2095;
```


### USDC
*The Circle USD stablecoin address.*


```solidity
address internal constant USDC = 0x0b2C639c533813f4Aa9D7837CAf62653d097Ff85;
```


### USDT
*The Tether USD stablecoin address.*


```solidity
address internal constant USDT = 0x94b008aA00579c1307B0EF2c499aD98a8ce58e58;
```


### DAI
*The Maker DAO USD stablecoin address.*


```solidity
address internal constant DAI = 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1;
```


### OP
*The Optimism DAO governance token address.*


```solidity
address internal constant OP = 0x4200000000000000000000000000000000000042;
```


### WSTETH
*The Lido Wrapped Staked ETH token address.*


```solidity
address internal constant WSTETH = 0x1F32b1c2345538c0c6f582fCB022739c4A194Ebb;
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


### nami
========================== STORAGE ========================== ///

*DAO-governed naming interface (nami).*


```solidity
INAMI internal nami;
```


### addresses
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


## Functions
### constructor

======================== CONSTRUCTOR ======================== ///

*Constructs this IE on the Optimism L2 of Ethereum.*


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

*Returns ENS name ownership details.*


```solidity
function whatIsTheAddressOf(string memory name)
    public
    view
    virtual
    returns (address owner, address receiver, bytes32 node);
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

### setNAMI

*Sets the naming interface (nami) singleton. Governed by DAO.*


```solidity
function setNAMI(INAMI NAMI) public payable virtual;
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

