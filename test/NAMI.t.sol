// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {NAMI} from "../src/NAMI.sol";
import {Test} from "../lib/forge-std/src/Test.sol";

contract NAMITest is Test {
    NAMI internal nami;

    string internal constant zname = "z0r0z";
    address internal constant Z0R0Z_DOT_ETH = 0x1C0Aa8cCD568d90d61659F060D1bFb1e6f855A20;
    bytes32 internal constant znode =
        0xa5b4d411903b3ea236b2defe1f96e5a68505e58362e3d8d323fde0b6f8be8ad5;

    string internal constant vname = "vitalik";
    address internal constant VITALIK_DOT_ETH = 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045;
    bytes32 internal constant vnode =
        0xee6c4522aab0003e8d14cd40a6af439055fd2577951148c14b6cea9a53475835;

    function setUp() public payable {
        vm.createSelectFork(vm.rpcUrl("arbi")); // Arbitrum fork.
        nami = new NAMI();
    }

    function testRegister() public payable {
        nami.register(Z0R0Z_DOT_ETH, znode);
        assertEq(Z0R0Z_DOT_ETH, nami.owner(znode));
    }

    function testFailRegister() public payable {
        nami.register(VITALIK_DOT_ETH, vnode);
    }
}
