// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {LibString} from "../lib/solady/src/utils/LibString.sol";
import {SafeTransferLib} from "../lib/solady/src/utils/SafeTransferLib.sol";

/// @title Intent Executor
/// @notice Simple helper contract for turning transactional intents into executable code.
/// @dev V0 simulates the output of typical commands (sending assets) and allows execution.
/// @author nani.eth (https://github.com/NaniDAO/ie)
/// @custom:version 0.0.0
contract IE {
    /// @dev Safe asset transfer library.
    using SafeTransferLib for address;

    /// ======================= CUSTOM ERRORS ======================= ///

    /// @dev ENS fails.
    error InvalidName();

    /// @dev Caller fails.
    error Unauthorized();

    /// @dev Invalid command.
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

    /// @dev The conventional ERC7528 ETH address.
    address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

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

    /// ========================== PREVIEW GETTERS ========================== ///

    /// @dev Preview command. `Send` syntax uses ENS name: 'send vitalik 20 DAI'
    function previewCommand(string calldata intent)
        public
        view
        virtual
        returns (
            address to, // Recipient address.
            uint256 amount, // Formatted amount.
            address asset, // Asset to send `to`.
            bytes memory callData, // Raw calldata for send transaction.
            bytes memory executeCallData // Anticipates common execute API.
        )
    {
        string memory normalizedIntent = LibString.toCase(intent, false);
        if (
            LibString.contains(normalizedIntent, "send")
                || LibString.contains(normalizedIntent, "transfer")
                || LibString.contains(normalizedIntent, "give")
        ) {
            (string memory _to, string memory _amount, string memory _asset) =
                _extractDetails(normalizedIntent);
            (to, amount, asset, callData, executeCallData) = previewSend(_to, _amount, _asset);
        } else {
            revert InvalidSyntax();
        }
    }

    /// @dev Returns formatted preview for send operations based on parts of command.
    function previewSend(string memory to, string memory amount, string memory asset)
        public
        view
        returns (
            address _to,
            uint256 _amount,
            address _asset,
            bytes memory callData,
            bytes memory executeCallData
        )
    {
        _asset = assets[asset];
        (, _to,) = getNameOwnership(to);
        _amount = _stringToUint(amount, _asset == ETH ? 18 : IAsset(_asset).decimals());
        if (_asset != ETH) callData = abi.encodeCall(IAsset.transfer, (_to, _amount));
        executeCallData = abi.encodeCall(
            IExecutor.execute, (_asset == ETH ? _to : _asset, _asset == ETH ? _amount : 0, callData)
        );
    }

    /// @dev Checks ERC4337 userOp against the output of the command intent.
    function checkUserOp(string calldata intent, UserOperation calldata userOp)
        public
        view
        returns (bool)
    {
        (,,,, bytes memory executeCallData) = previewCommand(intent);
        if (userOp.callData.length != executeCallData.length) return false;
        return keccak256(userOp.callData) == keccak256(executeCallData);
    }

    /// ============================ SEND OPERATIONS ============================ ///

    function command(string calldata intent) public payable {
        string memory normalizedIntent = LibString.toCase(intent, false);
        if (
            LibString.contains(normalizedIntent, "send")
                || LibString.contains(normalizedIntent, "transfer")
                || LibString.contains(normalizedIntent, "give")
        ) {
            (string memory to, string memory amount, string memory asset) =
                _extractDetails(normalizedIntent);
            _send(to, amount, asset);
        }
    }

    function _send(string memory to, string memory amount, string memory asset) internal {
        unchecked {
            address _asset = assets[asset];
            (, address _to,) = getNameOwnership(to);
            if (_asset == ETH) {
                _to.safeTransferETH(_stringToUint(amount, 18));
            } else {
                _asset.safeTransferFrom(
                    msg.sender, _to, _stringToUint(amount, IAsset(_asset).decimals())
                );
            }
        }
    }

    /// ========================== ENS VERIFICATION ========================== ///

    function getNameOwnership(string memory name)
        public
        view
        returns (address owner, address receiver, bytes32 node)
    {
        (owner, node) = ENS_HELPER.owner(string(abi.encodePacked(name, ".eth")));
        if (IENSHelper(owner) == ENS_WRAPPER) owner = ENS_WRAPPER.ownerOf(uint256(node));
        receiver = IENSHelper(ENS_REGISTRY.resolver(node)).addr(node);
        if (receiver == address(0)) revert InvalidName();
    }

    /// ========================= GOVERNANCE SETTINGS ========================= ///

    function setName(address asset, string calldata name) public payable {
        if (msg.sender != DAO) revert Unauthorized();
        string memory normalizedName = LibString.toCase(name, false);
        emit NameSet(assets[normalizedName] = asset, normalizedName);
    }

    /// ========================== INTERNAL OPERATIONS ========================== ///

    function _extractDetails(string memory normalizedIntent)
        internal
        pure
        returns (string memory to, string memory amount, string memory asset)
    {
        // Format: `[action:send]:[to][amount][asset]`.
        string[] memory parts = _split(normalizedIntent, " ");
        if (parts.length < 4) revert InvalidSyntax();
        return (parts[1], parts[2], parts[3]);
    }

    function _split(string memory base, bytes1 value) internal pure returns (string[] memory) {
        uint256 index;
        uint256 count = 1;
        bytes memory baseBytes = bytes(base);
        for (uint256 i; i < baseBytes.length; ++i) {
            if (baseBytes[i] == value) ++count;
        }
        string[] memory array = new string[](count);
        for (uint256 i; i < baseBytes.length; ++i) {
            if (baseBytes[i] == value) {
                ++index;
            } else {
                array[index] = _concat(array[index], baseBytes[i]);
            }
        }
        return array;
    }

    function _concat(string memory base, bytes1 value) internal pure returns (string memory) {
        bytes memory baseBytes = bytes(base);
        bytes memory result = new bytes(baseBytes.length + 1);
        for (uint256 i; i < baseBytes.length; ++i) {
            result[i] = baseBytes[i];
        }
        result[baseBytes.length] = value;
        return string(result);
    }

    function _stringToUint(string memory s, uint8 decimals) internal pure returns (uint256) {
        unchecked {
            bytes memory b = bytes(s);
            uint256 beforeDecimal;
            uint256 afterDecimal;
            uint256 decimalPlace;
            bool decimalFound;
            for (uint256 i; i != b.length; ++i) {
                if (b[i] == ".") {
                    decimalFound = true;
                    continue;
                }
                uint256 c = uint256(uint8(b[i])) - 48;
                if (decimalFound) {
                    if (decimalPlace < decimals) {
                        afterDecimal = afterDecimal * 10 + c;
                        ++decimalPlace;
                    }
                } else {
                    beforeDecimal = beforeDecimal * 10 + c;
                }
            }
            if (decimalFound && decimalPlace < decimals) {
                afterDecimal *= 10 ** (decimals - decimalPlace);
            }
            return beforeDecimal * 10 ** decimals + afterDecimal;
        }
    }
}

/// @dev Simple asset transfer interface.
interface IAsset {
    function decimals() external view returns (uint8);
    function transfer(address, uint256) external view returns (bool);
}

/// @notice Simple calldata executor interface.
interface IExecutor {
    function execute(address, uint256, bytes calldata) external payable returns (bytes memory);
}

/// @dev ENS name normalizer helper contract interface.
interface IENSHelper {
    function addr(bytes32) external view returns (address);
    function ownerOf(uint256) external view returns (address);
    function resolver(bytes32) external view returns (address);
    function owner(string calldata) external view returns (address, bytes32);
}
