# IENSHelper
[Git Source](https://github.com/NaniDAO/IE/blob/6051cf6b98d5ad3397f6672cbe7b981770473570/src/IE.sol)

*ENS name resolution helper contracts interface.*


## Functions
### addr


```solidity
function addr(bytes32) external view returns (address);
```

### ownerOf


```solidity
function ownerOf(uint256) external view returns (address);
```

### resolver


```solidity
function resolver(bytes32) external view returns (address);
```

### owner


```solidity
function owner(string calldata) external view returns (address, bytes32);
```

