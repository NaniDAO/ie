// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {IENSHelper, IETH} from "../src/IETH.sol";
import {Test} from "../lib/forge-std/src/Test.sol";

contract IETHTest is Test {
    address internal constant DAO = 0xDa000000000000d2885F108500803dfBAaB2f2aA;

    address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address internal constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address internal constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal constant SUSHI = 0x6B3595068778DD592e39A122f4f5a5cF09C90fE2;
    address internal constant UNI = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;
    address internal constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address internal constant OMG = 0xd26114cd6EE289AccF82350c8d8487fedB8A0C07;
    address internal constant WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;

    address internal constant VITALIK_DOT_ETH = 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045;
    address internal constant Z0R0Z_DOT_ETH = 0x1C0Aa8cCD568d90d61659F060D1bFb1e6f855A20;
    address internal constant NANI_DOT_ETH = 0xDa000000000000d2885F108500803dfBAaB2f2aA;

    address internal constant USDC_WHALE = 0xD6153F5af5679a75cC85D8974463545181f48772;
    address internal constant DAI_WHALE = 0xD1668fB5F690C59Ab4B0CAbAd0f8C1617895052B;

    bytes internal constant ASCII_MAP =
        hex"2d00020101000a010700016101620163016401650166016701680169016a016b016c016d016e016f0170017101720173017401750176017701780179017a06001a010500";

    IETH internal ie; // Intents Engine on Ethereum.

    function setUp() public payable {
        vm.createSelectFork(vm.rpcUrl("main")); // Ethereum mainnet fork.
        ie = new IETH();
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
        new IETH();
    }

    function testENSNameOwnership() public payable {
        (, address receiver,) = ie.whatIsTheAddressOf("vitalik");
        assertEq(receiver, VITALIK_DOT_ETH);
        (, receiver,) = ie.whatIsTheAddressOf("z0r0z");
        assertEq(receiver, Z0R0Z_DOT_ETH);
        (, receiver,) = ie.whatIsTheAddressOf("nani");
        assertEq(receiver, NANI_DOT_ETH);
    }

    function testPreviewSendCommand() public payable {
        string memory command = "send vitalik 20 dai";
        (address to, uint256 amount,, address asset,,) = ie.previewCommand(command);
        assertEq(to, VITALIK_DOT_ETH);
        assertEq(amount, 20 ether);
        assertEq(asset, DAI);
    }

    function testPreviewCommandSendUSDC() public payable {
        string memory command = "send z0r0z 20 usdc";
        (address to, uint256 amount,, address asset,,) = ie.previewCommand(command);
        assertEq(to, Z0R0Z_DOT_ETH);
        assertEq(amount, 20000000);
        assertEq(asset, USDC);
    }

    function testPreviewCommandSendDecimals() public payable {
        string memory command = "send vitalik 20.2 dai";
        (address to, uint256 amount,, address asset,,) = ie.previewCommand(command);
        assertEq(to, VITALIK_DOT_ETH);
        assertEq(amount, 20.2 ether);
        assertEq(asset, DAI);
        command = "send vitalik 20.23345 eth";
        (to, amount,, asset,,) = ie.previewCommand(command);
        assertEq(to, VITALIK_DOT_ETH);
        assertEq(amount, 20.23345 ether);
        assertEq(asset, ETH);
    }

    function testIENameSetting() public payable {
        assertEq(ie.addresses("uni"), UNI);
    }

    function testCommandSendETH() public payable {
        uint256 vBal = VITALIK_DOT_ETH.balance;
        uint256 zBal = Z0R0Z_DOT_ETH.balance;
        vm.prank(VITALIK_DOT_ETH);
        ie.command{value: 1 ether}("send z0r0z 1 ETH");
        assertEq(VITALIK_DOT_ETH.balance, vBal - 1 ether);
        assertEq(Z0R0Z_DOT_ETH.balance, zBal + 1 ether);
    }

    error InvalidSyntax();

    function testCommandSendETHFailInvalidSyntax0() public payable {
        vm.prank(VITALIK_DOT_ETH);
        vm.expectRevert(InvalidSyntax.selector);
        ie.command{value: 1 ether}("sned z0r0z 1 ETH");
    }

    function testCommandSendETHFailInvalidSyntax1() public payable {
        vm.prank(VITALIK_DOT_ETH);
        vm.expectRevert(InvalidSyntax.selector);
        ie.command{value: 1 ether}("sendz0r0z 1 ETH");
    }

    function testCommandSendETHFailInvalidSyntax2() public payable {
        vm.prank(VITALIK_DOT_ETH);
        vm.expectRevert(InvalidSyntax.selector);
        ie.command{value: 1 ether}("send z0r0z1 ETH");
    }

    function testCommandSendETHFailInvalidSyntax3() public payable {
        vm.prank(VITALIK_DOT_ETH);
        vm.expectRevert(InvalidSyntax.selector);
        ie.command{value: 1 ether}("send z0r0z 1ETH");
    }

    function testSwapETHFailInvalidSyntax0() public payable {
        vm.prank(VITALIK_DOT_ETH);
        vm.expectRevert(InvalidSyntax.selector);
        ie.command{value: 1 ether}("swap z0r0z 1 ETH");
    }

    function testSwapETHFailInvalidSyntax1() public payable {
        vm.prank(VITALIK_DOT_ETH);
        vm.expectRevert();
        ie.command{value: 1 ether}("swap 1 ETH for z0r0z");
    }

    function testSwapETHFailInvalidSyntax2() public payable {
        vm.prank(VITALIK_DOT_ETH);
        vm.expectRevert();
        ie.command{value: 1 ether}("swap 1 ETH for usdc forz0r0z");
    }

    function testSwapETHFailInvalidSyntax3() public payable {
        vm.prank(VITALIK_DOT_ETH);
        vm.expectRevert();
        ie.command{value: 1 ether}("swap 1 ETH forusdc for z0r0z");
    }

    function testSwapETHFailInvalidSyntax4() public payable {
        vm.prank(VITALIK_DOT_ETH);
        vm.expectRevert(InvalidSyntax.selector);
        ie.command{value: 1 ether}("swap ETH 1 z0r0z");
    }

    function testCommandSendETHRawAddr() public payable {
        uint256 vBal = VITALIK_DOT_ETH.balance;
        uint256 zBal = Z0R0Z_DOT_ETH.balance;
        vm.prank(VITALIK_DOT_ETH);
        ie.command{value: 1 ether}("send 0x1C0Aa8cCD568d90d61659F060D1bFb1e6f855A20 1 ETH");
        assertEq(VITALIK_DOT_ETH.balance, vBal - 1 ether);
        assertEq(Z0R0Z_DOT_ETH.balance, zBal + 1 ether);
    }

    error InvalidReceiver();

    function testCommandSendETHFailInvalidReceiver() public payable {
        vm.prank(VITALIK_DOT_ETH);
        vm.expectRevert(InvalidReceiver.selector);
        ie.command{value: 1 ether}("send solady 1 ETH");
    }

    function testCommandSendETHBatch() public payable {
        uint256 vBal = VITALIK_DOT_ETH.balance;
        uint256 zBal = Z0R0Z_DOT_ETH.balance;
        uint256 nBal = DAO.balance;
        vm.prank(VITALIK_DOT_ETH);
        string[] memory intents = new string[](2);
        intents[0] = "send z0r0z 1 ETH";
        intents[1] = "send nani 1 ETH";
        ie.command{value: 2 ether}(intents);
        assertEq(VITALIK_DOT_ETH.balance, vBal - 2 ether);
        assertEq(Z0R0Z_DOT_ETH.balance, zBal + 1 ether);
        assertEq(DAO.balance, nBal + 1 ether);
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

    function testCommandSendUSDC100Percentage() public payable {
        vm.prank(USDC_WHALE);
        IERC20(USDC).approve(address(ie), 100 ether);
        uint256 wBal = IERC20(USDC).balanceOf(USDC_WHALE);
        uint256 zBal = IERC20(USDC).balanceOf(Z0R0Z_DOT_ETH);
        vm.prank(USDC_WHALE);
        ie.command("send z0r0z 100% USDC");
        assertEq(IERC20(USDC).balanceOf(USDC_WHALE), 0);
        assertEq(IERC20(USDC).balanceOf(Z0R0Z_DOT_ETH), zBal + wBal);
    }

    function testCommandSendUSDC50Percentage() public payable {
        vm.prank(USDC_WHALE);
        IERC20(USDC).approve(address(ie), 100 ether);
        uint256 wBal = IERC20(USDC).balanceOf(USDC_WHALE);
        uint256 zBal = IERC20(USDC).balanceOf(Z0R0Z_DOT_ETH);
        vm.prank(USDC_WHALE);
        ie.command("send z0r0z 50% USDC");
        assertEq(IERC20(USDC).balanceOf(USDC_WHALE), (wBal / 2));
        assertEq(IERC20(USDC).balanceOf(Z0R0Z_DOT_ETH), zBal + (wBal / 2));
    }

    function testCommandSendUSDCAll() public payable {
        vm.prank(USDC_WHALE);
        IERC20(USDC).approve(address(ie), 100 ether);
        uint256 wBal = IERC20(USDC).balanceOf(USDC_WHALE);
        uint256 zBal = IERC20(USDC).balanceOf(Z0R0Z_DOT_ETH);
        vm.prank(USDC_WHALE);
        ie.command("send z0r0z all USDC");
        assertEq(IERC20(USDC).balanceOf(USDC_WHALE), 0);
        assertEq(IERC20(USDC).balanceOf(Z0R0Z_DOT_ETH), zBal + wBal);
    }

    function testCommandSendUSDCAllAlt() public payable {
        vm.prank(USDC_WHALE);
        IERC20(USDC).approve(address(ie), 100 ether);
        uint256 wBal = IERC20(USDC).balanceOf(USDC_WHALE);
        uint256 zBal = IERC20(USDC).balanceOf(Z0R0Z_DOT_ETH);
        vm.prank(USDC_WHALE);
        ie.command("send all USDC to z0r0z");
        assertEq(IERC20(USDC).balanceOf(USDC_WHALE), 0);
        assertEq(IERC20(USDC).balanceOf(Z0R0Z_DOT_ETH), zBal + wBal);
    }

    function testSendETH() public payable {
        uint256 vBal = VITALIK_DOT_ETH.balance;
        uint256 zBal = Z0R0Z_DOT_ETH.balance;
        vm.prank(VITALIK_DOT_ETH);
        ie.send{value: 1 ether}("z0r0z", "1", "eth");
        assertEq(VITALIK_DOT_ETH.balance, vBal - 1 ether);
        assertEq(Z0R0Z_DOT_ETH.balance, zBal + 1 ether);
    }

    function testCommandSwapETH() public payable {
        vm.prank(VITALIK_DOT_ETH);
        ie.command{value: 10 ether}("swap 10 eth for 25000 dai"); // note: Price might change in future.
    }

    function testCommandSwapETHExactOut() public payable {
        uint256 balBefore = IERC20(DAI).balanceOf(VITALIK_DOT_ETH);
        vm.prank(VITALIK_DOT_ETH);
        ie.command{value: 10 ether}("swap eth for 25000 dai");
        assertTrue(IERC20(DAI).balanceOf(VITALIK_DOT_ETH) == balBefore + 25000 ether);
    }

    function testCommandSwapWETHExactOutSend() public payable {
        vm.prank(VITALIK_DOT_ETH);
        (bool ok,) = WETH.call{value: 10 ether}("");
        assert(ok);
        vm.prank(VITALIK_DOT_ETH);
        IERC20(WETH).approve(address(ie), type(uint256).max);
        uint256 balBefore = IERC20(DAI).balanceOf(Z0R0Z_DOT_ETH);
        vm.prank(VITALIK_DOT_ETH);
        ie.command("swap weth for 25000 dai for z0r0z");
        assertTrue(IERC20(DAI).balanceOf(Z0R0Z_DOT_ETH) == balBefore + 25000 ether);
    }

    function testCommandSwapETHSendDAINaniDAO() public payable {
        uint256 bal = IERC20(DAI).balanceOf(DAO);
        vm.prank(Z0R0Z_DOT_ETH);
        ie.command{value: 0.000888 ether}("swap 0.000888 eth to dai for nani");
        assertTrue(IERC20(DAI).balanceOf(DAO) > bal);
    }

    function testCommandSwapETHSendDAIExactOutNaniDAO() public payable {
        uint256 bal = IERC20(DAI).balanceOf(DAO);
        vm.prank(Z0R0Z_DOT_ETH);
        ie.command{value: 0.000888 ether}("swap eth to 2.250 dai for nani");
        assertTrue(IERC20(DAI).balanceOf(DAO) > bal);
    }

    function testCommandSwapETHSendDAIMinOutNaniDAO() public payable {
        uint256 bal = IERC20(DAI).balanceOf(DAO);
        vm.prank(Z0R0Z_DOT_ETH);
        ie.command{value: 0.000888 ether}("swap 0.000888 eth to 2.250 dai for nani");
        assertTrue(IERC20(DAI).balanceOf(DAO) > bal);
    }

    function testCommandSwapForETH() public payable {
        uint256 startBalETH = DAI_WHALE.balance;
        uint256 startBalDAI = IERC20(DAI).balanceOf(DAI_WHALE);
        vm.prank(DAI_WHALE);
        IERC20(DAI).approve(address(ie), 100 ether);
        vm.prank(DAI_WHALE);
        ie.command("swap 100 dai for eth");
        assert(startBalETH < DAI_WHALE.balance);
        assertEq(startBalDAI - 100 ether, IERC20(DAI).balanceOf(DAI_WHALE));
    }

    function testCommandSwapDAI() public payable {
        vm.prank(DAI_WHALE);
        IERC20(DAI).approve(address(ie), 100 ether);
        vm.prank(DAI_WHALE);
        ie.command("swap 100 dai for weth");
    }

    function testCommandSwapUSDC() public payable {
        vm.prank(USDC_WHALE);
        IERC20(USDC).approve(address(ie), 100 ether);
        vm.prank(USDC_WHALE);
        ie.command("swap 100 usdc for 0.035 weth");
    }

    function testCommandSwapUSDCForWBTC() public payable {
        uint256 startBalUSDC = IERC20(USDC).balanceOf(USDC_WHALE);
        uint256 startBalWBTC = IERC20(WBTC).balanceOf(USDC_WHALE);
        vm.prank(USDC_WHALE);
        IERC20(USDC).approve(address(ie), 100 ether);
        vm.prank(USDC_WHALE);
        ie.command("swap 100 usdc for wbtc");
        assert(startBalWBTC < IERC20(WBTC).balanceOf(USDC_WHALE));
        assertEq(startBalUSDC - 100 * 10 ** 6, IERC20(USDC).balanceOf(USDC_WHALE));
    }
}

interface IERC20 {
    function approve(address, uint256) external; // unsafe lol.
    function balanceOf(address) external view returns (uint256);
}
