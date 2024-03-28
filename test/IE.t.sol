// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {IE} from "../src/IE.sol";
import {Test} from "../lib/forge-std/src/Test.sol";

contract IETest is Test {
    address internal constant DAO = 0xDa000000000000d2885F108500803dfBAaB2f2aA;

    address internal constant NANI = 0x00000000000025824328358250920B271f348690;
    address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address internal constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address internal constant WBTC = 0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f;
    address internal constant USDC = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;
    address internal constant USDT = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;
    address internal constant DAI = 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1;
    address internal constant ARB = 0x912CE59144191C1204E64559FE8253a0e49E6548;
    address internal constant WSTETH = 0x5979D7b546E38E414F7E9822514be443A4800529;
    address internal constant RETH = 0xEC70Dcb4A1EFa46b8F2D97C310C9c4790ba5ffA8;

    address internal constant VITALIK_DOT_ETH = 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045;
    address internal constant Z0R0Z_DOT_ETH = 0x1C0Aa8cCD568d90d61659F060D1bFb1e6f855A20;
    address internal constant NANI_DOT_ETH = 0x7AF890Ca7262D6accdA5c9D24AC42e35Bb293188;

    address internal constant USDC_WHALE = 0x62383739D68Dd0F844103Db8dFb05a7EdED5BBE6;
    address internal constant DAI_WHALE = 0x2d070ed1321871841245D8EE5B84bD2712644322;

    bytes internal constant ASCII_MAP =
        hex"2d00020101000a010700016101620163016401650166016701680169016a016b016c016d016e016f0170017101720173017401750176017701780179017a06001a010500";

    IE internal ie; // Intents Engine.

    function setUp() public payable {
        vm.createSelectFork(vm.rpcUrl("arbi")); // Arbitrum fork.
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
        ie.setName(USDT, "USDT");
        vm.prank(DAO);
        ie.setName(USDT, "tether");
    }

    function testDeploy() public payable {
        new IE();
    }

    function testENSNameOwnership() public payable {
        (, address receiver,) = ie.whatIsTheAddressOf("z0r0z");
        assertEq(receiver, Z0R0Z_DOT_ETH);
    }

    function testPreviewSendCommand() public payable {
        string memory command = "send z0r0z 20 dai";
        (address to, uint256 amount,, address asset,,) = ie.previewCommand(command);
        assertEq(to, Z0R0Z_DOT_ETH);
        assertEq(amount, 20 ether);
        assertEq(asset, DAI);
    }

    function testPreviewSendCommandRawAddr() public payable {
        string memory command = "send 0x1C0Aa8cCD568d90d61659F060D1bFb1e6f855A20 20 dai";
        (address to, uint256 amount,, address asset,,) = ie.previewCommand(command);
        assertEq(to, Z0R0Z_DOT_ETH);
        assertEq(amount, 20 ether);
        assertEq(asset, DAI);
    }

    function testPreviewSend() public payable {
        (address to, uint256 amount, address asset,,) = ie.previewSend("z0r0z", "20", "dai");
        assertEq(to, Z0R0Z_DOT_ETH);
        assertEq(amount, 20 ether);
        assertEq(asset, DAI);
    }

    function testPreviewSendRawAddr() public payable {
        (address to, uint256 amount, address asset,,) =
            ie.previewSend("0x1C0Aa8cCD568d90d61659F060D1bFb1e6f855A20", "20", "dai");
        assertEq(to, Z0R0Z_DOT_ETH);
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
        string memory command = "send z0r0z 20.2 dai";
        (address to, uint256 amount,, address asset,,) = ie.previewCommand(command);
        assertEq(to, Z0R0Z_DOT_ETH);
        assertEq(amount, 20.2 ether);
        assertEq(asset, DAI);
        command = "send z0r0z 20.23345 eth";
        (to, amount,, asset,,) = ie.previewCommand(command);
        assertEq(to, Z0R0Z_DOT_ETH);
        assertEq(amount, 20.23345 ether);
        assertEq(asset, ETH);
    }

    function testIENameSetting() public payable {
        assertEq(ie.tokens("usdc"), USDC);
    }

    function testCommandSendETH() public payable {
        ie.command{value: 1 ether}("send z0r0z 1 ETH");
    }

    function testCommandSendETHRawAddr() public payable {
        ie.command{value: 1 ether}("send 0x1C0Aa8cCD568d90d61659F060D1bFb1e6f855A20 1 ETH");
    }

    function testCommandSwapETH() public payable {
        vm.prank(VITALIK_DOT_ETH); // Note: price might change in the future.
        ie.command{value: 1 ether}("swap 1 eth for 2800 dai");
    }

    function testCommandStakeETH() public payable {
        vm.prank(VITALIK_DOT_ETH);
        ie.command{value: 1 ether}("stake 1 eth into lido");
    }

    function testCommandDepositETH() public payable {
        vm.prank(VITALIK_DOT_ETH);
        ie.command{value: 1 ether}("deposit 1 eth into reth");
    }

    function testCommandWithdrawETH() public payable {
        vm.prank(VITALIK_DOT_ETH);
        ie.command{value: 1 ether}("deposit 1 eth into reth");
        vm.prank(VITALIK_DOT_ETH);
        IERC20(RETH).approve(address(ie), 100 ether);
        vm.prank(VITALIK_DOT_ETH);
        ie.command("withdraw 0.8 reth into eth");
    }

    function testCommandUnstakeETH() public payable {
        vm.prank(VITALIK_DOT_ETH);
        ie.command{value: 1 ether}("stake 1 eth into reth");
        vm.prank(VITALIK_DOT_ETH);
        IERC20(RETH).approve(address(ie), 100 ether);
        vm.prank(VITALIK_DOT_ETH);
        ie.command("unstake 0.8 reth for eth");
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
        ie.command("swap 100 usdc for 0.025 weth");
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
