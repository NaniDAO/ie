# ISwapRouter
[Git Source](https://github.com/NaniDAO/IE/blob/fe9aa8f819c0b0c1f1baab80820f73546caaabc2/src/IE.sol)

*Simple Uniswap V3 swapping interface.*


## Functions
### swap


```solidity
function swap(
    address recipient,
    bool zeroForOne,
    int256 amountSpecified,
    uint160 sqrtPriceLimitX96,
    bytes calldata data
) external returns (int256 amount0, int256 amount1);
```

