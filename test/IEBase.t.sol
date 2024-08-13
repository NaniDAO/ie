// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {IEBase} from "../src/IEBase.sol";
import {Test} from "../lib/forge-std/src/Test.sol";

contract IEBaseTest is Test {
    address internal constant DAO = 0xDa000000000000d2885F108500803dfBAaB2f2aA;
    address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address internal constant WETH = 0x4200000000000000000000000000000000000006;
    address internal constant TBTC = 0x236aa50979D5f3De3Bd1Eeb40E81137F22ab794b;
    address internal constant USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
    address internal constant USDT = 0xfde4C96c8593536E31F229EA8f37b2ADa2699bb2;
    address internal constant DAI = 0x50c5725949A6F0c72E6C4a641F24049A917DB0Cb;
    address internal constant CBETH = 0x2Ae3F1Ec7F1F5012CFEab0185bfc7aa3cf0DEc22;
    address internal constant WSTETH = 0xc1CBa3fCea344f92D9239c08C0568f6F2F0ee452;

    address internal constant CRV = 0x8Ee73c484A26e0A5df2Ee2a4960B789967dd0415;

    address internal constant SHIVANSHI_DOT_ETH = 0xCB0592589602B841BE035e1e64C2A5b1Ef006aa2;
    address internal constant CATTIN_DOT_ETH = 0xA9D2BCF3AcB743340CdB1D858E529A23Cef37838;
    address internal constant Z0R0Z_DOT_ETH = 0x1C0Aa8cCD568d90d61659F060D1bFb1e6f855A20;
    address internal constant NANI_DOT_ETH = 0x7AF890Ca7262D6accdA5c9D24AC42e35Bb293188;

    address internal constant ENTRY_POINT = 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789;

    address internal constant USDC_WHALE = 0x0B0A5886664376F59C351ba3f598C8A8B4D0A6f3;
    address internal constant DAI_WHALE = 0x6bcF3Fb49B493a74b1771DcEccc4c470f372d496;

    IEBase internal ie; // Intents Engine on Base.

    function setUp() public payable {
        vm.createSelectFork(vm.rpcUrl("base")); // Base fork.
        ie = new IEBase();
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
        ie.setName(USDT, "USDT");
        vm.prank(DAO);
        ie.setName(USDT, "tether");
        ie.setName(CRV);
    }

    function testDeploy() public payable {
        new IEBase();
    }

    function testPreviewSendCommandRawAddr() public payable {
        string memory command = "send 0x1C0Aa8cCD568d90d61659F060D1bFb1e6f855A20 20 dai";
        (address to, uint256 amount,, address asset,,) = ie.previewCommand(command);
        assertEq(to, Z0R0Z_DOT_ETH);
        assertEq(amount, 20 ether);
        assertEq(asset, DAI);
    }

    function testPreviewSendAllCommandRawAddr() public payable {
        string memory command = "send 0x1C0Aa8cCD568d90d61659F060D1bFb1e6f855A20 all dai";
        vm.prank(Z0R0Z_DOT_ETH);
        (address to, uint256 amount,, address asset,,) = ie.previewCommand(command);
        assertEq(to, Z0R0Z_DOT_ETH);
        assertEq(amount, 1 ether);
        assertEq(asset, DAI);

        command = "send all dai to 0x1C0Aa8cCD568d90d61659F060D1bFb1e6f855A20";
        vm.prank(Z0R0Z_DOT_ETH);
        (to, amount,, asset,,) = ie.previewCommand(command);
        assertEq(to, Z0R0Z_DOT_ETH);
        assertEq(amount, 1 ether);
        assertEq(asset, DAI);
    }

    function testPreviewCommandSendUSDC() public payable {
        string memory command = "send 0x1C0Aa8cCD568d90d61659F060D1bFb1e6f855A20 20 usdc";
        (address to, uint256 amount,, address asset,,) = ie.previewCommand(command);
        assertEq(to, Z0R0Z_DOT_ETH);
        assertEq(amount, 20000000);
        assertEq(asset, USDC);
    }

    function testPreviewCommandSendDecimals() public payable {
        string memory command = "send 0x1C0Aa8cCD568d90d61659F060D1bFb1e6f855A20 20.2 dai";
        (address to, uint256 amount,, address asset,,) = ie.previewCommand(command);
        assertEq(to, Z0R0Z_DOT_ETH);
        assertEq(amount, 20.2 ether);
        assertEq(asset, DAI);
        command = "send 0x1C0Aa8cCD568d90d61659F060D1bFb1e6f855A20 20.23345 eth";
        (to, amount,, asset,,) = ie.previewCommand(command);
        assertEq(to, Z0R0Z_DOT_ETH);
        assertEq(amount, 20.23345 ether);
        assertEq(asset, ETH);
    }

    function testTokenNameSetting() public payable {
        assertEq(ie.addresses("usdc"), USDC);
    }

    function testCommandSendETHRawAddr() public payable {
        ie.command{value: 1 ether}("send 0x1C0Aa8cCD568d90d61659F060D1bFb1e6f855A20 1 ETH");
    }

    function testCommandSendDAIRawAddr() public payable {
        vm.prank(Z0R0Z_DOT_ETH);
        IERC20(DAI).approve(address(ie), 1 ether);
        vm.prank(Z0R0Z_DOT_ETH);
        ie.command("send 0x999657A41753b8E69C66e7b1A8E37d513CB44E1C 1 DAI");
    }

    function testCommandSendUSDCRawAddr() public payable {
        assertEq(IERC20(USDC).balanceOf(Z0R0Z_DOT_ETH), 10 ** 6);
        vm.prank(Z0R0Z_DOT_ETH);
        IERC20(USDC).approve(address(ie), 10 ** 6);
        vm.prank(Z0R0Z_DOT_ETH);
        ie.command("send 0x999657A41753b8E69C66e7b1A8E37d513CB44E1C 1 USDC");
        assertEq(IERC20(USDC).balanceOf(Z0R0Z_DOT_ETH), 0);
    }

    function testCommandSendUSDCRawAddr100Percent() public payable {
        assertEq(IERC20(USDC).balanceOf(Z0R0Z_DOT_ETH), 10 ** 6);
        vm.prank(Z0R0Z_DOT_ETH);
        IERC20(USDC).approve(address(ie), 10 ** 6);
        vm.prank(Z0R0Z_DOT_ETH);
        ie.command("send 0x999657A41753b8E69C66e7b1A8E37d513CB44E1C 100% USDC");
        assertEq(IERC20(USDC).balanceOf(Z0R0Z_DOT_ETH), 0);
    }

    function testCommandSendUSDCRawAddr50Percent() public payable {
        assertEq(IERC20(USDC).balanceOf(Z0R0Z_DOT_ETH), 10 ** 6);
        vm.prank(Z0R0Z_DOT_ETH);
        IERC20(USDC).approve(address(ie), 10 ** 6);
        vm.prank(Z0R0Z_DOT_ETH);
        ie.command("send 0x999657A41753b8E69C66e7b1A8E37d513CB44E1C 50% USDC");
        assertEq(IERC20(USDC).balanceOf(Z0R0Z_DOT_ETH), 10 ** 6 / 2);
    }

    function testCommandSendDAIRawAddr100Percent() public payable {
        assertEq(IERC20(DAI).balanceOf(Z0R0Z_DOT_ETH), 1 ether);
        vm.prank(Z0R0Z_DOT_ETH);
        IERC20(DAI).approve(address(ie), 1 ether);
        vm.prank(Z0R0Z_DOT_ETH);
        ie.command("send 0x999657A41753b8E69C66e7b1A8E37d513CB44E1C 100% DAI");
        assertEq(IERC20(DAI).balanceOf(Z0R0Z_DOT_ETH), 0);
    }

    function testCommandSendDAIRawAddr5Percent() public payable {
        assertEq(IERC20(DAI).balanceOf(Z0R0Z_DOT_ETH), 1 ether);
        vm.prank(Z0R0Z_DOT_ETH);
        IERC20(DAI).approve(address(ie), 1 ether);
        vm.prank(Z0R0Z_DOT_ETH);
        ie.command("send 0x999657A41753b8E69C66e7b1A8E37d513CB44E1C 5% DAI");
        assertEq(IERC20(DAI).balanceOf(Z0R0Z_DOT_ETH), 0.95 ether);
    }

    function testCommandSendETHRawAddr100Percent() public payable {
        uint256 initBal = address(this).balance;
        assertTrue(initBal != 0);
        address recipient = 0x1C0Aa8cCD568d90d61659F060D1bFb1e6f855A20;
        uint256 initialRecvBal = recipient.balance;
        ie.command{value: initBal}("send 0x1C0Aa8cCD568d90d61659F060D1bFb1e6f855A20 100% ETH");
        assertTrue(address(this).balance == 0);
        assertEq(recipient.balance, initialRecvBal + initBal);
    }

    function testFailCommandSendETHRawAddr1000Percent() public payable {
        uint256 initBal = address(this).balance;
        assertTrue(initBal != 0);
        ie.command{value: initBal}("send 0x1C0Aa8cCD568d90d61659F060D1bFb1e6f855A20 1000% ETH");
    }

    function testCommandSendETHRawAddr50Percent() public payable {
        uint256 half = address(this).balance / 2;
        assertTrue(half != 0);

        address recipient = 0x1C0Aa8cCD568d90d61659F060D1bFb1e6f855A20;
        uint256 initialRecvBal = recipient.balance;

        ie.command{value: half}("send 0x1C0Aa8cCD568d90d61659F060D1bFb1e6f855A20 50% ETH");

        assertEq(recipient.balance, initialRecvBal + half);
    }

    function testCommandSendETHRawAddr51PointOnePercent() public payable {
        uint256 bal = address(this).balance;
        uint256 result = (bal * 511) / 1000;

        address recipient = 0x1C0Aa8cCD568d90d61659F060D1bFb1e6f855A20;
        uint256 initialRecvBal = recipient.balance;

        ie.command{value: result}("send 0x1C0Aa8cCD568d90d61659F060D1bFb1e6f855A20 51.1% ETH");

        assertEq(recipient.balance, initialRecvBal + result);
    }

    function testCommandSendETHRawAddr20PointOnePercent() public payable {
        uint256 bal = address(this).balance;
        uint256 result = (bal * 201) / 1000;

        address recipient = 0x1C0Aa8cCD568d90d61659F060D1bFb1e6f855A20;
        uint256 initialRecvBal = recipient.balance;

        ie.command{value: result}("send 0x1C0Aa8cCD568d90d61659F060D1bFb1e6f855A20 20.1% ETH");

        assertEq(recipient.balance, initialRecvBal + result);
    }

    function testCommandSendETHRawAddrPrecisePercent() public payable {
        uint256 bal = address(this).balance;
        uint256 result = (bal * 200001) / 1000000;

        address recipient = 0x1C0Aa8cCD568d90d61659F060D1bFb1e6f855A20;
        uint256 initialRecvBal = recipient.balance;

        ie.command{value: result}("send 0x1C0Aa8cCD568d90d61659F060D1bFb1e6f855A20 20.0001% ETH");

        assertEq(recipient.balance, initialRecvBal + result);
    }

    function testCommandSwapETH() public payable {
        vm.prank(ENTRY_POINT); // Note: price might change in the future.
        ie.command{value: 1 ether}("swap 1 eth for 2200 dai");
    }

    function testCommandSwapAllETH() public payable {
        uint256 bal = ENTRY_POINT.balance;
        vm.prank(ENTRY_POINT);
        ie.command{value: bal}("swap all eth for dai");
    }

    function testCommandSwapAllETHSend() public payable {
        uint256 bal = ENTRY_POINT.balance;
        vm.prank(ENTRY_POINT);
        ie.command{value: bal}(
            "swap all eth for dai for 0x999657A41753b8E69C66e7b1A8E37d513CB44E1C"
        );
        assertTrue(ENTRY_POINT.balance == 0);
    }

    function testCommandStakeETH() public payable {
        vm.prank(ENTRY_POINT);
        ie.command{value: 1 ether}("stake 1 eth into lido");
    }

    function testCommandSwapETHUnlistedToken() public payable {
        uint256 balBefore = IERC20(CRV).balanceOf(ENTRY_POINT);
        vm.prank(ENTRY_POINT);
        ie.command{value: 1 ether}("swap 1 eth for crv");
        assertTrue(IERC20(CRV).balanceOf(ENTRY_POINT) > balBefore);
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

    function testCommandSwapDAIExactOut() public payable {
        vm.prank(DAI_WHALE);
        IERC20(DAI).approve(address(ie), 10000 ether);
        vm.prank(DAI_WHALE);
        ie.command("swap dai for 1 weth");
    }

    function testCommandSwapDAIExactOutSendWETH() public payable {
        uint256 balBefore = IERC20(WETH).balanceOf(0x999657A41753b8E69C66e7b1A8E37d513CB44E1C);
        vm.prank(DAI_WHALE);
        IERC20(DAI).approve(address(ie), 10000 ether);
        vm.prank(DAI_WHALE);
        ie.command("swap dai for 1 weth for 0x999657A41753b8E69C66e7b1A8E37d513CB44E1C");
        assertEq(
            IERC20(WETH).balanceOf(0x999657A41753b8E69C66e7b1A8E37d513CB44E1C), balBefore + 1 ether
        );
    }

    function testCommandSwapDAIExactOutSendETH() public payable {
        uint256 balBefore = 0x999657A41753b8E69C66e7b1A8E37d513CB44E1C.balance;
        vm.prank(DAI_WHALE);
        IERC20(DAI).approve(address(ie), 10000 ether);
        vm.prank(DAI_WHALE);
        ie.command("swap dai for 1 eth for 0x999657A41753b8E69C66e7b1A8E37d513CB44E1C");
        assertEq(0x999657A41753b8E69C66e7b1A8E37d513CB44E1C.balance, balBefore + 1 ether);
    }

    function testCommandSwapDAIPercentageExactOutSendUSDC() public payable {
        vm.prank(DAI_WHALE);
        IERC20(DAI).approve(address(ie), 100000000000 ether);
        vm.prank(DAI_WHALE);
        ie.command("swap 10% dai for usdc for 0x999657A41753b8E69C66e7b1A8E37d513CB44E1C");
    }

    function testCommandSwapDAIMinOut() public payable {
        vm.prank(DAI_WHALE);
        IERC20(DAI).approve(address(ie), 10000 ether);
        vm.prank(DAI_WHALE);
        ie.command("swap 4000 dai for 1 weth");
    }

    function testCommandSwapDAIMinOutPercentage() public payable {
        vm.prank(DAI_WHALE);
        IERC20(DAI).approve(address(ie), 100000000 ether);
        vm.prank(DAI_WHALE);
        ie.command("swap 100% dai for 1 weth");
    }

    function testCommandSwapDAIMinOutAll() public payable {
        vm.prank(DAI_WHALE);
        IERC20(DAI).approve(address(ie), 100000000 ether);
        vm.prank(DAI_WHALE);
        ie.command("swap all dai for 1 weth");
    }

    function testCommandSwapDAI100Percent() public payable {
        assertEq(IERC20(DAI).balanceOf(Z0R0Z_DOT_ETH), 1 ether);
        vm.prank(Z0R0Z_DOT_ETH);
        IERC20(DAI).approve(address(ie), 1 ether);
        vm.prank(Z0R0Z_DOT_ETH);
        ie.command("swap 100% dai for weth");
        assertEq(IERC20(DAI).balanceOf(Z0R0Z_DOT_ETH), 0);
    }

    function testCommandSwapDAI50Percent() public payable {
        assertEq(IERC20(DAI).balanceOf(Z0R0Z_DOT_ETH), 1 ether);
        vm.prank(Z0R0Z_DOT_ETH);
        IERC20(DAI).approve(address(ie), 1 ether);
        vm.prank(Z0R0Z_DOT_ETH);
        ie.command("swap 50% dai for weth");
        assertEq(IERC20(DAI).balanceOf(Z0R0Z_DOT_ETH), 0.5 ether);
    }

    function testCommandSwapUSDC50Percent() public payable {
        assertEq(IERC20(USDC).balanceOf(Z0R0Z_DOT_ETH), 10 ** 6);
        vm.prank(Z0R0Z_DOT_ETH);
        IERC20(USDC).approve(address(ie), 10 ** 6);
        vm.prank(Z0R0Z_DOT_ETH);
        ie.command("swap 50% usdc for weth");
        assertEq(IERC20(USDC).balanceOf(Z0R0Z_DOT_ETH), 10 ** 6 / 2);
    }

    function testCommandSwapUSDC() public payable {
        vm.prank(USDC_WHALE);
        IERC20(USDC).approve(address(ie), 100 ether);
        vm.prank(USDC_WHALE);
        ie.command("swap 100 usdc for 0.025 weth");
    }

    function testCommandSwapETHForTBTC() public payable {
        vm.prank(ENTRY_POINT);
        ie.command{value: 1 ether}("swap 1 eth for tbtc");
    }

    function testTranslateCommand() public payable {
        string memory intent = "send z0r0z 1 usdc";
        string memory ret = ie.translateCommand(abi.encodePacked(IIE.command.selector, intent));
        assertEq(ret, intent);
    }

    function testTranslateExecuteSend1ETH() public payable {
        string memory intent = "send 1 ETH to 0x1c0aa8ccd568d90d61659f060d1bfb1e6f855a20";
        bytes4 sig = IExecutor.execute.selector;
        bytes memory execData = abi.encode(Z0R0Z_DOT_ETH, 1 ether, "");
        execData = abi.encodePacked(sig, execData);
        string memory ret = ie.translateExecute(execData);
        assertEq(ret, intent);
    }

    function testTranslateExecuteSend0_1ETH() public payable {
        string memory intent = "send 0.1 ETH to 0x1c0aa8ccd568d90d61659f060d1bfb1e6f855a20";
        bytes4 sig = IExecutor.execute.selector;
        bytes memory execData = abi.encode(Z0R0Z_DOT_ETH, 100000000000000000, "");
        execData = abi.encodePacked(sig, execData);
        string memory ret = ie.translateExecute(execData);
        assertEq(ret, intent);
    }

    function testTranslateExecuteSend0_0_1ETH() public payable {
        string memory intent = "send 0.01 ETH to 0x1c0aa8ccd568d90d61659f060d1bfb1e6f855a20";
        bytes4 sig = IExecutor.execute.selector;
        bytes memory execData = abi.encode(Z0R0Z_DOT_ETH, 10000000000000000, "");
        execData = abi.encodePacked(sig, execData);
        string memory ret = ie.translateExecute(execData);
        assertEq(ret, intent);
    }

    function testTranslateExecuteSend1Wei() public payable {
        string memory intent =
            "send 0.000000000000000001 ETH to 0x1c0aa8ccd568d90d61659f060d1bfb1e6f855a20";
        bytes4 sig = IExecutor.execute.selector;
        bytes memory execData = abi.encode(Z0R0Z_DOT_ETH, 1, "");
        execData = abi.encodePacked(sig, execData);
        string memory ret = ie.translateExecute(execData);
        assertEq(ret, intent);
    }

    function testTranslateExecuteSend10USDC() public payable {
        string memory intent = "send 10 USDC to 0x1c0aa8ccd568d90d61659f060d1bfb1e6f855a20";
        bytes memory execData = abi.encodeWithSelector(
            IExecutor.execute.selector,
            USDC,
            0,
            abi.encodeWithSelector(IERC20.transfer.selector, Z0R0Z_DOT_ETH, 10000000)
        );
        string memory ret = ie.translateExecute(execData);
        assertEq(ret, intent);
    }
}

interface IERC20 {
    function approve(address, uint256) external; // unsafe lol.
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
}

interface IExecutor {
    function execute(address, uint256, bytes calldata) external payable returns (bytes memory);
}

interface IIE {
    function command(string calldata) external;
}
