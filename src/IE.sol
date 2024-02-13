// ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘
// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {LibString} from "../lib/solady/src/utils/LibString.sol";
import {SafeTransferLib} from "../lib/solady/src/utils/SafeTransferLib.sol";
import {MetadataReaderLib} from "../lib/solady/src/utils/MetadataReaderLib.sol";

/// @title Intents Engine (IE)
/// @notice Simple helper contract for turning transactional intents into executable code.
/// @dev V1 simulates typical commands (sending and swapping tokens) and includes execution.
/// IE also has a workflow to verify the intent of ERC4337 account userOps against calldata.
/// @author nani.eth (https://github.com/NaniDAO/ie)
/// @custom:version 1.0.0
contract IE {
    /// ======================= LIBRARY USAGE ======================= ///

    /// @dev Metadata reader library.
    using MetadataReaderLib for address;

    /// @dev Safe token transfer library.
    using SafeTransferLib for address;

    /// ======================= CUSTOM ERRORS ======================= ///

    /// @dev Caller fails.
    error Unauthorized();

    /// @dev Invalid command form.
    error InvalidSyntax();

    /// @dev Non-numeric character.
    error InvalidCharacter();

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

    /// ========================= CONSTANTS ========================= ///

    /// @dev The governing DAO address.
    address internal constant DAO = 0xDa000000000000d2885F108500803dfBAaB2f2aA;

    /// @dev The NANI token address.
    address internal constant NANI = 0x00000000000025824328358250920B271f348690;

    /// @dev The conventional ERC7528 ETH address.
    address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @dev The canonical wrapped ETH address.
    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    /// @dev The popular wrapped BTC address.
    address internal constant WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;

    /// @dev The Circle USD stablecoin address.
    address internal constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    /// @dev The Tether USD stablecoin address.
    address internal constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    /// @dev The Maker DAO USD stablecoin address.
    address internal constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    /// @dev ENS name normalizer contract.
    IENSHelper internal constant ENS_HELPER = IENSHelper(0x4A5cae3EC0b144330cf1a6CeAD187D8F6B891758);

    /// @dev ENS fallback registry contract.
    IENSHelper internal constant ENS_REGISTRY =
        IENSHelper(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);

    /// @dev ENS name wrapper token contract.
    IENSHelper internal constant ENS_WRAPPER =
        IENSHelper(0xD4416b13d2b3a9aBae7AcD5D6C2BbDBE25686401);

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

    /// @dev Constructs
    /// this implementation.
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
            address token, // Asset to send `to`.
            bytes memory callData, // Raw calldata for send transaction.
            bytes memory executeCallData // Anticipates common execute API.
        )
    {
        string memory normalized = LibString.toCase(intent, false);
        bytes32 action = _extraction(normalized);
        if (action == "send" || action == "transfer" || action == "give") {
            (string memory _to, string memory _amount, string memory _token) =
                _extractSend(normalized);
            (to, amount, token, callData, executeCallData) = previewSend(_to, _amount, _token);
        } else if (action == "swap" || action == "exchange") {
            (string memory amountIn, string memory tokenIn, string memory tokenOut) =
                _extractSwap(normalized);
            (amount, token, to) = previewSwap(amountIn, tokenIn, tokenOut);
        } else {
            revert InvalidSyntax();
        }
    }

    /// @dev Previews a send command from the parts of a matched intent string.
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
        _token = _returnConstant(bytes32(bytes(token))); // Check constant.
        if (_token == address(0)) _token = tokens[token]; // Check storage.
        bool isETH = _token == ETH; // Memo whether the token is ETH or not.
        (, _to,) = whatIsTheAddressOf(to); // Fetch receiver address from ENS.
        _amount = _stringToUint(amount, isETH ? 18 : _token.readDecimals());
        if (!isETH) callData = abi.encodeCall(IToken.transfer, (_to, _amount));
        executeCallData =
            abi.encodeCall(IExecutor.execute, (isETH ? _to : _token, isETH ? _amount : 0, callData));
    }

    /// @dev Previews a swap command from the parts of a matched intent string.
    function previewSwap(string memory amountIn, string memory tokenIn, string memory tokenOut)
        public
        view
        virtual
        returns (uint256 _amountIn, address _tokenIn, address _tokenOut)
    {
        _tokenIn = _returnConstant(bytes32(bytes(tokenIn)));
        if (_tokenIn == address(0)) _tokenIn = tokens[tokenIn];
        _tokenOut = _returnConstant(bytes32(bytes(tokenOut)));
        if (_tokenOut == address(0)) _tokenOut = tokens[tokenOut];
        _amountIn = _stringToUint(amountIn, _tokenIn == ETH ? 18 : _tokenIn.readDecimals());
    }

    /// @dev Checks ERC4337 userOp against the output of the command intent.
    function checkUserOp(string calldata intent, UserOperation calldata userOp)
        public
        view
        virtual
        returns (bool)
    {
        (,,,, bytes memory executeCallData) = previewCommand(intent);
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
        (,,,, bytes memory executeCallData) = previewCommand(intent);
        if (executeCallData.length != userOp.callData.length) return false;
        return keccak256(executeCallData) == keccak256(userOp.callData);
    }

    /// @dev Checks and returns the canonical constant for a matched intent string.
    function _returnConstant(bytes32 token) internal view virtual returns (address _token) {
        if (token == "eth" || token == "ether" || msg.value != 0) return ETH;
        if (token == "usdc") return USDC;
        if (token == "usdt") return USDT;
        if (token == "dai") return DAI;
        if (token == "nani") return NANI;
        if (token == "weth") return WETH;
        if (token == "wbtc" || token == "btc" || token == "bitcoin") return WBTC;
    }

    /// ===================== COMMAND EXECUTION ===================== ///

    /// @dev Executes a text command from an intent string.
    function command(string calldata intent) public payable virtual {
        string memory normalized = LibString.toCase(intent, false);
        bytes32 action = _extraction(normalized);
        if (action == "send" || action == "transfer" || action == "give") {
            (string memory to, string memory amount, string memory token) = _extractSend(normalized);
            send(to, amount, token);
        } else if (action == "swap" || action == "exchange") {
            (string memory amountIn, string memory tokenIn, string memory tokenOut) =
                _extractSwap(normalized);
            swap(amountIn, tokenIn, tokenOut);
        } else {
            revert InvalidSyntax();
        }
    }

    /// @dev Executes a `send` command from the parts of a matched intent string.
    function send(string memory to, string memory amount, string memory token)
        public
        payable
        virtual
    {
        address _token = _returnConstant(bytes32(bytes(token)));
        if (_token == address(0)) _token = tokens[token];
        (, address _to,) = whatIsTheAddressOf(to);
        if (_token == ETH) {
            _to.safeTransferETH(_stringToUint(amount, 18));
        } else {
            _token.safeTransferFrom(msg.sender, _to, _stringToUint(amount, _token.readDecimals()));
        }
    }

    /// @dev Executes a `swap` command from the parts of a matched intent string.
    function swap(string memory amountIn, string memory tokenIn, string memory tokenOut)
        public
        payable
        virtual
    {
        address _tokenIn = _returnConstant(bytes32(bytes(tokenIn)));
        if (_tokenIn == address(0)) _tokenIn = tokens[tokenIn];
        address _tokenOut = _returnConstant(bytes32(bytes(tokenOut)));
        if (_tokenOut == address(0)) _tokenOut = tokens[tokenOut];
        bool isETH = _tokenIn == ETH;
        if (isETH) {
            _tokenIn = WETH;
            WETH.safeTransferETH(msg.value);
        }
        bool zeroForOne = _tokenIn < _tokenOut;
        uint256 _amountIn = _stringToUint(amountIn, isETH ? 18 : _tokenIn.readDecimals());
        address pool = _computePoolAddress(_tokenIn, _tokenOut, 3000);
        ISwapRouter(pool).swap(
            msg.sender,
            zeroForOne,
            int256(_amountIn),
            zeroForOne ? MIN_SQRT_RATIO_PLUS_ONE : MAX_SQRT_RATIO_MINUS_ONE,
            abi.encodePacked(isETH, zeroForOne, _tokenIn, msg.sender)
        );
    }

    /// @dev Computes the create2 address for given token pair. Starts mid fee.
    function _computePoolAddress(address tokenA, address tokenB, uint24 fee)
        internal
        view
        virtual
        returns (address pool)
    {
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        bytes32 salt = keccak256(abi.encode(tokenA, tokenB, fee));
        assembly ("memory-safe") {
            // Compute and store the bytecode hash.
            mstore8(0x00, 0xff) // Write the prefix.
            mstore(0x35, UNISWAP_V3_POOL_INIT_CODE_HASH)
            mstore(0x01, shl(96, UNISWAP_V3_FACTORY))
            mstore(0x15, salt)
            pool := keccak256(0x00, 0x55)
            mstore(0x35, 0) // Restore the overwritten
        }
        if (pool.code.length != 0) return pool;
        else return _computePoolAddress(tokenA, tokenB, 500);
    }

    /// @dev Fallback `uniswapV3SwapCallback`.
    /// If ETH is swapped, WETH is forwarded.
    fallback() external {
        int256 amount0Delta;
        int256 amount1Delta;
        bool isETH;
        bool zeroForOne;
        address tokenIn;
        address payer;
        assembly ("memory-safe") {
            amount0Delta := calldataload(0x4)
            amount1Delta := calldataload(0x24)
            isETH := byte(0, calldataload(0x84))
            zeroForOne := byte(0, calldataload(add(0x84, 1)))
            tokenIn := shr(96, calldataload(add(0x84, 2)))
            payer := shr(96, calldataload(add(0x84, 22)))
        }
        isETH
            ? WETH.safeTransfer(msg.sender, uint256(zeroForOne ? amount0Delta : amount1Delta))
            : tokenIn.safeTransferFrom(
                payer, msg.sender, uint256(zeroForOne ? amount0Delta : amount1Delta)
            );
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
        string memory normalized = LibString.toCase(token, false);
        address _token = _returnConstant(bytes32(bytes(normalized)));
        if (_token == address(0)) _token = tokens[token];
        bool isETH = _token == ETH;
        balance = isETH ? _name.balance : _balanceOf(_token, _name);
        balanceAdjusted = balance / 10 ** (isETH ? 18 : _token.readDecimals());
    }

    /// @dev Returns the total supply of a named token.
    function whatIsTheTotalSupplyOf(string calldata token)
        public
        view
        virtual
        returns (uint256 supply, uint256 supplyAdjusted)
    {
        address _token = _returnConstant(bytes32(bytes(token)));
        if (_token == address(0)) _token = tokens[token];
        if (_token == ETH) revert InvalidSyntax();
        supply = _totalSupply(_token);
        supplyAdjusted = supply / 10 ** _token.readDecimals();
    }

    /// @dev Returns the amount of ERC20/721 `token` owned by `account`.
    function _balanceOf(address token, address account)
        internal
        view
        virtual
        returns (uint256 amount)
    {
        assembly ("memory-safe") {
            mstore(0x00, 0x70a08231000000000000000000000000) // `balanceOf(address)`.
            mstore(0x14, account) // Store the `account` argument.
            if iszero(staticcall(gas(), token, 0x10, 0x24, 0x20, 0x20)) { revert(codesize(), 0x00) }
            amount := mload(0x20)
        }
    }

    /// @dev Returns the total supply of ERC20/721 `token`.
    function _totalSupply(address token) internal view virtual returns (uint256 supply) {
        assembly ("memory-safe") {
            mstore(0x00, 0x18160ddd) // `totalSupply()`.
            if iszero(staticcall(gas(), token, 0x1c, 0x04, 0x20, 0x20)) { revert(codesize(), 0x00) }
            supply := mload(0x20)
        }
    }

    /// ====================== ENS VERIFICATION ====================== ///

    /// @dev Returns ENS name ownership details.
    function whatIsTheAddressOf(string memory name)
        public
        view
        virtual
        returns (address owner, address receiver, bytes32 node)
    {
        (owner, node) = ENS_HELPER.owner(string(abi.encodePacked(name, ".eth")));
        if (IENSHelper(owner) == ENS_WRAPPER) owner = ENS_WRAPPER.ownerOf(uint256(node));
        receiver = IENSHelper(ENS_REGISTRY.resolver(node)).addr(node); // Fails on misname.
    }

    /// ========================= GOVERNANCE ========================= ///

    /// @dev Sets a public `name` tag for a given `token` address. Governed by DAO.
    function setName(address token, string calldata name) public payable virtual {
        if (msg.sender != DAO) revert Unauthorized();
        string memory normalized = LibString.toCase(name, false);
        emit NameSet(tokens[normalized] = token, normalized);
    }

    /// ================= INTERNAL STRING OPERATIONS ================= ///

    /// @dev Extracts the first word (action) as bytes32.
    function _extraction(string memory normalizedIntent)
        internal
        pure
        virtual
        returns (bytes32 result)
    {
        assembly ("memory-safe") {
            let str := add(normalizedIntent, 32)
            for { let i } lt(i, 32) { i := add(i, 1) } {
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
        returns (string memory amountIn, string memory tokenIn, string memory tokenOut)
    {
        string[] memory parts = _split(normalizedIntent, " ");
        if (parts.length == 5) return (parts[1], parts[2], parts[4]);
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

/// @dev ENS name resolution helper contracts interface.
interface IENSHelper {
    function addr(bytes32) external view returns (address);
    function ownerOf(uint256) external view returns (address);
    function resolver(bytes32) external view returns (address);
    function owner(string calldata) external view returns (address, bytes32);
}

/// @dev Simple Uniswap V3 swapping interface.
interface ISwapRouter {
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);
}
