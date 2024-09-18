# IEBase
[Git Source](https://github.com/NaniDAO/ie/blob/58175fad32cfeea89f1d83e288aec227fe545300/src/IEBase.sol)

**Author:**
nani.eth (https://github.com/NaniDAO/ie)

Simple helper contract for turning transactional intents into executable code.

*V2 simulates typical commands (sending and swapping tokens) and includes execution.
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


### CBBTC
*The Coinbase wrapped BTC address.*


```solidity
address internal constant CBBTC = 0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf;
```


### TBTC
*The threshold wrapped BTC address.*


```solidity
address internal constant TBTC = 0x236aa50979D5f3De3Bd1Eeb40E81137F22ab794b;
```


### USDC
*The Circle USD stablecoin address.*


```solidity
address internal constant USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
```


### USDT
*The Tether USD stablecoin address.*


```solidity
address internal constant USDT = 0xfde4C96c8593536E31F229EA8f37b2ADa2699bb2;
```


### DAI
*The Maker DAO USD stablecoin address.*


```solidity
address internal constant DAI = 0x50c5725949A6F0c72E6C4a641F24049A917DB0Cb;
```


### CBETH
*The Coinbase wrapped staked ETH token address.*


```solidity
address internal constant CBETH = 0x2Ae3F1Ec7F1F5012CFEab0185bfc7aa3cf0DEc22;
```


### WSTETH
*The Lido wrapped staked ETH token address.*


```solidity
address internal constant WSTETH = 0xc1CBa3fCea344f92D9239c08C0568f6F2F0ee452;
```


### CURIA
*The resolution registry smart account.*


```solidity
address internal constant CURIA = 0x0000000000001d8a2e7bf6bc369525A2654aa298;
```


### ESCROWS
*The Escrows protocol singleton.*


```solidity
address internal constant ESCROWS = 0x00000000000044992CB97CB1A57A32e271C04c11;
```


### _REENTRANCY_GUARD_SLOT
*Equivalent to: `uint72(bytes9(keccak256("_REENTRANCY_GUARD_SLOT")))`.*


```solidity
uint256 internal constant _REENTRANCY_GUARD_SLOT = 0x929eee149b4bd21268;
```


### UNISWAP_V3_FACTORY
*The address of the Uniswap V3 Factory.*


```solidity
address internal constant UNISWAP_V3_FACTORY = 0x33128a8fC17869897dcE68Ed026d694621f6FDfD;
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


### BASE_ENS
*The L2Resolver for `base.eth` domains.*


```solidity
address internal constant BASE_ENS = 0xC6d566A56A1aFf6508b41f6c90ff131615583BCD;
```


### BASE_ENS_REVERSE
*The ReverseRegistrar for `base.eth` domains.*


```solidity
address internal constant BASE_ENS_REVERSE = 0x79EA96012eEa67A83431F1701B3dFf7e37F9E282;
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


### orders
*Open order book for p2p asset exchange.*


```solidity
mapping(bytes32 orderHash => Order) public orders;
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


### orderHashes
*Array of onchain order struct hashes.*


```solidity
bytes32[] public orderHashes;
```


## Functions
### constructor

======================== CONSTRUCTOR ======================== ///

*Constructs this IE on the Base L2 of Ethereum with ENS `ASCII_MAP`.*


```solidity
constructor() payable;
```

### previewCommand

====================== COMMAND PREVIEW ====================== ///

*Preview natural language smart contract command.
The `send` syntax uses ENS naming: 'send vitalik 20 DAI'.
`swap` syntax uses common format: 'swap 100 DAI for WETH'.
`lock` syntax uses send format: 'lock 1 WETH for vitalik'.*


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

### _previewLock

*Previews a `lock` command from the parts of a matched intent string.*


```solidity
function _previewLock(
    bytes memory to,
    bytes memory amount,
    bytes memory token,
    bytes memory time,
    bytes memory unit
) internal view virtual returns (address _to, uint256 _amount, address _token, uint256 _expiry);
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

*Checks packed ERC4337 userOp against the output of the command intent.
note: This function checks ETH and ERC20 transfers only with `execute()`.*


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

### lock

*Executes a `lock` command from the parts of a matched intent string.*


```solidity
function lock(
    string memory to,
    string memory amount,
    string memory token,
    string memory time,
    string memory unit
) public payable virtual returns (bytes32);
```

### escrow

*Executes an `escrow` command from the parts of a matched intent string.*


```solidity
function escrow(
    string memory to,
    string memory amount,
    string memory token,
    string memory time,
    string memory unit
) public payable virtual returns (bytes32);
```

### _escrow

*Handles either a `lock` or `escrow` command via Escrows protocol.*


```solidity
function _escrow(
    bytes memory to,
    bytes memory amount,
    bytes memory token,
    bytes memory time,
    bytes memory unit,
    bool lockup
) internal virtual returns (bytes32);
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

### nonReentrant

*Guards a function from reentrancy.*


```solidity
modifier nonReentrant() virtual;
```

### order

*Executes an `order` command from the parts of a matched intent string.*


```solidity
function order(
    string memory tokenIn,
    string memory tokenOut,
    string memory amountIn,
    string memory amountOut,
    string memory receiver
) public payable nonReentrant returns (bytes32 hash);
```

### cancelOrder

*Cancels a standing order by the `maker`.*


```solidity
function cancelOrder(bytes32 hash) public nonReentrant;
```

### executeOrder

*Executes a standing order for the `receiver`.*


```solidity
function executeOrder(bytes32 hash) public payable nonReentrant;
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

### whatIsTheNameOf

*Returns ENS reverse name resolution details.*


```solidity
function whatIsTheNameOf(address user) public view virtual returns (string memory);
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

### _extractLock

*Extract the key words of normalized `lock` intent.*


```solidity
function _extractLock(bytes memory normalizedIntent)
    internal
    pure
    virtual
    returns (
        bytes memory to,
        bytes memory amount,
        bytes memory token,
        bytes memory time,
        bytes memory unit
    );
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

### _simpleToUint256

*Simple bytes string converter for time units.*


```solidity
function _simpleToUint256(bytes memory b) internal pure virtual returns (uint256);
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

### Unauthorized
*Invalid function caller.*


```solidity
error Unauthorized();
```

### OrderExpired
*Order expiry has arrived.*


```solidity
error OrderExpired();
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

### Reentrancy
*Unauthorized reentrant call.*


```solidity
error Reentrancy();
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

### Order
*The onchain order struct.*


```solidity
struct Order {
    address tokenIn;
    address tokenOut;
    uint256 amountIn;
    uint256 amountOut;
    address maker;
    address receiver;
    uint48 nonce;
    uint48 expiry;
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

