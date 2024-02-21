// ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘
// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

/// @title NANI ARBITRUM MAGIC INVOICE (NAMI)
/// @notice A contract for managing ENS domain name ownership and resolution on Arbitrum L2.
/// @dev Provides functions for registering names, verifying ownership, and resolving addresses.
/// @author nani.eth (https://github.com/NaniDAO/ie)
/// @custom:version 1.0.0
contract NAMI {
    /// ======================= CUSTOM ERRORS ======================= ///

    /// @dev Unregistered.
    error Unregistered();

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

    /// @dev The governing DAO address.
    address internal constant DAO = 0xDa000000000000d2885F108500803dfBAaB2f2aA;

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

    /// @dev Internal mapping of registered node owners.
    mapping(bytes32 node => address) internal _owners;

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

    /// @dev Registers a new name under an owner. ENS L1 node must be bridged.
    function register(address _owner, bytes32 _node) public payable virtual {
        if (!isOwner(_owner, _node)) revert Unregistered();
        emit Registered(_owners[_node] = _owner, _node);
    }

    /// @dev Registers a new subname under an owner. Only the DAO may call this function.
    function registerSub(address _owner, string calldata _subname) public payable virtual {
        assembly ("memory-safe") {
            if iszero(eq(caller(), DAO)) { revert(codesize(), 0x00) } // Optimized for repeat.
        }
        bytes32 subnode = _namehash(string(abi.encodePacked(_subname, ".nani.eth")));
        emit Registered(_owners[subnode] = _owner, subnode);
    }

    /// ====================== OWNERSHIP LOGIC ====================== ///

    /// @dev Returns the registered owner of a given ENS L1 node. Must be bridged.
    /// note: Alternatively, NAMI provides subdomains issued under `nani.eth` node.
    function owner(bytes32 _node) public view virtual returns (address _owner) {
        _owner = _owners[_node];
        if (_owner == address(0) || !isOwner(_owner, _node)) revert Unregistered();
    }

    /// @dev Checks if an address is the owner of a given ENS L1 node represented as `l2Token`.
    /// note: NAMI operates under the assumption that the proper owner-receiver holds majority.
    function isOwner(address _owner, bytes32 _node) public view virtual returns (bool) {
        (, address l2Token) = predictDeterministicAddresses(_node);
        return IToken(l2Token).balanceOf(_owner) > (IToken(l2Token).totalSupply() / 2);
    }

    /// @dev Returns the deterministic create2 addresses for ENS node tokens on L1 & L2.
    function predictDeterministicAddresses(bytes32 _node)
        public
        pure
        virtual
        returns (address l1Token, address l2Token)
    {
        l1Token = _predictDeterministicAddress(_initCodeHash(bytes.concat(_node)), _node);
        l2Token = _calculateL2TokenAddress(l1Token);
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
            let dataEnd := add(add(data, 0x20), 0x20)
            let mAfter1 := mload(dataEnd)
            returndatacopy(returndatasize(), returndatasize(), gt(0x20, 0xff9b))
            let extraLength := add(0x20, 2)
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
            mstore(data, 0x20)
            mstore(sub(data, 0x20), mBefore1)
            mstore(sub(data, 0x40), mBefore2)
            mstore(sub(data, 0x60), mBefore3)
        }
    }

    /// @dev Returns the predicted `l2Token` address using Arbitrum create2 bridge preview methods on `l1Token`.
    function _calculateL2TokenAddress(address l1Token)
        internal
        pure
        virtual
        returns (address l2Token)
    {
        return address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff),
                            L2_DEPLOYER,
                            keccak256(
                                abi.encode(COUNTERPART_GATEWAY, keccak256(abi.encode(l1Token)))
                            ),
                            L2_HASH
                        )
                    )
                )
            )
        );
    }
}

/// @dev Simple token balance & supply interface.
interface IToken {
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
}
