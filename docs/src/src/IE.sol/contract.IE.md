# IE
[Git Source](https://github.com/NaniDAO/ie/blob/b0475e5d66a2a8d1371056df9a3f0ad75b1b4d99/src/IE.sol)

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


### AKA
*The onchain akashic library.*


```solidity
address internal constant AKA = 0x000000000000394793B2Fe854281CeE09a98bdBC;
```


### NANI
*The NANI token address.*


```solidity
address internal constant NANI = 0x000000000000C6A645b0E51C9eCAA4CA580Ed8e8;
```


### ETH
*The conventional ERC7528 ETH address.*


```solidity
address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
```


### WETH
*The canonical wrapped ETH address.*


```solidity
address internal constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
```


### WBTC
*The popular wrapped BTC address.*


```solidity
address internal constant WBTC = 0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f;
```


### USDC
*The Circle USD stablecoin address.*


```solidity
address internal constant USDC = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;
```


### USDT
*The Tether USD stablecoin address.*


```solidity
address internal constant USDT = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;
```


### DAI
*The Maker DAO USD stablecoin address.*


```solidity
address internal constant DAI = 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1;
```


### ARB
*The Arbitrum DAO governance token address.*


```solidity
address internal constant ARB = 0x912CE59144191C1204E64559FE8253a0e49E6548;
```


### WSTETH
*The Lido Wrapped Staked ETH token address.*


```solidity
address internal constant WSTETH = 0x5979D7b546E38E414F7E9822514be443A4800529;
```


### RETH
*The Rocket Pool Staked ETH token address.*


```solidity
address internal constant RETH = 0xEC70Dcb4A1EFa46b8F2D97C310C9c4790ba5ffA8;
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

*DAO-governed NAMI naming system on Arbitrum.*


```solidity
INAMI internal nami = INAMI(0x000000006641B4C250AEA6B62A1e0067D300697a);
```


### tokens
*DAO-governed token name aliasing.*


```solidity
mapping(string name => address) public tokens;
```


### aliases
*DAO-governed token address name aliasing.*


```solidity
mapping(address token => string name) public aliases;
```


### pairs
*DAO-governed token swap pool routing on Uniswap V3.*


```solidity
mapping(address token0 => mapping(address token1 => address)) public pairs;
```


## Functions
### constructor

======================== CONSTRUCTOR ======================== ///

*Constructs this IE on the Arbitrum L2 of Ethereum.*


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

### previewSend

*Previews a `send` command from the parts of a matched intent string.*


```solidity
function previewSend(string memory to, string memory amount, string memory token)
    public
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

### previewSwap

*Previews a `swap` command from the parts of a matched intent string.*


```solidity
function previewSwap(
    string memory amountIn,
    string memory amountOutMinimum,
    string memory tokenIn,
    string memory tokenOut
)
    public
    view
    virtual
    returns (uint256 _amountIn, uint256 _amountOut, address _tokenIn, address _tokenOut);
```

### checkUserOp

*Checks ERC4337 userOp against the output of the command intent.*


```solidity
function checkUserOp(string calldata intent, UserOperation calldata userOp)
    public
    view
    virtual
    returns (bool intentMatched);
```

### checkPackedUserOp

*Checks packed ERC4337 userOp against the output of the command intent.*


```solidity
function checkPackedUserOp(string calldata intent, PackedUserOperation calldata userOp)
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

*Executes a text command from an intent string.*


```solidity
function command(string calldata intent) public payable virtual;
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
    string memory amountOutMinimum,
    string memory tokenIn,
    string memory tokenOut
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

### read

==================== COMMAND TRANSLATION ==================== ///

*Returns the akashic library summary digest `about` a given `topic`.*


```solidity
function read(string calldata topic) public view virtual returns (string memory about);
```

### translateCommand

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

### translateTokenTransfer

*Translates the `intent` for `token` send action from the solution `tokenCalldata`.
note: Designed for EOAs and raw verification. Token alias is checked against storage.*


```solidity
function translateTokenTransfer(address token, bytes calldata tokenCalldata)
    public
    view
    virtual
    returns (string memory intent);
```

### translateUserOp

*Translate ERC4337 userOp `callData` into readable `intent`.*


```solidity
function translateUserOp(UserOperation calldata userOp)
    public
    view
    virtual
    returns (string memory intent);
```

### translatePackedUserOp

*Translate packed ERC4337 userOp `callData` into readable `intent`.*


```solidity
function translatePackedUserOp(PackedUserOperation calldata userOp)
    public
    view
    virtual
    returns (string memory intent);
```

### previewBalanceChange

================== BALANCE & SUPPLY HELPERS ================== ///

*Returns resulting percentage change of ETH or token balance.*


```solidity
function previewBalanceChange(address user, string calldata intent)
    public
    view
    virtual
    returns (uint256 percentage);
```

### whatIsTheBalanceOf

*Returns the balance of a named account in a named token.*


```solidity
function whatIsTheBalanceOf(string calldata name, string calldata token)
    public
    view
    virtual
    returns (uint256 balance, uint256 balanceAdjusted);
```

### whatIsTheTotalSupplyOf

*Returns the total supply of a named token.*


```solidity
function whatIsTheTotalSupplyOf(string calldata token)
    public
    view
    virtual
    returns (uint256 supply, uint256 supplyAdjusted);
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

### setAlias

========================= GOVERNANCE ========================= ///

*Sets a public alias tag for a given `token` address. Governed by DAO.*


```solidity
function setAlias(address token, string calldata _alias) public payable virtual;
```

### setAliasAndTicker

*Sets a public alias and ticker for a given `token` address.*


```solidity
function setAliasAndTicker(address token) public payable virtual;
```

### setPair

*Sets a public pool `pair` for swapping. Governed by DAO.*


```solidity
function setPair(address tokenA, address tokenB, address pair) public payable virtual;
```

### setNAMI

*Sets the Arbitrum naming singleton (NAMI). Governed by DAO.*


```solidity
function setNAMI(INAMI NAMI) public payable virtual;
```

### _lowercase

===================== STRING OPERATIONS ===================== ///

*Returns copy of string in lowercase.
Modified from Solady LibString `toCase`.*


```solidity
function _lowercase(string memory subject) internal pure virtual returns (string memory result);
```

### _extraction

*Extracts the first word (action) as bytes32.*


```solidity
function _extraction(string memory normalizedIntent)
    internal
    pure
    virtual
    returns (bytes32 result);
```

### _extractSend

*Extract the key words of normalized `send` intent.*


```solidity
function _extractSend(string memory normalizedIntent)
    internal
    pure
    virtual
    returns (string memory to, string memory amount, string memory token);
```

### _extractSwap

*Extract the key words of normalized `swap` intent.*


```solidity
function _extractSwap(string memory normalizedIntent)
    internal
    pure
    virtual
    returns (
        string memory amountIn,
        string memory amountOutMinimum,
        string memory tokenIn,
        string memory tokenOut
    );
```

### _split

*Split the intent into an array of words.*


```solidity
function _split(string memory base, bytes1 delimiter)
    internal
    pure
    virtual
    returns (string[] memory parts);
```

### _toUint

*Convert string to decimalized numerical value.*


```solidity
function _toUint(string memory s, uint256 decimals)
    internal
    pure
    virtual
    returns (uint256 result);
```

### _toAddress

*Converts a hexadecimal string to its `address` representation.
Modified from Stack (https://ethereum.stackexchange.com/a/156916).*


```solidity
function _toAddress(string memory s) internal pure virtual returns (address addr);
```

### _hexStringToAddress

*Converts a hexadecimal string into its bytes representation.*


```solidity
function _hexStringToAddress(string memory s) internal pure virtual returns (bytes memory r);
```

### _fromHexChar

*Converts a single hexadecimal character into its numerical value.*


```solidity
function _fromHexChar(uint8 c) internal pure virtual returns (uint8 result);
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

*Remove any trailing zeroes from string.*


```solidity
function _removeTrailingZeros(string memory str) internal pure virtual returns (string memory);
```

### _toString

*Returns the base 10 decimal representation of `value`.
Modified from (https://github.com/Vectorized/solady/blob/main/src/utils/LibString.sol)*


```solidity
function _toString(uint256 value) internal pure virtual returns (string memory str);
```

## Events
### AliasSet
=========================== EVENTS =========================== ///

*Logs the registration of a token name alias.*


```solidity
event AliasSet(address indexed token, string name);
```

### PairSet
*Logs the registration of a token swap pool pair route on Uniswap V3.*


```solidity
event PairSet(address indexed token0, address indexed token1, address pair);
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
*Invalid selector for the given asset spend.*


```solidity
error InvalidSelector();
```

## Structs
### UserOperation
========================== STRUCTS ========================== ///

*The ERC4337 user operation (userOp) struct.*


```solidity
struct UserOperation {
    address sender;
    uint256 nonce;
    bytes initCode;
    bytes callData;
    uint256 callGasLimit;
    uint256 verificationGasLimit;
    uint256 preVerificationGas;
    uint256 maxFeePerGas;
    uint256 maxPriorityFeePerGas;
    bytes paymasterAndData;
    bytes signature;
}
```

### PackedUserOperation
*The packed ERC4337 userOp struct.*


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
*The `swap` command information struct.*


```solidity
struct SwapInfo {
    address tokenIn;
    address tokenOut;
    uint256 amountIn;
    bool ETHIn;
    bool ETHOut;
}
```

### SwapLiq
*The `swap` pool liquidity struct.*


```solidity
struct SwapLiq {
    address pool;
    uint256 liq;
}
```

