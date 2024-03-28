# NAMI
[Git Source](https://github.com/NaniDAO/ie/blob/f061f69f55a660146bbc3247dded252faef04a99/src/NAMI.sol)

**Author:**
nani.eth (https://github.com/NaniDAO/ie)

A contract for managing ENS domain name ownership and resolution on Arbitrum L2.

*Provides logic for registering names, verifying ownership, and resolving addresses.*


## State Variables
### DAO
========================= CONSTANTS ========================= ///

*The governing DAO address.*


```solidity
address internal constant DAO = 0xDa000000000000d2885F108500803dfBAaB2f2aA;
```


### L1_DEPLOYER
*L1_DEPLOYER represents the address responsible for deploying ENS proxy contracts on Ethereum Layer 1.
This address is typically used in conjunction with create2 operations for deterministic deployment.*


```solidity
address internal constant L1_DEPLOYER = 0x000000008B009D81C933a72545Ed7500cbB5B9D1;
```


### L2_DEPLOYER
*L2_DEPLOYER denotes the address that performs bridged ENS deployments on Arbitrum Layer 2.
Similar to L1_DEPLOYER, it's crucial for deterministic deployment but within the Arbitrum L2 context.*


```solidity
address internal constant L2_DEPLOYER = 0x3fE38087A94903A9D946fa1915e1772fe611000f;
```


### IMPLEMENTATION
*IMPLEMENTATION refers to the address of the contract serving as the implementation for ENS proxies.*


```solidity
address internal constant IMPLEMENTATION = 0xEBb49317E567a40cF468c409409aD59a8f67ddE6;
```


### COUNTERPART_GATEWAY
*COUNTERPART_GATEWAY is the address of the gateway contract on Arbitrum Layer 2 that pairs with a corresponding
gateway on Ethereum Layer 1. This gateway facilitates the bridging of tokens between L1 and L2, managing the
lock/mint and burn/release mechanics across layers.*


```solidity
address internal constant COUNTERPART_GATEWAY = 0x09e9222E96E7B4AE2a407B98d48e330053351EEe;
```


### L2_HASH
*L2_HASH is a unique identifier, used as part of the create2 address computation for contracts on Arbitrum Layer 2.*


```solidity
bytes32 internal constant L2_HASH =
    0x4b11cb57b978697e0aec0c18581326376d6463fd3f6699cbe78ee5935617082d;
```


### ASCII_MAP
*String mapping for `ENSAsciiNormalizer` logic.*


```solidity
bytes internal constant ASCII_MAP =
    hex"2d00020101000a010700016101620163016401650166016701680169016a016b016c016d016e016f0170017101720173017401750176017701780179017a06001a010500";
```


### _idnamap
========================== STORAGE ========================== ///

*Each index in idnamap refers to an ascii code point.
If idnamap[char] > 2, char maps to a valid ascii character.
Otherwise, idna[char] returns Rule.DISALLOWED or Rule.VALID.
Modified from `ENSAsciiNormalizer` deployed by royalfork.eth
(0x4A5cae3EC0b144330cf1a6CeAD187D8F6B891758).*


```solidity
bytes1[] internal _idnamap;
```


### _owners
*Internal mapping of registered node owners.*


```solidity
mapping(bytes32 node => Ownership) internal _owners;
```


## Functions
### constructor

======================== CONSTRUCTOR ======================== ///

*Constructs this IE with `ASCII_MAP`.*


```solidity
constructor() payable;
```

### whatIsTheAddressOf

====================== ENS VERIFICATION ====================== ///

*Returns ENS name ownership information.*


```solidity
function whatIsTheAddressOf(string calldata name)
    public
    view
    virtual
    returns (address _owner, address _receiver, bytes32 _node);
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

### register

======================== REGISTRATION ======================== ///

*Registers a name node under an owner. ENS L1 node must be bridged.*


```solidity
function register(address _owner, bytes32 _node) public payable virtual;
```

### registerSub

*Registers a name subnode under an owner. Only the DAO may call this function.*


```solidity
function registerSub(address _owner, string calldata _subname) public payable virtual;
```

### owner

====================== OWNERSHIP LOGIC ====================== ///

*Returns the registered owner of a given ENS L1 node. Must be bridged.
note: Alternatively, NAMI provides subdomains issued under `nani.eth` node.*


```solidity
function owner(bytes32 _node) public view virtual returns (address _owner);
```

### isOwner

*Checks if an address is the owner of a given ENS L1 node represented as `l2Token`.
note: NAMI operates under the assumption that the proper owner-receiver holds majority.*


```solidity
function isOwner(address _owner, bytes32 _node) public view virtual returns (bool);
```

### predictDeterministicAddresses

*Returns the deterministic create2 addresses for ENS node tokens on L1 & L2.*


```solidity
function predictDeterministicAddresses(bytes32 _node)
    public
    pure
    virtual
    returns (address l1Token, address l2Token);
```

### _predictDeterministicAddress

*Returns the predicted address on L1 using CWIA pattern.*


```solidity
function _predictDeterministicAddress(bytes32 hash, bytes32 salt)
    internal
    pure
    virtual
    returns (address predicted);
```

### _initCodeHash

*Returns the initCodeHash for the predicted address on L1 using CWIA pattern.*


```solidity
function _initCodeHash(bytes memory data) internal pure virtual returns (bytes32 hash);
```

### _calculateL2TokenAddress

*Returns the predicted `l2Token` address using Arbitrum create2 bridge preview methods on `l1Token`.*


```solidity
function _calculateL2TokenAddress(address l1Token)
    internal
    pure
    virtual
    returns (address l2Token);
```

## Events
### Registered
=========================== EVENTS =========================== ///

*Logs the registration of a name node into ownership.*


```solidity
event Registered(bytes32 indexed node, Ownership ownership);
```

## Errors
### Unregistered
======================= CUSTOM ERRORS ======================= ///

*Unregistered.*


```solidity
error Unregistered();
```

## Structs
### Ownership
========================== STRUCTS ========================== ///

*The name node ownership information struct.*


```solidity
struct Ownership {
    address owner;
    bool subnode;
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

