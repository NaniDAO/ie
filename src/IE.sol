// ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘
// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {LibString} from "../lib/solady/src/utils/LibString.sol";
import {SafeTransferLib} from "../lib/solady/src/utils/SafeTransferLib.sol";
import {MetadataReaderLib} from "../lib/solady/src/utils/MetadataReaderLib.sol";

/// @title Intents Engine (IE)
/// @notice Simple helper contract for turning transactional intents into executable code.
/// @dev V0 simulates the output of typical commands (sending assets) and allows execution.
/// IE also has workflow to verify the intent of ERC-4337 account userOps against calldata.
/// @author nani.eth (https://github.com/NaniDAO/ie)
/// @custom:version 0.0.0
contract IE {
    /// ======================= LIBRARY USAGE ======================= ///

    /// @dev Metadata reader library.
    using MetadataReaderLib for address;

    /// @dev Safe asset transfer library.
    using SafeTransferLib for address;

    /// ======================= CUSTOM ERRORS ======================= ///

    /// @dev Caller fails.
    error Unauthorized();

    /// @dev Invalid command form.
    error InvalidSyntax();

    /// @dev Non-numeric character.
    error InvalidCharacter();

    /// =========================== EVENTS =========================== ///

    /// @dev Logs the registration of an asset name.
    event NameSet(address indexed asset, string name);

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

    /// ========================= CONSTANTS ========================= ///

    /// @dev The governing DAO address.
    address internal constant DAO = 0xDa000000000000d2885F108500803dfBAaB2f2aA;

    /// @dev The NANI token address.
    address internal constant NANI = 0x00000000000025824328358250920B271f348690;

    /// @dev The conventional ERC7528 ETH address.
    address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @dev The canonical wrapped ETH address.
    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

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

    /// ========================== STORAGE ========================== ///

    /// @dev DAO-governed asset address naming.
    mapping(string name => address) public assets;

    /// ======================== CONSTRUCTOR ======================== ///

    /// @dev Constructs
    /// this implementation.
    constructor() payable {}

    /// ====================== COMMAND PREVIEW ====================== ///

    /// @dev Preview command. `send` syntax uses ENS name: 'send vitalik 20 DAI'.
    function previewCommand(string calldata intent)
        public
        view
        virtual
        returns (
            address to, // Receiver address.
            uint256 amount, // Formatted amount.
            address asset, // Asset to send `to`.
            bytes memory callData, // Raw calldata for send transaction.
            bytes memory executeCallData // Anticipates common execute API.
        )
    {
        string memory normalizedIntent = LibString.toCase(intent, false);
        bytes32 action = _extraction(normalizedIntent);
        if (action == "send" || action == "transfer" || action == "give") {
            (string memory _to, string memory _amount, string memory _asset) =
                _extractSend(normalizedIntent);
            (to, amount, asset, callData, executeCallData) = previewSend(_to, _amount, _asset);
        } else {
            revert InvalidSyntax();
        }
    }

    /// @dev Returns formatted preview for `send` operations from parts of a command.
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
        )
    {
        _asset = _returnConstant(bytes32(bytes(asset))); // Check constant.
        if (_asset == address(0)) _asset = assets[asset]; // Check storage.
        bool isEth = _asset == ETH; // Memo whether the asset is ETH or not.
        (, _to,) = whatIsTheAddressOf(to); // Fetch receiver address from ENS.
        _amount = _stringToUint(amount, isEth ? 18 : _asset.readDecimals());
        if (!isEth) callData = abi.encodeCall(IAsset.transfer, (_to, _amount));
        executeCallData =
            abi.encodeCall(IExecutor.execute, (isEth ? _to : _asset, isEth ? _amount : 0, callData));
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

    /// @dev Checks and returns the canonical constant for a matched intent string.
    function _returnConstant(bytes32 asset) internal view virtual returns (address _asset) {
        if (asset == "eth" || msg.value != 0) return ETH;
        if (asset == "usdc") return USDC;
        if (asset == "usdt") return USDT;
        if (asset == "dai") return DAI;
        if (asset == "weth") return WETH;
        if (asset == "nani") return NANI;
    }

    /// ===================== COMMAND EXECUTION ===================== ///

    /// @dev Executes a command from an intent string.
    function command(string calldata intent) public payable virtual {
        string memory normalizedIntent = LibString.toCase(intent, false);
        bytes32 action = _extraction(normalizedIntent);
        if (action == "send" || action == "transfer" || action == "give") {
            (string memory to, string memory amount, string memory asset) =
                _extractSend(normalizedIntent);
            send(to, amount, asset);
        } else {
            revert InvalidSyntax();
        }
    }

    /// @dev Executes a send command from the parts of a matched intent string.
    function send(string memory to, string memory amount, string memory asset)
        public
        payable
        virtual
    {
        address _asset = _returnConstant(bytes32(bytes(asset)));
        if (_asset == address(0)) _asset = assets[asset];
        (, address _to,) = whatIsTheAddressOf(to);
        if (_asset == ETH) {
            _to.safeTransferETH(_stringToUint(amount, 18));
        } else {
            _asset.safeTransferFrom(msg.sender, _to, _stringToUint(amount, _asset.readDecimals()));
        }
    }

    /// ================== BALANCE & SUPPLY HELPERS ================== ///

    /// @dev Returns your balance in a named asset.
    function whatIsMyBalanceIn(string calldata asset)
        public
        view
        virtual
        returns (uint256 balance, uint256 balanceAdjusted)
    {
        string memory normalizeAsset = LibString.toCase(asset, false);
        address _asset = _returnConstant(bytes32(bytes(normalizeAsset)));
        if (_asset == address(0)) _asset = assets[asset];
        bool isEth = _asset == ETH;
        balance = isEth ? msg.sender.balance : _balanceOf(_asset, msg.sender);
        balanceAdjusted = balance / 10 ** (isEth ? 18 : _asset.readDecimals());
    }

    /// @dev Returns the balance of a named account in a named asset.
    function whatIsTheBalanceOf(string calldata name, /*(bob)*/ /*in*/ string calldata asset)
        public
        view
        virtual
        returns (uint256 balance, uint256 balanceAdjusted)
    {
        (, address _name,) = whatIsTheAddressOf(name);
        string memory normalizeAsset = LibString.toCase(asset, false);
        address _asset = _returnConstant(bytes32(bytes(normalizeAsset)));
        if (_asset == address(0)) _asset = assets[asset];
        bool isEth = _asset == ETH;
        balance = isEth ? _name.balance : _balanceOf(_asset, _name);
        balanceAdjusted = balance / 10 ** (isEth ? 18 : _asset.readDecimals());
    }

    /// @dev Returns the total supply of a named asset.
    function whatIsTheTotalSupplyOf(string calldata asset)
        public
        view
        virtual
        returns (uint256 supply, uint256 supplyAdjusted)
    {
        address _asset = _returnConstant(bytes32(bytes(asset)));
        if (_asset == address(0)) _asset = assets[asset];
        if (_asset == ETH) revert InvalidSyntax();
        supply = _totalSupply(_asset);
        supplyAdjusted = supply / 10 ** _asset.readDecimals();
    }

    /// @dev Returns the amount of ERC20/721 `asset` owned by `account`.
    function _balanceOf(address asset, address account)
        internal
        view
        virtual
        returns (uint256 amount)
    {
        assembly ("memory-safe") {
            mstore(0x00, 0x70a08231000000000000000000000000) // `balanceOf(address)`.
            mstore(0x14, account) // Store the `account` argument.
            if iszero(staticcall(gas(), asset, 0x10, 0x24, 0x20, 0x20)) { revert(codesize(), 0x00) }
            amount := mload(0x20)
        }
    }

    /// @dev Returns the total supply of ERC20/721 `asset`.
    function _totalSupply(address asset) internal view virtual returns (uint256 supply) {
        assembly ("memory-safe") {
            mstore(0x00, 0x18160ddd) // `totalSupply()`.
            if iszero(staticcall(gas(), asset, 0x1c, 0x04, 0x20, 0x20)) { revert(codesize(), 0x00) }
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

    /// @dev Sets a public name tag for a given asset address. Governed by DAO.
    function setName(address asset, string calldata name) public payable virtual {
        if (msg.sender != DAO) revert Unauthorized();
        string memory normalizedName = LibString.toCase(name, false);
        emit NameSet(assets[normalizedName] = asset, normalizedName);
    }

    /// ================= INTERNAL STRING OPERATIONS ================= ///

    /// @dev Extracts first word (action) from a string.
    function _extraction(string memory normalizedIntent) internal pure virtual returns (bytes32) {
        bytes memory stringBytes = bytes(normalizedIntent);
        uint256 endIndex = stringBytes.length;
        for (uint256 i; i != stringBytes.length; ++i) {
            if (stringBytes[i] == 0x20) {
                endIndex = i;
                break;
            }
        }
        bytes memory firstWordBytes = new bytes(endIndex);
        for (uint256 i; i != endIndex; ++i) {
            firstWordBytes[i] = stringBytes[i];
        }
        return bytes32(firstWordBytes);
    }

    /// @dev Extract key words of normalized `send` intent.
    function _extractSend(string memory normalizedIntent)
        internal
        pure
        virtual
        returns (string memory to, string memory amount, string memory asset)
    {
        string[] memory parts = _split(normalizedIntent, " ");
        if (parts.length == 4) return (parts[1], parts[2], parts[3]);
        if (parts.length == 5) return (parts[4], parts[1], parts[2]);
        else revert InvalidSyntax(); // Command is not formatted.
    }

    /// @dev Split the intent into an array of words.
    function _split(string memory base, bytes1 value)
        internal
        pure
        virtual
        returns (string[] memory)
    {
        uint256 index;
        uint256 count = 1;
        bytes memory baseBytes = bytes(base);
        for (uint256 i; i != baseBytes.length; ++i) {
            if (baseBytes[i] == value) ++count;
        }
        string[] memory array = new string[](count);
        for (uint256 i; i != baseBytes.length; ++i) {
            if (baseBytes[i] == value) {
                ++index;
            } else {
                array[index] = _concat(array[index], baseBytes[i]);
            }
        }
        return array;
    }

    /// @dev Perform string concatenation on base.
    function _concat(string memory base, bytes1 value)
        internal
        pure
        virtual
        returns (string memory)
    {
        unchecked {
            bytes memory baseBytes = bytes(base);
            bytes memory result = new bytes(baseBytes.length + 1);
            for (uint256 i; i != baseBytes.length; ++i) {
                result[i] = baseBytes[i];
            }
            result[baseBytes.length] = value;
            return string(result);
        }
    }

    /// @dev Convert string to decimalized numerical value.
    function _stringToUint(string memory s, uint8 decimals)
        internal
        pure
        virtual
        returns (uint256)
    {
        unchecked {
            uint256 result;
            bool hasDecimal;
            uint256 decimalPlaces;
            bytes memory b = bytes(s);
            for (uint256 i; i != b.length; ++i) {
                if (b[i] >= "0" && b[i] <= "9") {
                    result = result * 10 + (uint256(uint8(b[i])) - 48);
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
            return result;
        }
    }
}

/// @dev Simple asset transfer interface.
interface IAsset {
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
