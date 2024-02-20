// ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘
// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.24;

import {SafeTransferLib} from "../lib/solady/src/utils/SafeTransferLib.sol";
import {MetadataReaderLib} from "../lib/solady/src/utils/MetadataReaderLib.sol";

/// @title Intents Engine (IE)
/// @notice Simple helper contract for turning transactional intents into executable code.
/// @dev V1 simulates typical commands (sending and swapping tokens) and includes execution.
/// IE also has a workflow to verify the intent of ERC4337 account userOps against calldata.
/// @author nani.eth (https://github.com/NaniDAO/ie)
/// @custom:version 1.1.0
contract IE {
    /// ======================= LIBRARY USAGE ======================= ///

    /// @dev Metadata reader library.
    using MetadataReaderLib for address;

    /// @dev Safe token transfer library.
    using SafeTransferLib for address;

    /// ======================= CUSTOM ERRORS ======================= ///

    /// @dev Bad math.
    error Overflow();

    /// @dev Caller fails.
    error Unauthorized();

    /// @dev 0-liquidity.
    error InvalidSwap();

    /// @dev Invalid command.
    error InvalidSyntax();

    /// @dev Non-numeric character.
    error InvalidCharacter();

    /// @dev Insufficient swap output.
    error InsufficientSwap();

    /// =========================== EVENTS =========================== ///

    /// @dev Logs the registration of a token name.
    event NameSet(address indexed token, string name);

    /// ========================== STRUCTS ========================== ///

    /// @dev The ERC4337 user operation (userOp) struct.
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

    /// @dev The packed ERC4337 user operation (userOp) struct.
    struct PackedUserOperation {
        address sender;
        uint256 nonce;
        bytes initCode;
        bytes callData;
        bytes32 accountGasLimits;
        uint256 preVerificationGas;
        bytes32 gasFees; // `maxPriorityFee` and `maxFeePerGas`.
        bytes paymasterAndData;
        bytes signature;
    }

    /// @dev The `swap` command details.
    struct SwapDetails {
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        bool ETHIn;
        bool ETHOut;
    }

    /// ========================= CONSTANTS ========================= ///

    /// @dev The governing DAO address.
    address internal constant DAO = 0xDa000000000000d2885F108500803dfBAaB2f2aA;

    /// @dev The NANI token address.
    address internal constant NANI = 0x00000000000025824328358250920B271f348690;

    /// @dev The NANI naming system on Arbitrum.
    address internal constant NAMES = 0x871E6ba1a81DD52C7eeeBD6f37c5CeFE11207b90;

    /// @dev The conventional ERC7528 ETH address.
    address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @dev The canonical wrapped ETH address.
    address internal constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;

    /// @dev The popular wrapped BTC address.
    address internal constant WBTC = 0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f;

    /// @dev The Circle USD stablecoin address.
    address internal constant USDC = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;

    /// @dev The Tether USD stablecoin address.
    address internal constant USDT = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;

    /// @dev The Maker DAO USD stablecoin address.
    address internal constant DAI = 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1;

    /// @dev The Arbitrum DAO governance token address.
    address internal constant ARB = 0x912CE59144191C1204E64559FE8253a0e49E6548;

    /// @dev The address of the Uniswap V3 Factory.
    address internal constant UNISWAP_V3_FACTORY = 0x1F98431c8aD98523631AE4a59f267346ea31F984;

    /// @dev The Uniswap V3 Pool `initcodehash`.
    bytes32 internal constant UNISWAP_V3_POOL_INIT_CODE_HASH =
        0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

    /// @dev The minimum value that can be returned from `getSqrtRatioAtTick` (plus one).
    uint160 internal constant MIN_SQRT_RATIO_PLUS_ONE = 4295128740;

    /// @dev The maximum value that can be returned from `getSqrtRatioAtTick` (minus one).
    uint160 internal constant MAX_SQRT_RATIO_MINUS_ONE =
        1461446703485210103287273052203988822378723970341;

    /// ========================== STORAGE ========================== ///

    /// @dev DAO-governed token address naming.
    mapping(string name => address) public tokens;

    /// ======================== CONSTRUCTOR ======================== ///

    /// @dev Constructs this IE on the Arbitrum L2 of Ethereum.
    constructor() payable {}

    /// ====================== COMMAND PREVIEW ====================== ///

    /// @notice Preview natural language smart contract command.
    /// The `send` syntax uses ENS naming: 'send vitalik 20 DAI'.
    /// `swap` syntax uses common format: 'swap 100 DAI for WETH'.
    function previewCommand(string calldata intent)
        public
        view
        virtual
        returns (
            address to, // Receiver address.
            uint256 amount, // Formatted amount.
            uint256 minAmountOut, // Formatted amount.
            address token, // Asset to send `to`.
            bytes memory callData, // Raw calldata for send transaction.
            bytes memory executeCallData // Anticipates common execute API.
        )
    {
        string memory normalized = _lowercase(intent);
        bytes32 action = _extraction(normalized);
        if (action == "send" || action == "transfer") {
            (string memory _to, string memory _amount, string memory _token) =
                _extractSend(normalized);
            (to, amount, token, callData, executeCallData) = previewSend(_to, _amount, _token);
        } else if (action == "swap" || action == "exchange") {
            (
                string memory amountIn,
                string memory amountOutMinimum,
                string memory tokenIn,
                string memory tokenOut
            ) = _extractSwap(normalized);
            (amount, minAmountOut, token, to) =
                previewSwap(amountIn, amountOutMinimum, tokenIn, tokenOut);
        } else {
            revert InvalidSyntax(); // Invalid command format.
        }
    }

    /// @dev Previews a `send` command from the parts of a matched intent string.
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
        )
    {
        _token = _returnTokenConstant(bytes32(bytes(token))); // Check constant.
        if (_token == address(0)) _token = tokens[token]; // Check storage.
        bool isETH = _token == ETH; // Memo whether the token is ETH or not.
        (, _to,) = whatIsTheAddressOf(to); // Fetch receiver address from ENS.
        _amount = _stringToUint(amount, isETH ? 18 : _token.readDecimals());
        if (!isETH) callData = abi.encodeCall(IToken.transfer, (_to, _amount));
        executeCallData =
            abi.encodeCall(IExecutor.execute, (isETH ? _to : _token, isETH ? _amount : 0, callData));
    }

    /// @dev Previews a `swap` command from the parts of a matched intent string.
    function previewSwap(
        string memory amountIn,
        string memory amountOutMinimum,
        string memory tokenIn,
        string memory tokenOut
    )
        public
        view
        virtual
        returns (uint256 _amountIn, uint256 _amountOut, address _tokenIn, address _tokenOut)
    {
        _tokenIn = _returnTokenConstant(bytes32(bytes(tokenIn)));
        if (_tokenIn == address(0)) _tokenIn = tokens[tokenIn];
        _tokenOut = _returnTokenConstant(bytes32(bytes(tokenOut)));
        if (_tokenOut == address(0)) _tokenOut = tokens[tokenOut];
        _amountIn = _stringToUint(amountIn, _tokenIn == ETH ? 18 : _tokenIn.readDecimals());
        _amountOut =
            _stringToUint(amountOutMinimum, _tokenOut == ETH ? 18 : _tokenOut.readDecimals());
    }

    /// @dev Checks ERC4337 userOp against the output of the command intent.
    function checkUserOp(string calldata intent, UserOperation calldata userOp)
        public
        view
        virtual
        returns (bool)
    {
        (,,,,, bytes memory executeCallData) = previewCommand(intent);
        if (executeCallData.length != userOp.callData.length) return false;
        return keccak256(executeCallData) == keccak256(userOp.callData);
    }

    /// @dev Checks packed ERC4337 userOp against the output of the command intent.
    function checkPackedUserOp(string calldata intent, PackedUserOperation calldata userOp)
        public
        view
        virtual
        returns (bool)
    {
        (,,,,, bytes memory executeCallData) = previewCommand(intent);
        if (executeCallData.length != userOp.callData.length) return false;
        return keccak256(executeCallData) == keccak256(userOp.callData);
    }

    /// @dev Checks and returns the canonical token address constant for a matched intent string.
    function _returnTokenConstant(bytes32 token) internal view virtual returns (address _token) {
        if (token == "eth" || token == "ether") return ETH;
        if (token == "usdc") return USDC;
        if (token == "usdt") return USDT;
        if (token == "dai") return DAI;
        if (token == "arb" || token == "arbitrum") return ARB;
        if (token == "nani") return NANI;
        if (token == "weth") return WETH;
        if (token == "wbtc" || token == "btc" || token == "bitcoin") return WBTC;
    }

    /// ===================== COMMAND EXECUTION ===================== ///

    /// @dev Executes a text command from an intent string.
    function command(string calldata intent) public payable virtual {
        string memory normalized = _lowercase(intent);
        bytes32 action = _extraction(normalized);
        if (action == "send" || action == "transfer") {
            (string memory to, string memory amount, string memory token) = _extractSend(normalized);
            send(to, amount, token);
        } else if (action == "swap" || action == "exchange") {
            (
                string memory amountIn,
                string memory amountOutMinimum,
                string memory tokenIn,
                string memory tokenOut
            ) = _extractSwap(normalized);
            swap(amountIn, amountOutMinimum, tokenIn, tokenOut);
        } else {
            revert InvalidSyntax(); // Invalid command format.
        }
    }

    /// @dev Executes a `send` command from the parts of a matched intent string.
    function send(string memory to, string memory amount, string memory token)
        public
        payable
        virtual
    {
        address _token = _returnTokenConstant(bytes32(bytes(token)));
        if (_token == address(0)) _token = tokens[token];
        (, address _to,) = whatIsTheAddressOf(to);
        if (_token == ETH) {
            _to.safeTransferETH(_stringToUint(amount, 18));
        } else {
            _token.safeTransferFrom(msg.sender, _to, _stringToUint(amount, _token.readDecimals()));
        }
    }

    /// @dev Executes a `swap` command from the parts of a matched intent string.
    function swap(
        string memory amountIn,
        string memory amountOutMinimum,
        string memory tokenIn,
        string memory tokenOut
    ) public payable virtual {
        SwapDetails memory details;
        details.tokenIn = _returnTokenConstant(bytes32(bytes(tokenIn)));
        if (details.tokenIn == address(0)) details.tokenIn = tokens[tokenIn];
        details.tokenOut = _returnTokenConstant(bytes32(bytes(tokenOut)));
        if (details.tokenOut == address(0)) details.tokenOut = tokens[tokenOut];

        details.ETHIn = details.tokenIn == ETH;
        if (details.ETHIn) details.tokenIn = WETH;
        details.ETHOut = details.tokenOut == ETH;
        if (details.ETHOut) details.tokenOut = WETH;

        details.amountIn =
            _stringToUint(amountIn, details.ETHIn ? 18 : details.tokenIn.readDecimals());
        if (details.amountIn >= 1 << 255) revert Overflow();
        (address pool, bool zeroForOne) = _computePoolAddress(details.tokenIn, details.tokenOut);
        (int256 amount0, int256 amount1) = ISwapRouter(pool).swap(
            !details.ETHOut ? msg.sender : address(this),
            zeroForOne,
            int256(details.amountIn),
            zeroForOne ? MIN_SQRT_RATIO_PLUS_ONE : MAX_SQRT_RATIO_MINUS_ONE,
            abi.encodePacked(
                details.ETHIn, details.ETHOut, msg.sender, details.tokenIn, details.tokenOut
            )
        );
        if (
            uint256(-(zeroForOne ? amount1 : amount0))
                < _stringToUint(amountOutMinimum, details.ETHOut ? 18 : details.tokenOut.readDecimals())
        ) revert InsufficientSwap();
    }

    /// @dev Fallback `uniswapV3SwapCallback`.
    /// If ETH is swapped, WETH is forwarded.
    fallback() external payable virtual {
        int256 amount0Delta;
        int256 amount1Delta;
        bool ETHIn;
        bool ETHOut;
        address payer;
        address tokenIn;
        address tokenOut;
        assembly ("memory-safe") {
            amount0Delta := calldataload(0x4)
            amount1Delta := calldataload(0x24)
            ETHIn := byte(0, calldataload(0x84))
            ETHOut := byte(0, calldataload(add(0x84, 1)))
            payer := shr(96, calldataload(add(0x84, 2)))
            tokenIn := shr(96, calldataload(add(0x84, 22)))
            tokenOut := shr(96, calldataload(add(0x84, 42)))
        }
        if (amount0Delta <= 0 && amount1Delta <= 0) revert InvalidSwap();
        (address pool, bool zeroForOne) = _computePoolAddress(tokenIn, tokenOut);
        if (msg.sender != pool) revert Unauthorized(); // Only pair pool can call.
        if (ETHIn) {
            _wrapETH(uint256(zeroForOne ? amount0Delta : amount1Delta));
        } else {
            tokenIn.safeTransferFrom(
                payer, msg.sender, uint256(zeroForOne ? amount0Delta : amount1Delta)
            );
        }
        if (ETHOut) {
            uint256 amount = uint256(-(zeroForOne ? amount1Delta : amount0Delta));
            _unwrapETH(amount);
            payer.safeTransferETH(amount);
        }
    }

    /// @dev Computes the create2 address for given token pair.
    function _computePoolAddress(address tokenA, address tokenB)
        internal
        view
        virtual
        returns (address pool, bool zeroForOne)
    {
        if (tokenA < tokenB) zeroForOne = true;
        else (tokenA, tokenB) = (tokenB, tokenA);
        pool = _computePairHash(tokenA, tokenB, 500); // Low fee.
        if (pool.code.length != 0) return (pool, zeroForOne);
        else pool = _computePairHash(tokenA, tokenB, 3000); // Mid fee.
        if (pool.code.length != 0) return (pool, zeroForOne);
        else pool = _computePairHash(tokenA, tokenB, 100); // Lowest fee.
        if (pool.code.length != 0) return (pool, zeroForOne);
        else pool = _computePairHash(tokenA, tokenB, 10000); // Highest fee.
        if (pool.code.length != 0) return (pool, zeroForOne);
    }

    /// @dev Computes the create2 deployment hash for given token pair.
    function _computePairHash(address token0, address token1, uint24 fee)
        internal
        pure
        virtual
        returns (address pool)
    {
        bytes32 salt = keccak256(abi.encode(token0, token1, fee));
        assembly ("memory-safe") {
            mstore8(0x00, 0xff) // Write the prefix.
            mstore(0x35, UNISWAP_V3_POOL_INIT_CODE_HASH)
            mstore(0x01, shl(96, UNISWAP_V3_FACTORY))
            mstore(0x15, salt)
            pool := keccak256(0x00, 0x55)
            mstore(0x35, 0) // Restore overwritten.
        }
    }

    /// @dev Wraps an `amount` of ETH to WETH and funds pool caller for swap.
    function _wrapETH(uint256 amount) internal virtual {
        assembly ("memory-safe") {
            pop(call(gas(), WETH, amount, codesize(), 0x00, codesize(), 0x00))
            mstore(0x14, caller()) // Store the `pool` argument.
            mstore(0x34, amount) // Store the `amount` argument.
            mstore(0x00, 0xa9059cbb000000000000000000000000) // `transfer(address,uint256)`.
            pop(call(gas(), WETH, 0, 0x10, 0x44, codesize(), 0x00))
            mstore(0x34, 0) // Restore the part of the free memory pointer that was overwritten.
        }
    }

    /// @dev Unwraps an `amount` of ETH from WETH for return.
    function _unwrapETH(uint256 amount) internal virtual {
        assembly ("memory-safe") {
            mstore(0x00, 0x2e1a7d4d) // `withdraw(uint256)`.
            mstore(0x20, amount) // Store the `amount` argument.
            pop(call(gas(), WETH, 0, 0x1c, 0x24, codesize(), 0x00))
        }
    }

    /// @dev ETH receiver fallback.
    receive() external payable virtual {
        if (msg.sender != WETH) revert Unauthorized();
    }

    /// ================== BALANCE & SUPPLY HELPERS ================== ///

    /// @dev Returns the balance of a named account in a named token.
    function whatIsTheBalanceOf(string calldata name, /*(bob)*/ /*in*/ string calldata token)
        public
        view
        virtual
        returns (uint256 balance, uint256 balanceAdjusted)
    {
        (, address _name,) = whatIsTheAddressOf(name);
        string memory normalized = _lowercase(token);
        address _token = _returnTokenConstant(bytes32(bytes(normalized)));
        if (_token == address(0)) _token = tokens[token];
        bool isETH = _token == ETH;
        balance = isETH ? _name.balance : _token.balanceOf(_name);
        balanceAdjusted = balance / 10 ** (isETH ? 18 : _token.readDecimals());
    }

    /// @dev Returns the total supply of a named token.
    function whatIsTheTotalSupplyOf(string calldata token)
        public
        view
        virtual
        returns (uint256 supply, uint256 supplyAdjusted)
    {
        address _token = _returnTokenConstant(bytes32(bytes(token)));
        if (_token == address(0)) _token = tokens[token];
        if (_token == ETH) revert InvalidSyntax();
        assembly ("memory-safe") {
            mstore(0x00, 0x18160ddd) // `totalSupply()`.
            if iszero(staticcall(gas(), _token, 0x1c, 0x04, 0x20, 0x20)) {
                revert(codesize(), 0x00)
            }
            supply := mload(0x20)
        }
        supplyAdjusted = supply / 10 ** _token.readDecimals();
    }

    /// ====================== ENS VERIFICATION ====================== ///

    /// @dev Returns ENS name ownership details.
    function whatIsTheAddressOf(string memory name)
        public
        view
        virtual
        returns (address owner, address receiver, bytes32 node)
    {
        (owner, receiver, node) = INames(NAMES).whatIsTheAddressOf(name);
    }

    /// ========================= GOVERNANCE ========================= ///

    /// @dev Sets a public `name` tag for a given `token` address. Governed by DAO.
    function setName(address token, string calldata name) public payable virtual {
        if (msg.sender != DAO) revert Unauthorized();
        string memory normalized = _lowercase(name);
        emit NameSet(tokens[normalized] = token, normalized);
    }

    /// @dev Sets a public name and ticker for a given `token` address.
    function setNameAndTicker(address token) public payable virtual {
        string memory normalizedName = _lowercase(token.readName());
        string memory normalizedSymbol = _lowercase(token.readSymbol());
        emit NameSet(tokens[normalizedName] = token, normalizedName);
        emit NameSet(tokens[normalizedSymbol] = token, normalizedSymbol);
    }

    /// ===================== STRING OPERATIONS ===================== ///

    /// @dev Returns copy of string in lowercase.
    /// Modified from Solady LibString `toCase`.
    function _lowercase(string memory subject)
        internal
        pure
        virtual
        returns (string memory result)
    {
        assembly ("memory-safe") {
            let length := mload(subject)
            if length {
                result := add(mload(0x40), 0x20)
                subject := add(subject, 1)
                let flags := shl(add(70, shl(5, 0)), 0x3ffffff)
                let w := not(0)
                for { let o := length } 1 {} {
                    o := add(o, w)
                    let b := and(0xff, mload(add(subject, o)))
                    mstore8(add(result, o), xor(b, and(shr(b, flags), 0x20)))
                    if iszero(o) { break }
                }
                result := mload(0x40)
                mstore(result, length) // Store the length.
                let last := add(add(result, 0x20), length)
                mstore(last, 0) // Zeroize the slot after the string.
                mstore(0x40, add(last, 0x20)) // Allocate the memory.
            }
        }
    }

    /// @dev Extracts the first word (action) as bytes32.
    function _extraction(string memory normalizedIntent)
        internal
        pure
        virtual
        returns (bytes32 result)
    {
        assembly ("memory-safe") {
            let str := add(normalizedIntent, 0x20)
            for { let i } lt(i, 0x20) { i := add(i, 1) } {
                let char := byte(0, mload(add(str, i)))
                if eq(char, 0x20) { break }
                result := or(result, shl(sub(248, mul(i, 8)), char))
            }
        }
    }

    /// @dev Extract the key words of normalized `send` intent.
    function _extractSend(string memory normalizedIntent)
        internal
        pure
        virtual
        returns (string memory to, string memory amount, string memory token)
    {
        string[] memory parts = _split(normalizedIntent, " ");
        if (parts.length == 4) return (parts[1], parts[2], parts[3]);
        if (parts.length == 5) return (parts[4], parts[1], parts[2]);
        else revert InvalidSyntax(); // Command is not formatted.
    }

    /// @dev Extract the key words of normalized `swap` intent.
    function _extractSwap(string memory normalizedIntent)
        internal
        pure
        virtual
        returns (
            string memory amountIn,
            string memory amountOutMinimum,
            string memory tokenIn,
            string memory tokenOut
        )
    {
        string[] memory parts = _split(normalizedIntent, " ");
        if (parts.length == 5) return (parts[1], "", parts[2], parts[4]);
        if (parts.length == 6) return (parts[1], parts[4], parts[2], parts[5]);
        else revert InvalidSyntax(); // Command is not formatted.
    }

    /// @dev Split the intent into an array of words.
    function _split(string memory base, bytes1 delimiter)
        internal
        pure
        virtual
        returns (string[] memory parts)
    {
        unchecked {
            bytes memory baseBytes = bytes(base);
            uint256 count = 1;
            for (uint256 i; i != baseBytes.length; ++i) {
                if (baseBytes[i] == delimiter) {
                    ++count;
                }
            }
            parts = new string[](count);
            uint256 partIndex;
            uint256 start;
            for (uint256 i; i <= baseBytes.length; ++i) {
                if (i == baseBytes.length || baseBytes[i] == delimiter) {
                    bytes memory part = new bytes(i - start);
                    for (uint256 j = start; j != i; ++j) {
                        part[j - start] = baseBytes[j];
                    }
                    parts[partIndex] = string(part);
                    ++partIndex;
                    start = i + 1;
                }
            }
        }
    }

    /// @dev Convert string to decimalized numerical value.
    function _stringToUint(string memory s, uint8 decimals)
        internal
        pure
        virtual
        returns (uint256 result)
    {
        unchecked {
            bool hasDecimal;
            uint256 decimalPlaces;
            bytes memory b = bytes(s);
            for (uint256 i; i != b.length; ++i) {
                if (b[i] >= "0" && b[i] <= "9") {
                    result = result * 10 + uint8(b[i]) - 48;
                    if (hasDecimal) {
                        ++decimalPlaces;
                        if (decimalPlaces > decimals) {
                            break;
                        }
                    }
                } else if (b[i] == "." && !hasDecimal) {
                    hasDecimal = true;
                } else {
                    revert InvalidCharacter();
                }
            }
            if (decimalPlaces < decimals) {
                result *= 10 ** (decimals - decimalPlaces);
            }
        }
    }
}

/// @dev Simple token transfer interface.
interface IToken {
    function transfer(address, uint256) external returns (bool);
}

/// @notice Simple calldata executor interface.
interface IExecutor {
    function execute(address, uint256, bytes calldata) external payable returns (bytes memory);
}

/// @dev Simple Names interface for resolving L2 ENS ownership.
interface INames {
    function whatIsTheAddressOf(string calldata)
        external
        view
        returns (address, address, bytes32);
}

/// @dev Simple Uniswap V3 swapping interface.
interface ISwapRouter {
    function swap(address, bool, int256, uint160, bytes calldata)
        external
        returns (int256, int256);
}
