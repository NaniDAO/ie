# IE
[Git Source](https://github.com/NaniDAO/IE/blob/fe9aa8f819c0b0c1f1baab80820f73546caaabc2/src/IE.sol)

**Author:**
nani.eth (https://github.com/NaniDAO/ie)

Simple helper contract for turning transactional intents into executable code.

*V0 simulates the output of typical commands (sending tokens) and allows execution.
IE also has workflow to verify the intent of ERC-4337 account userOps against calldata.*


## State Variables
### DAO
========================= CONSTANTS ========================= ///

*The governing DAO address.*


```solidity
address internal constant DAO = 0xDa000000000000d2885F108500803dfBAaB2f2aA;
```


### NANI
*The NANI token address.*


```solidity
address internal constant NANI = 0x00000000000025824328358250920B271f348690;
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


### ENS_HELPER
*ENS name normalizer contract.*


```solidity
IENSHelper internal constant ENS_HELPER = IENSHelper(0x4A5cae3EC0b144330cf1a6CeAD187D8F6B891758);
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


### MIN_SQRT_RATIO
*The minimum value that can be returned from `getSqrtRatioAtTick`.*


```solidity
uint160 internal constant MIN_SQRT_RATIO = 4295128739;
```


### MAX_SQRT_RATIO
*The maximum value that can be returned from `getSqrtRatioAtTick`.*


```solidity
uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;
```


### tokens
========================== STORAGE ========================== ///

*DAO-governed token address naming.*


```solidity
mapping(string name => address) public tokens;
```


## Functions
### constructor

======================== CONSTRUCTOR ======================== ///

*Constructs
this implementation.*


```solidity
constructor() payable;
```

### previewCommand

====================== COMMAND PREVIEW ====================== ///

Preview natural language smart contract command.
The `send` syntax uses ENS naming: 'send vitalik 20 DAI'.
`swap` syntax uses common command: 'swap 100 DAI for WETH'.


```solidity
function previewCommand(string calldata intent)
    public
    view
    virtual
    returns (
        address to,
        uint256 amount,
        address token,
        bytes memory callData,
        bytes memory executeCallData
    );
```

### previewSend

*Previews a send command from the parts of a matched intent string.*


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

*Previews a swap command from the parts of a matched intent string.*


```solidity
function previewSwap(string memory amountIn, string memory tokenIn, string memory tokenOut)
    public
    view
    virtual
    returns (uint256 _amountIn, address _tokenIn, address _tokenOut);
```

### checkUserOp

*Checks ERC4337 userOp against the output of the command intent.*


```solidity
function checkUserOp(string calldata intent, UserOperation calldata userOp)
    public
    view
    virtual
    returns (bool);
```

### checkPackedUserOp

*Checks packed ERC4337 userOp against the output of the command intent.*


```solidity
function checkPackedUserOp(string calldata intent, PackedUserOperation calldata userOp)
    public
    view
    virtual
    returns (bool);
```

### _returnConstant

*Checks and returns the canonical constant for a matched intent string.*


```solidity
function _returnConstant(bytes32 token) internal view virtual returns (address _token);
```

### command

===================== COMMAND EXECUTION ===================== ///

*Executes a command from an intent string.*


```solidity
function command(string calldata intent) public payable virtual;
```

### send

*Executes a send command from the parts of a matched intent string.*


```solidity
function send(string memory to, string memory amount, string memory token) public payable virtual;
```

### swap

*Executes a swap command from the parts of a matched intent string.*


```solidity
function swap(string memory amountIn, string memory tokenIn, string memory tokenOut)
    public
    payable
    virtual;
```

### uniswapV3SwapCallback

*Callback for IUniswapV3PoolActions#swap.*


```solidity
function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data)
    public
    payable
    virtual;
```

### _computePoolAddress


```solidity
function _computePoolAddress(address tokenA, address tokenB)
    internal
    view
    virtual
    returns (address pool);
```

### whatIsMyBalanceIn

================== BALANCE & SUPPLY HELPERS ================== ///

*Returns your balance in a named token.*


```solidity
function whatIsMyBalanceIn(string calldata token)
    public
    view
    virtual
    returns (uint256 balance, uint256 balanceAdjusted);
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

### _balanceOf

*Returns the amount of ERC20/721 `token` owned by `account`.*


```solidity
function _balanceOf(address token, address account)
    internal
    view
    virtual
    returns (uint256 amount);
```

### _totalSupply

*Returns the total supply of ERC20/721 `token`.*


```solidity
function _totalSupply(address token) internal view virtual returns (uint256 supply);
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

### _extraction

================= INTERNAL STRING OPERATIONS ================= ///

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
    returns (string memory amountIn, string memory tokenIn, string memory tokenOut);
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

### _stringToUint

*Convert string to decimalized numerical value.*


```solidity
function _stringToUint(string memory s, uint8 decimals)
    internal
    pure
    virtual
    returns (uint256 result);
```

## Events
### NameSet
=========================== EVENTS =========================== ///

*Logs the registration of a token name.*


```solidity
event NameSet(address indexed token, string name);
```

## Errors
### Unauthorized
======================= LIBRARY USAGE ======================= ///

*Metadata reader library.*

*Safe token transfer library.
======================= CUSTOM ERRORS ======================= ///*

*Caller fails.*


```solidity
error Unauthorized();
```

### InvalidSyntax
*Invalid command form.*


```solidity
error InvalidSyntax();
```

### InvalidCharacter
*Non-numeric character.*


```solidity
error InvalidCharacter();
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

