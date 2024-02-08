# IE
[Git Source](https://github.com/NaniDAO/IE/blob/6051cf6b98d5ad3397f6672cbe7b981770473570/src/IE.sol)

**Author:**
nani.eth (https://github.com/NaniDAO/ie)

Simple helper contract for turning transactional intents into executable code.

*V0 simulates the output of typical commands (sending assets) and allows execution.
IE also has workflow to verify the intent of ERC-4337 account userOps against calldata.*


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


### NANI
*The NANI token address.*


```solidity
address internal constant NANI = 0x00000000000025824328358250920B271f348690;
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


### assets
========================== STORAGE ========================== ///

*DAO-governed asset address naming.*


```solidity
mapping(string name => address) public assets;
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

*Preview command. `Send` syntax uses ENS name: 'send vitalik 20 DAI'*


```solidity
function previewCommand(string calldata intent)
    public
    view
    virtual
    returns (
        address to,
        uint256 amount,
        address asset,
        bytes memory callData,
        bytes memory executeCallData
    );
```

### previewSend

*Returns formatted preview for send operations based on parts of command.*


```solidity
function previewSend(string memory to, string memory amount, string memory asset)
    public
    view
    virtual
    returns (
        address _to,
        uint256 _amount,
        address _asset,
        bytes memory callData,
        bytes memory executeCallData
    );
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

### _returnConstant

*Checks and returns the canonical constant for a matched intent string.*


```solidity
function _returnConstant(bytes32 asset) internal view virtual returns (address _asset);
```

### command

===================== COMMAND EXECUTION ===================== ///

*Executes a command from an intent string.*


```solidity
function command(string calldata intent) public payable virtual;
```

### send

*Executes a send command from the corresponding parts of a matched intent string.*


```solidity
function send(string memory to, string memory amount, string memory asset) public payable virtual;
```

### whatIsMyBalanceIn

================== BALANCE & SUPPLY HELPERS ================== ///

*Returns your balance in a named asset.*


```solidity
function whatIsMyBalanceIn(string calldata asset)
    public
    view
    virtual
    returns (uint256 balance, uint256 balanceAdjusted);
```

### whatIsTheBalanceOf

*Returns the balance of a named account in a named asset.*


```solidity
function whatIsTheBalanceOf(string calldata name, string calldata asset)
    public
    view
    virtual
    returns (uint256 balance, uint256 balanceAdjusted);
```

### whatIsTheTotalSupplyOf

*Returns the total supply of a named asset.*


```solidity
function whatIsTheTotalSupplyOf(string calldata asset)
    public
    view
    virtual
    returns (uint256 supply, uint256 supplyAdjusted);
```

### _balanceOf

*Returns the amount of ERC20/721 `asset` owned by `account`.*


```solidity
function _balanceOf(address asset, address account)
    internal
    view
    virtual
    returns (uint256 amount);
```

### _totalSupply

*Returns the total supply of ERC20/721 `asset`.*


```solidity
function _totalSupply(address asset) internal view virtual returns (uint256 supply);
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

*Sets a public name tag for a given asset address. Governed by DAO.*


```solidity
function setName(address asset, string calldata name) public payable virtual;
```

### _extractAction

================= INTERNAL STRING OPERATIONS ================= ///

*Extracts the first word (action) from a string.*


```solidity
function _extractAction(string memory normalizedIntent) internal pure virtual returns (bytes32);
```

### _extractSendInfo

*Extract the key words of normalized `send` intent.*


```solidity
function _extractSendInfo(string memory normalizedIntent)
    internal
    pure
    virtual
    returns (string memory to, string memory amount, string memory asset);
```

### _split

*Split the intent into an array of words.*


```solidity
function _split(string memory base, bytes1 value) internal pure virtual returns (string[] memory);
```

### _concat

*Perform string concatentation on base.*


```solidity
function _concat(string memory base, bytes1 value) internal pure virtual returns (string memory);
```

### _stringToUint

*Convert string to decimalized numerical value.*


```solidity
function _stringToUint(string memory s, uint8 decimals) internal pure virtual returns (uint256);
```

## Events
### NameSet
=========================== EVENTS =========================== ///

*Logs the registration of an asset name.*


```solidity
event NameSet(address indexed asset, string name);
```

## Errors
### Unauthorized
======================= LIBRARY USAGE ======================= ///

*Metadata reader library.*

*Safe asset transfer library.
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

