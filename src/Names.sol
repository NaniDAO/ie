// ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘
// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

/// @title Names
/// @notice A contract for managing ENS domain name ownership and resolution on Arbitrum L2.
/// @dev Provides functions for registering names, verifying ownership, and resolving addresses.
/// @author nani.eth (https://github.com/NaniDAO/ie)
/// @custom:version 1.0.0
contract Names {
    /// ======================= CUSTOM ERRORS ======================= ///

    /// @dev Caller fail.
    error Unauthorized();

    /// =========================== EVENTS =========================== ///

    /// @dev Logs the registration of a name to an owner.
    event Registered(address indexed owner, bytes32 indexed node);

    /// =========================== ENUMS =========================== ///

    /// @dev `ENSAsciiNormalizer` rules.
    enum Rule {
        DISALLOWED,
        VALID
    }

    /// ========================= CONSTANTS ========================= ///

    /// @dev L1_DEPLOYER represents the address responsible for deploying ENS proxy contracts on Ethereum Layer 1.
    /// This address is typically used in conjunction with create2 operations for deterministic deployment.
    address internal constant L1_DEPLOYER = 0x000000008B009D81C933a72545Ed7500cbB5B9D1;

    /// @dev L2_DEPLOYER denotes the address that performs bridged ENS deployments on Arbitrum Layer 2.
    /// Similar to L1_DEPLOYER, it's crucial for deterministic deployment but within the Arbitrum L2 context.
    address internal constant L2_DEPLOYER = 0x3fE38087A94903A9D946fa1915e1772fe611000f;

    /// @dev IMPLEMENTATION refers to the address of the contract serving as the implementation for ENS proxies.
    address internal constant IMPLEMENTATION = 0xEBb49317E567a40cF468c409409aD59a8f67ddE6;

    /// @dev COUNTERPART_GATEWAY is the address of the gateway contract on Arbitrum Layer 2 that pairs with a corresponding
    /// gateway on Ethereum Layer 1. This gateway facilitates the bridging of tokens between L1 and L2, managing the
    /// lock/mint and burn/release mechanics across layers.
    address internal constant COUNTERPART_GATEWAY = 0x09e9222E96E7B4AE2a407B98d48e330053351EEe;

    /// @dev L2_HASH is a unique identifier, used as part of the create2 address computation for contracts on Arbitrum Layer 2.
    bytes32 internal constant L2_HASH =
        0x4b11cb57b978697e0aec0c18581326376d6463fd3f6699cbe78ee5935617082d;

    /// @dev String mapping for `ENSAsciiNormalizer` logic.
    bytes internal constant ASCII_MAP =
        hex"2d00020101000a010700016101620163016401650166016701680169016a016b016c016d016e016f0170017101720173017401750176017701780179017a06001a010500";

    /// ========================== STORAGE ========================== ///

    /// @dev Each index in idnamap refers to an ascii code point.
    /// If idnamap[char] > 2, char maps to a valid ascii character.
    /// Otherwise, idna[char] returns Rule.DISALLOWED or Rule.VALID.
    /// Modified from `ENSAsciiNormalizer` deployed by royalfork.eth
    /// (0x4A5cae3EC0b144330cf1a6CeAD187D8F6B891758).
    bytes1[] internal _idnamap;

    /// @dev Internal mapping of registered name owners.
    mapping(bytes32 => address) internal _owners;

    /// ======================== CONSTRUCTOR ======================== ///

    /// @dev Constructs this IE with `ASCII_MAP`.
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

    /// ====================== ENS VERIFICATION ====================== ///

    /// @dev Returns ENS name ownership details.
    function whatIsTheAddressOf(string calldata name)
        public
        view
        virtual
        returns (address _owner, address _receiver, bytes32 _node)
    {
        _node = _namehash(string(abi.encodePacked(name, ".eth")));
        _owner = owner(_node);
        _receiver = _owner;
    }

    /// @dev Computes an ENS domain namehash.
    function _namehash(string memory domain) internal view virtual returns (bytes32 node) {
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

    /// ======================== REGISTRATION ======================== ///

    /// @dev Registers a new name under an owner.
    function register(address _owner, bytes32 _node) public payable virtual {
        if (!isOwner(_owner, _node)) revert Unauthorized();
        emit Registered(_owners[_node] = _owner, _node);
    }

    /// ====================== OWNERSHIP LOGIC ====================== ///

    /// @dev Checks if an address is the owner of a given node.
    function owner(bytes32 _node) public view virtual returns (address) {
        address _owner = _owners[_node];
        if (!isOwner(_owner, _node)) revert Unauthorized();
        return _owner;
    }

    /// @dev Checks if an address is the owner of a given node.
    function isOwner(address _owner, bytes32 _node) public view virtual returns (bool result) {
        (, address token) = predictDeterministicAddresses(_node);
        uint256 bal;
        uint256 supply;
        assembly ("memory-safe") {
            mstore(0x14, _owner) // Store the `_owner` argument.
            mstore(0x00, 0x70a08231000000000000000000000000) // `balanceOf(address)`.
            bal := mload(staticcall(gas(), token, 0x10, 0x24, 0x20, 0x20))
            mstore(0x00, 0x18160ddd) // `totalSupply()`.
            supply := mload(staticcall(gas(), token, 0x1c, 0x04, 0x20, 0x20))
            result := gt(bal, div(supply, 2))
        }
    }

    /// @dev Returns the deterministic addresses for ENS proxy tokens on L1 & L2.
    function predictDeterministicAddresses(bytes32 _node)
        public
        pure
        virtual
        returns (address l1, address l2)
    {
        l1 = _predictDeterministicAddress(_initCodeHash(bytes.concat(_node)), _node);
        l2 = _calculateL2TokenAddress(l1);
    }

    /// @dev Returns the predicted address on L1 using CWIA pattern.
    function _predictDeterministicAddress(bytes32 hash, bytes32 salt)
        internal
        pure
        virtual
        returns (address predicted)
    {
        assembly ("memory-safe") {
            // Compute and store the bytecode hash.
            mstore8(0x00, 0xff) // Write the prefix.
            mstore(0x35, hash)
            mstore(0x01, shl(96, L1_DEPLOYER))
            mstore(0x15, salt)
            predicted := keccak256(0x00, 0x55)
            mstore(0x35, 0) // Restore the overwritten part of the free memory pointer.
        }
    }

    /// @dev Returns the initCodeHash for the predicted address on L1 using CWIA pattern.
    function _initCodeHash(bytes memory data) internal pure virtual returns (bytes32 hash) {
        assembly ("memory-safe") {
            let mBefore3 := mload(sub(data, 0x60))
            let mBefore2 := mload(sub(data, 0x40))
            let mBefore1 := mload(sub(data, 0x20))
            let dataLength := mload(data)
            let dataEnd := add(add(data, 0x20), dataLength)
            let mAfter1 := mload(dataEnd)
            returndatacopy(returndatasize(), returndatasize(), gt(dataLength, 0xff9b))
            let extraLength := add(dataLength, 2)
            mstore(data, 0x5af43d3d93803e606057fd5bf3)
            mstore(sub(data, 0x0d), IMPLEMENTATION)
            mstore(
                sub(data, 0x21),
                or(shl(0x48, extraLength), 0x593da1005b363d3d373d3d3d3d610000806062363936013d73)
            )
            mstore(
                sub(data, 0x3a), 0x9e4ac34f21c619cefc926c8bd93b54bf5a39c7ab2127a895af1cc0691d7e3dff
            )
            mstore(
                sub(data, 0x5a),
                or(shl(0x78, add(extraLength, 0x62)), 0x6100003d81600a3d39f336602c57343d527f)
            )
            mstore(dataEnd, shl(0xf0, extraLength))
            hash := keccak256(sub(data, 0x4c), add(extraLength, 0x6c))
            mstore(dataEnd, mAfter1)
            mstore(data, dataLength)
            mstore(sub(data, 0x20), mBefore1)
            mstore(sub(data, 0x40), mBefore2)
            mstore(sub(data, 0x60), mBefore3)
        }
    }

    /// @dev Returns the predicted L2 token address using Arbitrum create2 methods.
    function _calculateL2TokenAddress(address l1ERC20) internal pure virtual returns (address) {
        return address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff),
                            L2_DEPLOYER,
                            keccak256(
                                abi.encode(COUNTERPART_GATEWAY, keccak256(abi.encode(l1ERC20)))
                            ),
                            L2_HASH
                        )
                    )
                )
            )
        );
    }
}
