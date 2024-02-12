# IENSHelper
[Git Source](https://github.com/NaniDAO/IE/blob/fe9aa8f819c0b0c1f1baab80820f73546caaabc2/src/IE.sol)

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

