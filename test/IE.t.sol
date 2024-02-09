// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {IENSHelper, IE} from "../src/IE.sol";
import {Test} from "../lib/forge-std/src/Test.sol";

contract IETest is Test {
    address internal constant DAO = 0xDa000000000000d2885F108500803dfBAaB2f2aA;

    address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address internal constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address internal constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal constant SUSHI = 0x6B3595068778DD592e39A122f4f5a5cF09C90fE2;
    address internal constant UNI = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;
    address internal constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address internal constant OMG = 0xd26114cd6EE289AccF82350c8d8487fedB8A0C07;

    address internal constant VITALIK_DOT_ETH = 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045;
    address internal constant Z0R0Z_DOT_ETH = 0x1C0Aa8cCD568d90d61659F060D1bFb1e6f855A20;
    address internal constant NANI_DOT_ETH = 0x7AF890Ca7262D6accdA5c9D24AC42e35Bb293188;

    address internal constant USDC_WHALE = 0xD6153F5af5679a75cC85D8974463545181f48772;

    IE internal ie; // Intents Engine.

    function setUp() public payable {
        vm.createSelectFork(vm.rpcUrl("main")); // Ethereum mainnet fork.
        ie = new IE();
        vm.prank(DAO);
        ie.setName(ETH, "ETH");
        vm.prank(DAO);
        ie.setName(ETH, "ether");
        vm.prank(DAO);
        ie.setName(ETH, "ethereum");
        vm.prank(DAO);
        ie.setName(DAI, "DAI");
        vm.prank(DAO);
        ie.setName(USDC, "USDC");
        vm.prank(DAO);
        ie.setName(WETH, "WETH");
        vm.prank(DAO);
        ie.setName(WETH, "wrapped eth");
        vm.prank(DAO);
        ie.setName(WETH, "wrapped ether");
        vm.prank(DAO);
        ie.setName(SUSHI, "SUSHI");
        vm.prank(DAO);
        ie.setName(UNI, "UNI");
        vm.prank(DAO);
        ie.setName(USDT, "USDT");
        vm.prank(DAO);
        ie.setName(USDT, "tether");
        vm.prank(DAO);
        ie.setName(OMG, "omg");
    }

    function testDeploy() public payable {
        new IE();
    }

    function testENSNameOwnership() public payable {
        (, address receiver,) = ie.whatIsTheAddressOf("vitalik");
        assertEq(receiver, VITALIK_DOT_ETH);
        (, receiver,) = ie.whatIsTheAddressOf("z0r0z");
        assertEq(receiver, Z0R0Z_DOT_ETH);
        (, receiver,) = ie.whatIsTheAddressOf("nani");
        assertEq(receiver, NANI_DOT_ETH);
    }

    function testENSNameFromENSHelper() public payable {
        (address result,) =
            IENSHelper(0x4A5cae3EC0b144330cf1a6CeAD187D8F6B891758).owner("vitalik.eth");
        assertEq(result, VITALIK_DOT_ETH);
    }

    function testPreviewSendCommand() public payable {
        string memory command = "send vitalik 20 dai";
        (address to, uint256 amount, address asset,,) = ie.previewCommand(command);
        assertEq(to, VITALIK_DOT_ETH);
        assertEq(amount, 20 ether);
        assertEq(asset, DAI);
    }

    function testPreviewSend() public payable {
        (address to, uint256 amount, address asset,,) = ie.previewSend("vitalik", "20", "dai");
        assertEq(to, VITALIK_DOT_ETH);
        assertEq(amount, 20 ether);
        assertEq(asset, DAI);
    }

    function testPreviewCommandSendUSDC() public payable {
        string memory command = "send z0r0z 20 usdc";
        (address to, uint256 amount, address asset,,) = ie.previewCommand(command);
        assertEq(to, Z0R0Z_DOT_ETH);
        assertEq(amount, 20000000);
        assertEq(asset, USDC);
    }

    function testPreviewCommandSendDecimals() public payable {
        string memory command = "send vitalik 20.2 dai";
        (address to, uint256 amount, address asset,,) = ie.previewCommand(command);
        assertEq(to, VITALIK_DOT_ETH);
        assertEq(amount, 20.2 ether);
        assertEq(asset, DAI);
        command = "send vitalik 20.23345 eth";
        (to, amount, asset,,) = ie.previewCommand(command);
        assertEq(to, VITALIK_DOT_ETH);
        assertEq(amount, 20.23345 ether);
        assertEq(asset, ETH);
    }

    function testIENameSetting() public payable {
        assertEq(ie.assets("uni"), UNI);
    }

    function testTotalSupply() public payable {
        (uint256 supply, uint256 adjustedSupply) = ie.whatIsTheTotalSupplyOf("uni");
        assertEq(supply, 1000000000000000000000000000);
        assertEq(adjustedSupply, 1000000000);
    }

    function testBalanceInERC20() public payable {
        uint256 vBal = IERC20(OMG).balanceOf(VITALIK_DOT_ETH);
        (uint256 balance, uint256 adjustedBalance) = ie.whatIsTheBalanceOf("VITALIK", "omg");
        assertEq(balance, vBal);
        assertEq(adjustedBalance, vBal / 10 ** 18);
    }

    function testBalanceInETH() public payable {
        uint256 vBal = VITALIK_DOT_ETH.balance;
        (uint256 balance, uint256 adjustedBalance) = ie.whatIsTheBalanceOf("VITALIK", "eth");
        assertEq(balance, vBal);
        assertEq(adjustedBalance, vBal / 10 ** 18);
    }

    function testCommandSendETH() public payable {
        uint256 vBal = VITALIK_DOT_ETH.balance;
        uint256 zBal = Z0R0Z_DOT_ETH.balance;
        vm.prank(VITALIK_DOT_ETH);
        ie.command{value: 1 ether}("send z0r0z 1 ETH");
        assertEq(VITALIK_DOT_ETH.balance, vBal - 1 ether);
        assertEq(Z0R0Z_DOT_ETH.balance, zBal + 1 ether);
    }

    function testCommandSendERC0() public payable {
        vm.prank(VITALIK_DOT_ETH);
        IERC20(OMG).approve(address(ie), 100 ether);
        uint256 vBal = IERC20(OMG).balanceOf(VITALIK_DOT_ETH);
        uint256 zBal = IERC20(OMG).balanceOf(Z0R0Z_DOT_ETH);
        vm.prank(VITALIK_DOT_ETH);
        ie.command("send z0r0z 100 OMG");
        assertEq(IERC20(OMG).balanceOf(VITALIK_DOT_ETH), vBal - 100 ether);
        assertEq(IERC20(OMG).balanceOf(Z0R0Z_DOT_ETH), zBal + 100 ether);
    }

    function testCommandSendUSDC() public payable {
        vm.prank(USDC_WHALE);
        IERC20(USDC).approve(address(ie), 100 ether);
        uint256 wBal = IERC20(USDC).balanceOf(USDC_WHALE);
        uint256 zBal = IERC20(USDC).balanceOf(Z0R0Z_DOT_ETH);
        vm.prank(USDC_WHALE);
        ie.command("send z0r0z 100 USDC");
        assertEq(IERC20(USDC).balanceOf(USDC_WHALE), wBal - 100000000);
        assertEq(IERC20(USDC).balanceOf(Z0R0Z_DOT_ETH), zBal + 100000000);
    }

    function testSendETH() public payable {
        uint256 vBal = VITALIK_DOT_ETH.balance;
        uint256 zBal = Z0R0Z_DOT_ETH.balance;
        vm.prank(VITALIK_DOT_ETH);
        ie.send{value: 1 ether}("z0r0z", "1", "ETH");
        assertEq(VITALIK_DOT_ETH.balance, vBal - 1 ether);
        assertEq(Z0R0Z_DOT_ETH.balance, zBal + 1 ether);
    }
}

interface IERC20 {
    function approve(address, uint256) external; // unsafe lol.
    function balanceOf(address) external view returns (uint256);
}
