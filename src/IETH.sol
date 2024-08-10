// ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘
// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {SafeTransferLib} from "../lib/solady/src/utils/SafeTransferLib.sol";
import {MetadataReaderLib} from "../lib/solady/src/utils/MetadataReaderLib.sol";

/// @title Intents Engine (IE) on Ethereum (IETH)
/// @notice Simple helper contract for turning transactional intents into executable code.
/// @dev V1 simulates typical commands (sending and swapping tokens) and includes execution.
/// IE also has a workflow to verify the intent of ERC4337 account userOps against calldata.
/// Example commands include "send nani 100 dai" or "swap usdc for 1 eth" and such variants.
/// @author nani.eth (https://github.com/NaniDAO/ie)
/// @custom:version 1.5.0
contract IETH {
    /// ======================= LIBRARY USAGE ======================= ///

    /// @dev Token transfer library.
    using SafeTransferLib for address;

    /// @dev Token metadata reader library.
    using MetadataReaderLib for address;

    /// ======================= CUSTOM ERRORS ======================= ///

    /// @dev Bad math.
    error Overflow();

    /// @dev 0-liquidity.
    error InvalidSwap();

    /// @dev Invalid command.
    error InvalidSyntax();

    /// @dev Non-numeric character.
    error InvalidCharacter();

    /// @dev Insufficient swap output.
    error InsufficientSwap();

    /// @dev Invalid selector for spend.
    error InvalidSelector();

    /// =========================== EVENTS =========================== ///

    /// @dev Logs the setting of a token name.
    event NameSet(address token, string name);

    /// @dev Logs the setting of a swap pool pair on Uniswap V3.
    event PairSet(address token0, address token1, address pair);

    /// ========================== STRUCTS ========================== ///

    /// @dev The packed ERC4337 user operation (userOp) struct.
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

    /// @dev The `swap()` command information struct.
    struct SwapInfo {
        bool ETHIn;
        bool ETHOut;
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
    }

    /// @dev The `swap()` pool liquidity struct.
    struct SwapLiq {
        address pool;
        uint256 liq;
    }

    /// @dev The string start and end indices.
    struct StringPart {
        uint256 start;
        uint256 end;
    }

    /// =========================== ENUMS =========================== ///

    /// @dev `ENSAsciiNormalizer` rules.
    enum Rule {
        DISALLOWED,
        VALID
    }

    /// ========================= CONSTANTS ========================= ///

    /// @dev The governing DAO address.
    address internal constant DAO = 0xDa000000000000d2885F108500803dfBAaB2f2aA;

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

    /// @dev The Lido Wrapped Staked ETH token address.
    address internal constant WSTETH = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;

    /// @dev The Rocket Pool Staked ETH token address.
    address internal constant RETH = 0xae78736Cd615f374D3085123A210448E74Fc6393;

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

    /// @dev ENS fallback registry contract.
    IENSHelper internal constant ENS_REGISTRY =
        IENSHelper(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);

    /// @dev ENS name wrapper token contract.
    IENSHelper internal constant ENS_WRAPPER =
        IENSHelper(0xD4416b13d2b3a9aBae7AcD5D6C2BbDBE25686401);

    /// @dev String mapping for `ENSAsciiNormalizer` logic.
    bytes internal constant ASCII_MAP =
        hex"2d00020101000a010700016101620163016401650166016701680169016a016b016c016d016e016f0170017101720173017401750176017701780179017a06001a010500";

    /// ========================== STORAGE ========================== ///

    /// @dev DAO-governed naming interface (nami).
    INAMI internal nami;

    /// @dev DAO-governed token names to addresses.
    mapping(string name => address) public addresses;

    /// @dev DAO-governed token addresses to names.
    mapping(address addresses => string) public names;

    /// @dev DAO-governed token swap pool routing on Uniswap V3.
    mapping(address token0 => mapping(address token1 => address)) public pairs;

    /// @dev Each index in idnamap refers to an ascii code point.
    /// If idnamap[char] > 2, char maps to a valid ascii character.
    /// Otherwise, idna[char] returns Rule.DISALLOWED or Rule.VALID.
    /// Modified from `ENSAsciiNormalizer` deployed by royalfork.eth
    /// (0x4A5cae3EC0b144330cf1a6CeAD187D8F6B891758).
    bytes1[] internal _idnamap;

    /// ======================== CONSTRUCTOR ======================== ///

    /// @dev Constructs this IE on Ethereum with ENS `ASCII_MAP`.
    constructor() payable {
        unchecked {
            for (uint256 i; i != ASCII_MAP.length; i += 2) {
                bytes1 r = ASCII_MAP[i + 1];
                for (uint8 j; j != uint8(ASCII_MAP[i]); ++j) {
                    _idnamap.push(r);
                }
            }
        }
    }

    /// ====================== COMMAND PREVIEW ====================== ///

    /// @dev Preview natural language smart contract command.
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
        bytes memory normalized = _lowercase(bytes(intent));
        bytes32 action = _extraction(normalized);
        if (action == "send" || action == "transfer" || action == "pay" || action == "grant") {
            (bytes memory _to, bytes memory _amount, bytes memory _token) = _extractSend(normalized);
            (to, amount, token, callData, executeCallData) = _previewSend(_to, _amount, _token);
        } else if (
            action == "swap" || action == "sell" || action == "exchange" || action == "stake"
        ) {
            (
                bytes memory amountIn,
                bytes memory amountOutMin,
                bytes memory tokenIn,
                bytes memory tokenOut,
                bytes memory receiver
            ) = _extractSwap(normalized);
            address _receiver;
            (amount, minAmountOut, token, to, _receiver) =
                _previewSwap(amountIn, amountOutMin, tokenIn, tokenOut, receiver);
            callData = abi.encodePacked(_receiver);
        } else {
            revert InvalidSyntax(); // Invalid command format.
        }
    }

    /// @dev Previews a `send` command from the parts of a matched intent string.
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
        )
    {
        uint256 decimals;
        (_token, decimals) = _returnTokenConstants(bytes32(token));
        if (_token == address(0)) _token = addresses[string(token)];
        bool isETH = _token == ETH;
        (, _to,) = whatIsTheAddressOf(string(to));
        _amount = _toUint(amount, decimals != 0 ? decimals : _token.readDecimals(), _token);

        if (!isETH) callData = abi.encodeCall(IToken.transfer, (_to, _amount));
        executeCallData =
            abi.encodeCall(IExecutor.execute, (isETH ? _to : _token, isETH ? _amount : 0, callData));
    }

    /// @dev Previews a `swap` command from the parts of a matched intent string.
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
        )
    {
        uint256 decimalsIn;
        uint256 decimalsOut;
        (_tokenIn, decimalsIn) = _returnTokenConstants(bytes32(tokenIn));
        if (_tokenIn == address(0)) _tokenIn = addresses[string(tokenIn)];
        (_tokenOut, decimalsOut) = _returnTokenConstants(bytes32(tokenOut));
        if (_tokenOut == address(0)) _tokenOut = addresses[string(tokenOut)];

        _amountIn =
            _toUint(amountIn, decimalsIn != 0 ? decimalsIn : _tokenIn.readDecimals(), _tokenIn);
        _amountOut = _toUint(
            amountOutMin, decimalsOut != 0 ? decimalsOut : _tokenOut.readDecimals(), _tokenOut
        );

        if (receiver.length != 0) (, _receiver,) = whatIsTheAddressOf(string(receiver));
    }

    /// @dev Checks packed ERC4337 userOp against the output of the command intent.
    function checkUserOp(string calldata intent, PackedUserOperation calldata userOp)
        public
        view
        virtual
        returns (bool intentMatched)
    {
        (,,,,, bytes memory executeCallData) = previewCommand(intent);
        if (executeCallData.length != userOp.callData.length) return false;
        return keccak256(executeCallData) == keccak256(userOp.callData);
    }

    /// @dev Checks and returns the canonical token address constant for a matched intent string.
    function _returnTokenConstants(bytes32 token)
        internal
        pure
        virtual
        returns (address _token, uint256 _decimals)
    {
        if (token == "eth" || token == "ether") return (ETH, 18);
        if (token == "usdc") return (USDC, 6);
        if (token == "usdt" || token == "tether") return (USDT, 6);
        if (token == "dai") return (DAI, 18);
        if (token == "weth") return (WETH, 18);
        if (token == "wbtc" || token == "btc" || token == "bitcoin") return (WBTC, 8);
        if (token == "steth" || token == "wsteth" || token == "lido") return (WSTETH, 18);
        if (token == "reth") return (RETH, 18);
    }

    /// @dev Checks and returns the canonical token string constant for a matched address.
    function _returnTokenAliasConstants(address token)
        internal
        pure
        virtual
        returns (string memory _token, uint256 _decimals)
    {
        if (token == USDC) return ("USDC", 6);
        if (token == USDT) return ("USDT", 6);
        if (token == DAI) return ("DAI", 18);
        if (token == WETH) return ("WETH", 18);
        if (token == WBTC) return ("WBTC", 8);
        if (token == WSTETH) return ("WSTETH", 18);
        if (token == RETH) return ("RETH", 18);
    }

    /// @dev Checks and returns popular pool pairs for WETH swaps.
    function _returnPoolConstants(address token0, address token1)
        internal
        pure
        virtual
        returns (address pool)
    {
        if (token0 == WSTETH && token1 == WETH) return 0x109830a1AAaD605BbF02a9dFA7B0B92EC2FB7dAa;
        if (token0 == RETH && token1 == WETH) return 0x553e9C493678d8606d6a5ba284643dB2110Df823;
        if (token0 == USDC && token1 == WETH) return 0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640;
        if (token0 == WETH && token1 == USDT) return 0x11b815efB8f581194ae79006d24E0d814B7697F6;
        if (token0 == DAI && token1 == WETH) return 0xC2e9F25Be6257c210d7Adf0D4Cd6E3E881ba25f8;
        if (token0 == WBTC && token1 == WETH) return 0x4585FE77225b41b697C938B018E2Ac67Ac5a20c0;
    }

    /// ===================== COMMAND EXECUTION ===================== ///

    /// @dev Executes a text command from an `intent` string.
    function command(string calldata intent) public payable virtual {
        bytes memory normalized = _lowercase(bytes(intent));
        bytes32 action = _extraction(normalized);
        if (action == "send" || action == "transfer" || action == "pay" || action == "grant") {
            (bytes memory to, bytes memory amount, bytes memory token) = _extractSend(normalized);
            send(string(to), string(amount), string(token));
        } else if (
            action == "swap" || action == "sell" || action == "exchange" || action == "stake"
        ) {
            (
                bytes memory amountIn,
                bytes memory amountOutMin,
                bytes memory tokenIn,
                bytes memory tokenOut,
                bytes memory receiver
            ) = _extractSwap(normalized);
            swap(
                string(amountIn),
                string(amountOutMin),
                string(tokenIn),
                string(tokenOut),
                string(receiver)
            );
        } else {
            revert InvalidSyntax(); // Invalid command format.
        }
    }

    /// @dev Executes batch of text commands from an `intents` string.
    function command(string[] calldata intents) public payable virtual {
        for (uint256 i; i != intents.length; ++i) {
            command(intents[i]);
        }
    }

    /// @dev Executes a `send` command from the parts of a matched intent string.
    function send(string memory to, string memory amount, string memory token)
        public
        payable
        virtual
    {
        (address _token, uint256 decimals) = _returnTokenConstants(bytes32(bytes(token)));
        if (_token == address(0)) _token = addresses[token];
        (, address _to,) = whatIsTheAddressOf(to);
        uint256 _amount =
            _toUint(bytes(amount), decimals != 0 ? decimals : _token.readDecimals(), _token);

        if (_token == ETH) {
            _to.safeTransferETH(_amount);
        } else {
            _token.safeTransferFrom(msg.sender, _to, _amount);
        }
    }

    /// @dev Executes a `swap` command from the parts of a matched intent string.
    function swap(
        string memory amountIn,
        string memory amountOutMin,
        string memory tokenIn,
        string memory tokenOut,
        string memory receiver
    ) public payable virtual {
        SwapInfo memory info;
        uint256 decimalsIn;
        uint256 decimalsOut;
        (info.tokenIn, decimalsIn) = _returnTokenConstants(bytes32(bytes(tokenIn)));
        if (info.tokenIn == address(0)) info.tokenIn = addresses[tokenIn];
        (info.tokenOut, decimalsOut) = _returnTokenConstants(bytes32(bytes(tokenOut)));
        if (info.tokenOut == address(0)) info.tokenOut = addresses[tokenOut];
        info.ETHIn = info.tokenIn == ETH;
        if (info.ETHIn) info.tokenIn = WETH;
        info.ETHOut = info.tokenOut == ETH;
        if (info.ETHOut) info.tokenOut = WETH;

        uint256 minOut;
        if (bytes(amountOutMin).length != 0) {
            minOut = _toUint(
                bytes(amountOutMin),
                decimalsOut != 0 ? decimalsOut : info.tokenOut.readDecimals(),
                info.tokenOut
            );
        }

        bool exactOut = bytes(amountIn).length == 0;
        info.amountIn = exactOut
            ? minOut
            : _toUint(
                bytes(amountIn),
                decimalsIn != 0 ? decimalsIn : info.tokenIn.readDecimals(),
                info.tokenIn
            );

        if (info.amountIn >= 1 << 255) revert Overflow();

        address _receiver;
        if (bytes(receiver).length == 0) _receiver = msg.sender;
        else (, _receiver,) = whatIsTheAddressOf(receiver);

        (address pool, bool zeroForOne) = _computePoolAddress(info.tokenIn, info.tokenOut);
        (int256 amount0, int256 amount1) = ISwapRouter(pool).swap(
            !info.ETHOut ? _receiver : address(this),
            zeroForOne,
            !exactOut ? int256(info.amountIn) : -int256(info.amountIn),
            zeroForOne ? MIN_SQRT_RATIO_PLUS_ONE : MAX_SQRT_RATIO_MINUS_ONE,
            abi.encodePacked(
                info.ETHIn, info.ETHOut, msg.sender, info.tokenIn, info.tokenOut, _receiver
            )
        );

        if (minOut != 0) {
            if (uint256(-(zeroForOne ? amount1 : amount0)) < minOut) revert InsufficientSwap();
        }
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
        address receiver;
        assembly ("memory-safe") {
            amount0Delta := calldataload(0x4)
            amount1Delta := calldataload(0x24)
            ETHIn := byte(0, calldataload(0x84))
            ETHOut := byte(0, calldataload(add(0x84, 1)))
            payer := shr(96, calldataload(add(0x84, 2)))
            tokenIn := shr(96, calldataload(add(0x84, 22)))
            tokenOut := shr(96, calldataload(add(0x84, 42)))
            receiver := shr(96, calldataload(add(0x84, 62)))
        }
        if (amount0Delta <= 0 && amount1Delta <= 0) revert InvalidSwap();
        (address pool, bool zeroForOne) = _computePoolAddress(tokenIn, tokenOut);
        assembly ("memory-safe") {
            if iszero(eq(caller(), pool)) { revert(codesize(), codesize()) }
        }
        if (ETHIn) {
            _wrapETH(uint256(zeroForOne ? amount0Delta : amount1Delta));
        } else {
            tokenIn.safeTransferFrom(payer, pool, uint256(zeroForOne ? amount0Delta : amount1Delta));
        }
        if (ETHOut) {
            uint256 amount = uint256(-(zeroForOne ? amount1Delta : amount0Delta));
            _unwrapETH(amount);
            receiver.safeTransferETH(amount);
        }
    }

    /// @dev Computes the create2 address for given token pair.
    /// note: This process checks all available pools for price.
    function _computePoolAddress(address tokenA, address tokenB)
        internal
        view
        virtual
        returns (address pool, bool zeroForOne)
    {
        if (tokenA < tokenB) zeroForOne = true;
        else (tokenA, tokenB) = (tokenB, tokenA);
        pool = _returnPoolConstants(tokenA, tokenB);
        if (pool == address(0)) {
            pool = pairs[tokenA][tokenB];
            if (pool == address(0)) {
                address pool100 = _computePairHash(tokenA, tokenB, 100); // Lowest fee.
                address pool500 = _computePairHash(tokenA, tokenB, 500); // Lower fee.
                address pool3000 = _computePairHash(tokenA, tokenB, 3000); // Mid fee.
                address pool10000 = _computePairHash(tokenA, tokenB, 10000); // Hi fee.
                SwapLiq memory topPool;
                uint256 liq;
                if (pool100.code.length != 0) {
                    liq = _balanceOf(tokenA, pool100);
                    topPool = SwapLiq(pool100, liq);
                }
                if (pool500.code.length != 0) {
                    liq = _balanceOf(tokenA, pool500);
                    if (liq > topPool.liq) {
                        topPool = SwapLiq(pool500, liq);
                    }
                }
                if (pool3000.code.length != 0) {
                    liq = _balanceOf(tokenA, pool3000);
                    if (liq > topPool.liq) {
                        topPool = SwapLiq(pool3000, liq);
                    }
                }
                if (pool10000.code.length != 0) {
                    liq = _balanceOf(tokenA, pool10000);
                    if (liq > topPool.liq) {
                        topPool = SwapLiq(pool10000, liq);
                    }
                }
                pool = topPool.pool; // Return top pool.
            }
        }
    }

    /// @dev Computes the create2 deployment hash for a given token pair.
    function _computePairHash(address token0, address token1, uint24 fee)
        internal
        pure
        virtual
        returns (address pool)
    {
        bytes32 salt = _hash(token0, token1, fee);
        assembly ("memory-safe") {
            mstore8(0x00, 0xff) // Write the prefix.
            mstore(0x35, UNISWAP_V3_POOL_INIT_CODE_HASH)
            mstore(0x01, shl(96, UNISWAP_V3_FACTORY))
            mstore(0x15, salt)
            pool := keccak256(0x00, 0x55)
            mstore(0x35, 0) // Restore overwritten.
        }
    }

    /// @dev Returns `keccak256(abi.encode(value0, value1, value2))`.
    function _hash(address value0, address value1, uint24 value2)
        internal
        pure
        virtual
        returns (bytes32 result)
    {
        assembly ("memory-safe") {
            let m := mload(0x40)
            mstore(m, value0)
            mstore(add(m, 0x20), value1)
            mstore(add(m, 0x40), value2)
            result := keccak256(m, 0x60)
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

    /// @dev Returns the amount of ERC20 `token` owned by `account`.
    function _balanceOf(address token, address account)
        internal
        view
        virtual
        returns (uint256 amount)
    {
        assembly ("memory-safe") {
            mstore(0x00, 0x70a08231000000000000000000000000) // `balanceOf(address)`.
            mstore(0x14, account) // Store the `account` argument.
            pop(staticcall(gas(), token, 0x10, 0x24, 0x20, 0x20))
            amount := mload(0x20)
        }
    }

    /// @dev ETH receiver fallback.
    /// Only canonical WETH can call.
    receive() external payable virtual {
        assembly ("memory-safe") {
            if iszero(eq(caller(), WETH)) { revert(codesize(), codesize()) }
        }
    }

    /// ==================== COMMAND TRANSLATION ==================== ///

    /// @dev Translates an `intent` from raw `command()` calldata.
    function translateCommand(bytes calldata callData)
        public
        pure
        virtual
        returns (string memory intent)
    {
        return string(callData[4:]);
    }

    /// @dev Translates an `intent` for send action from the solution `callData` of standard `execute()`.
    /// note: The function selector technically doesn't need to be `execute()` but params should match.
    function translateExecute(bytes calldata callData)
        public
        view
        virtual
        returns (string memory intent)
    {
        unchecked {
            (address target, uint256 value) = abi.decode(callData[4:68], (address, uint256));

            if (value != 0) {
                return string(
                    abi.encodePacked(
                        "send ",
                        _convertWeiToString(value, 18),
                        " ETH to 0x",
                        _toAsciiString(target)
                    )
                );
            }

            if (
                bytes4(callData[132:136]) != IToken.transfer.selector
                    && bytes4(callData[132:136]) != IToken.approve.selector
            ) revert InvalidSelector();
            bool transfer = bytes4(callData[132:136]) == IToken.transfer.selector;

            (string memory token, uint256 decimals) = _returnTokenAliasConstants(target);
            if (bytes(token).length == 0) token = names[target];
            if (decimals == 0) decimals = target.readDecimals(); // Sanity check.
            (target, value) = abi.decode(callData[136:], (address, uint256));

            return string(
                abi.encodePacked(
                    transfer ? "send " : "approve ",
                    _convertWeiToString(value, decimals),
                    " ",
                    token,
                    " to 0x",
                    _toAsciiString(target)
                )
            );
        }
    }

    /// @dev Translate packed ERC4337 userOp `callData` into readable `intent`.
    function translateUserOp(PackedUserOperation calldata userOp)
        public
        view
        virtual
        returns (string memory intent)
    {
        return bytes4(userOp.callData) == IExecutor.execute.selector
            ? translateExecute(userOp.callData)
            : translateCommand(userOp.callData);
    }

    /// ====================== ENS VERIFICATION ====================== ///

    /// @dev Returns ENS name ownership details.
    function whatIsTheAddressOf(string memory name)
        public
        view
        virtual
        returns (address owner, address receiver, bytes32 node)
    {
        node = _namehash(string(abi.encodePacked(name, ".eth")));
        owner = ENS_REGISTRY.owner(node);
        if (IENSHelper(owner) == ENS_WRAPPER) owner = ENS_WRAPPER.ownerOf(uint256(node));
        receiver = IENSHelper(ENS_REGISTRY.resolver(node)).addr(node); // Fails on misname.
    }

    /// @dev Computes an ENS domain namehash.
    function _namehash(string memory domain) internal view virtual returns (bytes32 node) {
        // Process labels (in reverse order for namehash).
        uint256 i = bytes(domain).length;
        uint256 lastDot = i;
        unchecked {
            for (; i != 0; --i) {
                bytes1 c = bytes(domain)[i - 1];
                if (c == ".") {
                    node = keccak256(abi.encodePacked(node, _labelhash(domain, i, lastDot)));
                    lastDot = i - 1;
                    continue;
                }
                require(c < 0x80);
                bytes1 r = _idnamap[uint8(c)];
                require(uint8(r) != uint8(Rule.DISALLOWED));
                if (uint8(r) > 1) {
                    bytes(domain)[i - 1] = r;
                }
            }
        }
        return keccak256(abi.encodePacked(node, _labelhash(domain, i, lastDot)));
    }

    /// @dev Computes an ENS domain labelhash given its start and end.
    function _labelhash(string memory domain, uint256 start, uint256 end)
        internal
        pure
        virtual
        returns (bytes32 hash)
    {
        assembly ("memory-safe") {
            hash := keccak256(add(add(domain, 0x20), start), sub(end, start))
        }
    }

    /// ========================= GOVERNANCE ========================= ///

    /// @dev Sets a public `name` tag for a given `token` address. Governed by DAO.
    function setName(address token, string calldata name) public payable virtual {
        assembly ("memory-safe") {
            if iszero(eq(caller(), DAO)) { revert(codesize(), codesize()) }
        }
        string memory normalized = string(_lowercase(bytes(name)));
        names[token] = normalized;
        emit NameSet(addresses[normalized] = token, normalized);
    }

    /// @dev Sets a public `name` and ticker for a given `token` address. Open.
    function setName(address token) public payable virtual {
        string memory normalizedName = string(_lowercase(bytes(token.readName())));
        string memory normalizedSymbol = string(_lowercase(bytes(token.readSymbol())));
        names[token] = normalizedSymbol;
        emit NameSet(addresses[normalizedName] = token, normalizedName);
        emit NameSet(addresses[normalizedSymbol] = token, normalizedSymbol);
    }

    /// @dev Sets a public pool `pair` for swapping tokens. Governed by DAO.
    function setPair(address tokenA, address tokenB, address pair) public payable virtual {
        assembly ("memory-safe") {
            if iszero(eq(caller(), DAO)) { revert(codesize(), codesize()) }
        }
        if (tokenB < tokenA) (tokenA, tokenB) = (tokenB, tokenA);
        emit PairSet(tokenA, tokenB, pairs[tokenA][tokenB] = pair);
    }

    /// @dev Sets the naming interface (nami) singleton. Governed by DAO.
    function setNAMI(INAMI NAMI) public payable virtual {
        assembly ("memory-safe") {
            if iszero(eq(caller(), DAO)) { revert(codesize(), codesize()) }
        }
        nami = NAMI; // No event emitted since very infrequent if ever.
    }

    /// ===================== STRING OPERATIONS ===================== ///

    /// @dev Returns copy of string in lowercase.
    /// Modified from Solady LibString `toCase`.
    function _lowercase(bytes memory subject) internal pure virtual returns (bytes memory result) {
        assembly ("memory-safe") {
            let len := mload(subject)
            result := add(mload(0x40), 0x20)
            subject := add(subject, 1)
            let flags := shl(add(70, shl(5, 0)), 0x3ffffff)
            let w := not(0)
            for { let o := len } 1 {} {
                o := add(o, w)
                let b := and(0xff, mload(add(subject, o)))
                mstore8(add(result, o), xor(b, and(shr(b, flags), 0x20)))
                if iszero(o) { break }
            }
            result := mload(0x40)
            mstore(result, len) // Store the length.
            let last := add(add(result, 0x20), len)
            mstore(last, 0) // Zeroize the slot after the string.
            mstore(0x40, add(last, 0x20)) // Allocate the memory.
        }
    }

    /// @dev Extracts the first word (action) as bytes32.
    function _extraction(bytes memory normalizedIntent)
        internal
        pure
        virtual
        returns (bytes32 result)
    {
        assembly ("memory-safe") {
            let str := add(normalizedIntent, 0x20)
            result := mload(str)

            // Find the index of the first space or null terminator.
            let spaceIndex := 32
            for { let i := 0 } lt(i, 32) { i := add(i, 1) } {
                let char := byte(i, result)
                if or(eq(char, 0x20), eq(char, 0)) {
                    spaceIndex := i
                    break
                }
            }

            // Create a mask to clear bytes after the first word.
            let mask := shl(mul(8, sub(32, spaceIndex)), not(0))
            result := and(result, mask)
        }
    }

    /// @dev Extract the key words of normalized `send` intent.
    function _extractSend(bytes memory normalizedIntent)
        internal
        pure
        virtual
        returns (bytes memory to, bytes memory amount, bytes memory token)
    {
        StringPart[] memory parts = _split(normalizedIntent, " ");
        if (parts.length == 4) {
            return (
                _getPart(normalizedIntent, parts[1]),
                _getPart(normalizedIntent, parts[2]),
                _getPart(normalizedIntent, parts[3])
            );
        }
        if (parts.length == 5) {
            return (
                _getPart(normalizedIntent, parts[4]),
                _getPart(normalizedIntent, parts[1]),
                _getPart(normalizedIntent, parts[2])
            );
        } else {
            revert InvalidSyntax(); // Command is not formatted.
        }
    }

    /// @dev Extract the key words of normalized `swap` intent.
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
        )
    {
        StringPart[] memory parts = _split(normalizedIntent, " ");
        bool isNumber;
        if (parts.length == 5) {
            isNumber = _isNumber(_getPart(normalizedIntent, parts[1]));
            if (isNumber) {
                return (
                    _getPart(normalizedIntent, parts[1]),
                    "",
                    _getPart(normalizedIntent, parts[2]),
                    _getPart(normalizedIntent, parts[4]),
                    ""
                );
            } else {
                return (
                    "",
                    _getPart(normalizedIntent, parts[3]),
                    _getPart(normalizedIntent, parts[1]),
                    _getPart(normalizedIntent, parts[4]),
                    ""
                );
            }
        } else if (parts.length == 6) {
            return (
                _getPart(normalizedIntent, parts[1]),
                _getPart(normalizedIntent, parts[4]),
                _getPart(normalizedIntent, parts[2]),
                _getPart(normalizedIntent, parts[5]),
                ""
            );
        } else if (parts.length == 7) {
            isNumber = _isNumber(_getPart(normalizedIntent, parts[1]));
            if (isNumber) {
                return (
                    _getPart(normalizedIntent, parts[1]),
                    "",
                    _getPart(normalizedIntent, parts[2]),
                    _getPart(normalizedIntent, parts[4]),
                    _getPart(normalizedIntent, parts[6])
                );
            } else {
                return (
                    "",
                    _getPart(normalizedIntent, parts[3]),
                    _getPart(normalizedIntent, parts[1]),
                    _getPart(normalizedIntent, parts[4]),
                    _getPart(normalizedIntent, parts[6])
                );
            }
        } else if (parts.length == 8) {
            return (
                _getPart(normalizedIntent, parts[1]),
                _getPart(normalizedIntent, parts[4]),
                _getPart(normalizedIntent, parts[2]),
                _getPart(normalizedIntent, parts[5]),
                _getPart(normalizedIntent, parts[6])
            );
        } else {
            revert InvalidSyntax(); // Unformatted.
        }
    }

    /// @dev Validate whether given bytes string is number, percentage or 'all'.
    function _isNumber(bytes memory s) internal pure virtual returns (bool) {
        if (bytes32(s) == "all") return true;
        return (s[0] >= 0x30 && s[0] <= 0x39);
    }

    /// @dev Splits a string into parts based on a delimiter.
    function _split(bytes memory base, bytes1 delimiter)
        internal
        pure
        virtual
        returns (StringPart[] memory parts)
    {
        unchecked {
            uint256 len = base.length;
            uint256 count = 1;
            // Count the number of parts.
            for (uint256 i; i != len; ++i) {
                if (base[i] == delimiter) {
                    ++count;
                }
            }
            parts = new StringPart[](count);
            uint256 partIndex;
            uint256 start;
            // Split the string and populate parts array.
            for (uint256 i; i != len; ++i) {
                if (base[i] == delimiter) {
                    parts[partIndex++] = StringPart(start, i);
                    start = i + 1;
                }
            }
            // Add the final part.
            parts[partIndex] = StringPart(start, len);
        }
    }

    /// @dev Converts a `StringPart` into its compact bytes.
    function _getPart(bytes memory base, StringPart memory part)
        internal
        pure
        virtual
        returns (bytes memory)
    {
        unchecked {
            bytes memory result = new bytes(part.end - part.start);
            for (uint256 i; i != result.length; ++i) {
                result[i] = base[part.start + i];
            }
            return result;
        }
    }

    /// @dev Convert string to decimalized numerical value.
    function _toUint(bytes memory s, uint256 decimals, address token)
        internal
        view
        virtual
        returns (uint256 result)
    {
        unchecked {
            // Check for "all" or "100%" first.
            bytes32 sBytes32 = bytes32(s);
            if (sBytes32 == bytes32("all") || sBytes32 == bytes32("100%")) {
                return token == ETH ? msg.sender.balance + msg.value : _balanceOf(token, msg.sender);
            }

            uint256 len = s.length;
            bool hasDecimal;
            uint256 decimalPlaces;
            bool isPercentage;

            for (uint256 i; i < len; ++i) {
                bytes1 c = s[i];
                if (c >= 0x30 && c <= 0x39) {
                    result = result * 10 + uint8(c) - 48;
                    if (hasDecimal) {
                        if (++decimalPlaces > decimals) break;
                    }
                } else if (c == 0x2E && !hasDecimal) {
                    hasDecimal = true;
                } else if (c == 0x25 && i == len - 1) {
                    isPercentage = true;
                } else if (c != 0x20) {
                    revert InvalidCharacter();
                }
            }

            // Adjust for decimals.
            if (!hasDecimal) {
                result *= 10 ** decimals;
            } else if (decimalPlaces < decimals) {
                result *= 10 ** (decimals - decimalPlaces);
            }

            // Handle percentage.
            if (isPercentage) {
                uint256 balance =
                    token == ETH ? msg.sender.balance + msg.value : _balanceOf(token, msg.sender);
                result = (balance * result) / (100 * 10 ** decimals);
            }
        }
    }

    /// @dev Converts a hexadecimal string to its `address` representation.
    function _toAddress(bytes memory s) internal pure virtual returns (address addr) {
        unchecked {
            if (s.length != 42) revert InvalidSyntax();
            uint256 result;
            for (uint256 i = 2; i != 42; ++i) {
                result *= 16;
                uint8 b = uint8(s[i]);
                if (b >= 48 && b <= 57) {
                    result += b - 48;
                } else if (b >= 65 && b <= 70) {
                    result += b - 55;
                } else if (b >= 97 && b <= 102) {
                    result += b - 87;
                } else {
                    revert InvalidSyntax();
                }
            }
            return address(uint160(result));
        }
    }

    /// @dev Convert an address to an ASCII string representation.
    function _toAsciiString(address x) internal pure virtual returns (string memory) {
        unchecked {
            bytes memory s = new bytes(40);
            for (uint256 i; i != 20; ++i) {
                bytes1 b = bytes1(uint8(uint256(uint160(x)) / (2 ** (8 * (19 - i)))));
                bytes1 hi = bytes1(uint8(b) / 16);
                bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
                s[2 * i] = _char(hi);
                s[2 * i + 1] = _char(lo);
            }
            return string(s);
        }
    }

    /// @dev Convert a single byte to a character in the ASCII string.
    function _char(bytes1 b) internal pure virtual returns (bytes1 c) {
        unchecked {
            uint8 n = uint8(b) & 0xf;
            c = bytes1(n + (n < 10 ? 0x30 : 0x57));
        }
    }

    /// @dev Convert number to string and insert decimal point.
    function _convertWeiToString(uint256 weiAmount, uint256 decimals)
        internal
        pure
        virtual
        returns (string memory)
    {
        unchecked {
            uint256 scalingFactor = 10 ** decimals;
            string memory wholeNumberStr = _toString(weiAmount / scalingFactor);
            string memory decimalPartStr = _toString(weiAmount % scalingFactor);
            while (bytes(decimalPartStr).length != decimals) {
                decimalPartStr = string(abi.encodePacked("0", decimalPartStr));
            }
            decimalPartStr = _removeTrailingZeros(bytes(decimalPartStr));
            if (bytes(decimalPartStr).length == 0) {
                return wholeNumberStr;
            }
            return string(abi.encodePacked(wholeNumberStr, ".", decimalPartStr));
        }
    }

    /// @dev Remove any trailing zeroes from bytes.
    function _removeTrailingZeros(bytes memory str) internal pure virtual returns (string memory) {
        unchecked {
            uint256 len = str.length;
            uint256 end = len;
            while (end != 0 && str[end - 1] == 0x30) {
                --end;
            }
            if (end == len) {
                return string(str);
            }
            bytes memory trimmedBytes = new bytes(end);
            for (uint256 i; i != end; ++i) {
                trimmedBytes[i] = str[i];
            }
            return string(trimmedBytes);
        }
    }

    /// @dev Returns the base 10 decimal representation of `value`.
    /// Modified from (https://github.com/Vectorized/solady/blob/main/src/utils/LibString.sol)
    function _toString(uint256 value) internal pure virtual returns (string memory str) {
        assembly ("memory-safe") {
            str := add(mload(0x40), 0x80)
            mstore(0x40, add(str, 0x20))
            mstore(str, 0)
            let end := str
            let w := not(0)
            for { let temp := value } 1 {} {
                str := add(str, w)
                mstore8(str, add(48, mod(temp, 10)))
                temp := div(temp, 10)
                if iszero(temp) { break }
            }
            let len := sub(end, str)
            str := sub(str, 0x20)
            mstore(str, len)
        }
    }
}

/// @dev ENS name resolution helper contracts interface.
interface IENSHelper {
    function addr(bytes32) external view returns (address);
    function owner(bytes32) external view returns (address);
    function ownerOf(uint256) external view returns (address);
    function resolver(bytes32) external view returns (address);
}

/// @dev Simple token handler interface.
interface IToken {
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
}

/// @notice Simple calldata executor interface.
interface IExecutor {
    function execute(address, uint256, bytes calldata) external payable returns (bytes memory);
}

/// @dev Simple NAMI names interface for resolving L2 ENS ownership.
interface INAMI {
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
