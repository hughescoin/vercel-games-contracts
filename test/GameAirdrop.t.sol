// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console2} from "forge-std/Test.sol";
import {GameAirdrop} from "../src/GameAirdrop.sol";
import {MockERC20} from "./mocks/MockERC20.sol";

contract GameAirdropTest is Test {
    GameAirdrop public gameAirdrop;
    MockERC20 public usdc;
    address public owner;
    address public player1;
    address public player2;

    uint256 public constant INITIAL_ETH_ENTRY_FEE = 0.0001 ether;
    uint256 public constant INITIAL_USDC_ENTRY_FEE = 0.1e6; // 0.10 USDC
    uint256 public constant ETH_PAYOUT = 0.0001 ether;
    uint256 public constant USDC_PAYOUT = 1e6; // 1 USDC (6 decimals)
    uint256 public constant INITIAL_FUNDING = 1 ether;
    uint256 public constant INITIAL_USDC_FUNDING = 1000e6; // 1000 USDC

    event GameStarted(address indexed player, bool payWithETH, uint256 amount);
    event EntryFeeUpdated(bool isETH, uint256 oldFee, uint256 newFee);
    event RewardClaimed(address indexed player, bool wasETH, uint256 amount);
    event FundsWithdrawn(address indexed token, uint256 amount);
    event RewardRecorded(address indexed player, uint256 amount, bool isETH);
    event PayoutAmountUpdated(bool isETH, uint256 oldAmount, uint256 newAmount);
    event ContractFunded(address indexed token, uint256 amount);

    function setUp() public {
        owner = makeAddr("owner");
        player1 = makeAddr("player1");
        player2 = makeAddr("player2");

        // Deploy mock USDC
        usdc = new MockERC20("USD Coin", "USDC", 6);
        
        // Deploy GameAirdrop with initial funding
        vm.deal(owner, INITIAL_FUNDING * 2);
        vm.startPrank(owner);
        gameAirdrop = new GameAirdrop{value: INITIAL_FUNDING}(
            INITIAL_ETH_ENTRY_FEE,
            INITIAL_USDC_ENTRY_FEE,
            address(usdc),
            ETH_PAYOUT,
            USDC_PAYOUT
        );
        
        // Fund contract with USDC
        usdc.mint(owner, INITIAL_USDC_FUNDING);
        usdc.approve(address(gameAirdrop), INITIAL_USDC_FUNDING);
        gameAirdrop.fundContractUSDC(INITIAL_USDC_FUNDING);
        vm.stopPrank();

        // Fund players
        vm.deal(player1, 1 ether);
        vm.deal(player2, 1 ether);
        vm.prank(owner);
        usdc.mint(player1, 100e6);
        vm.prank(owner);
        usdc.mint(player2, 100e6);
    }

    function test_Initialization() public {
        assertEq(gameAirdrop.owner(), owner);
        assertEq(gameAirdrop.ethEntryFee(), INITIAL_ETH_ENTRY_FEE);
        assertEq(gameAirdrop.usdcEntryFee(), INITIAL_USDC_ENTRY_FEE);
        assertEq(gameAirdrop.ethPayoutAmount(), ETH_PAYOUT);
        assertEq(gameAirdrop.usdcPayoutAmount(), USDC_PAYOUT);
        assertEq(address(gameAirdrop).balance, INITIAL_FUNDING);
        assertEq(usdc.balanceOf(address(gameAirdrop)), INITIAL_USDC_FUNDING);
    }

    function test_StartGameWithETH() public {
        vm.startPrank(player1);
        vm.expectEmit(true, true, true, true);
        emit GameStarted(player1, true, INITIAL_ETH_ENTRY_FEE);
        gameAirdrop.startGame{value: INITIAL_ETH_ENTRY_FEE}(true);
        assertEq(address(gameAirdrop).balance, INITIAL_FUNDING + INITIAL_ETH_ENTRY_FEE);
        vm.stopPrank();
    }

    function test_StartGameWithUSDC() public {
        vm.startPrank(player1);
        usdc.approve(address(gameAirdrop), INITIAL_USDC_ENTRY_FEE);
        vm.expectEmit(true, true, true, true);
        emit GameStarted(player1, false, INITIAL_USDC_ENTRY_FEE);
        gameAirdrop.startGame(false);
        assertEq(usdc.balanceOf(address(gameAirdrop)), INITIAL_USDC_FUNDING + INITIAL_USDC_ENTRY_FEE);
        vm.stopPrank();
    }

    function test_RecordRewardETH() public {
        vm.startPrank(owner);
        vm.expectEmit(true, true, true, true);
        emit RewardRecorded(player1, ETH_PAYOUT, true);
        gameAirdrop.recordReward(player1, true);
        (uint256 ethReward, uint256 usdcReward) = gameAirdrop.getRewards(player1);
        assertEq(ethReward, ETH_PAYOUT);
        assertEq(usdcReward, 0);
        vm.stopPrank();
    }

    function test_RecordRewardUSDC() public {
        vm.startPrank(owner);
        vm.expectEmit(true, true, true, true);
        emit RewardRecorded(player1, USDC_PAYOUT, false);
        gameAirdrop.recordReward(player1, false);
        (uint256 ethReward, uint256 usdcReward) = gameAirdrop.getRewards(player1);
        assertEq(ethReward, 0);
        assertEq(usdcReward, USDC_PAYOUT);
        vm.stopPrank();
    }

    function test_ClaimRewardETH() public {
        // Record reward first
        vm.prank(owner);
        gameAirdrop.recordReward(player1, true);

        // Claim reward
        vm.startPrank(player1);
        uint256 balanceBefore = player1.balance;
        vm.expectEmit(true, true, true, true);
        emit RewardClaimed(player1, true, ETH_PAYOUT);
        gameAirdrop.claimReward(true);
        assertEq(player1.balance - balanceBefore, ETH_PAYOUT);
        (uint256 ethReward, uint256 usdcReward) = gameAirdrop.getRewards(player1);
        assertEq(ethReward, 0);
        assertEq(usdcReward, 0);
        vm.stopPrank();
    }

    function test_ClaimRewardUSDC() public {
        // Record reward first
        vm.prank(owner);
        gameAirdrop.recordReward(player1, false);

        // Claim reward
        vm.startPrank(player1);
        uint256 balanceBefore = usdc.balanceOf(player1);
        vm.expectEmit(true, true, true, true);
        emit RewardClaimed(player1, false, USDC_PAYOUT);
        gameAirdrop.claimReward(false);
        assertEq(usdc.balanceOf(player1) - balanceBefore, USDC_PAYOUT);
        (uint256 ethReward, uint256 usdcReward) = gameAirdrop.getRewards(player1);
        assertEq(ethReward, 0);
        assertEq(usdcReward, 0);
        vm.stopPrank();
    }

    function test_SetEntryFee() public {
        uint256 newEthFee = 0.0002 ether;
        uint256 newUsdcFee = 0.25e6;

        vm.startPrank(owner);
        
        // Update ETH fee
        vm.expectEmit(true, true, true, true);
        emit EntryFeeUpdated(true, INITIAL_ETH_ENTRY_FEE, newEthFee);
        gameAirdrop.setEntryFee(true, newEthFee);
        assertEq(gameAirdrop.ethEntryFee(), newEthFee);

        // Update USDC fee
        vm.expectEmit(true, true, true, true);
        emit EntryFeeUpdated(false, INITIAL_USDC_ENTRY_FEE, newUsdcFee);
        gameAirdrop.setEntryFee(false, newUsdcFee);
        assertEq(gameAirdrop.usdcEntryFee(), newUsdcFee);
        
        vm.stopPrank();
    }

    function test_SetPayoutAmounts() public {
        uint256 newEthPayout = 0.0002 ether;
        uint256 newUsdcPayout = 2e6;

        vm.startPrank(owner);
        vm.expectEmit(true, true, true, true);
        emit PayoutAmountUpdated(true, ETH_PAYOUT, newEthPayout);
        gameAirdrop.setEthPayoutAmount(newEthPayout);
        assertEq(gameAirdrop.ethPayoutAmount(), newEthPayout);

        vm.expectEmit(true, true, true, true);
        emit PayoutAmountUpdated(false, USDC_PAYOUT, newUsdcPayout);
        gameAirdrop.setUsdcPayoutAmount(newUsdcPayout);
        assertEq(gameAirdrop.usdcPayoutAmount(), newUsdcPayout);
        vm.stopPrank();
    }

    function test_FundContract() public {
        uint256 fundingAmount = 0.5 ether;
        vm.startPrank(owner);
        vm.expectEmit(true, true, true, true);
        emit ContractFunded(address(0), fundingAmount);
        gameAirdrop.fundContract{value: fundingAmount}();
        assertEq(address(gameAirdrop).balance, INITIAL_FUNDING + fundingAmount);
        vm.stopPrank();
    }

    function test_FundContractUSDC() public {
        uint256 fundingAmount = 500e6;
        vm.startPrank(owner);
        usdc.mint(owner, fundingAmount);
        usdc.approve(address(gameAirdrop), fundingAmount);
        vm.expectEmit(true, true, true, true);
        emit ContractFunded(address(usdc), fundingAmount);
        gameAirdrop.fundContractUSDC(fundingAmount);
        assertEq(usdc.balanceOf(address(gameAirdrop)), INITIAL_USDC_FUNDING + fundingAmount);
        vm.stopPrank();
    }

    function test_WithdrawFunds() public {
        uint256 withdrawAmount = 0.5 ether;
        vm.startPrank(owner);
        vm.expectEmit(true, true, true, true);
        emit FundsWithdrawn(address(0), withdrawAmount);
        gameAirdrop.withdrawFunds(address(0), withdrawAmount);
        assertEq(address(gameAirdrop).balance, INITIAL_FUNDING - withdrawAmount);
        vm.stopPrank();
    }

    function test_WithdrawFundsUSDC() public {
        uint256 withdrawAmount = 500e6;
        vm.startPrank(owner);
        vm.expectEmit(true, true, true, true);
        emit FundsWithdrawn(address(usdc), withdrawAmount);
        gameAirdrop.withdrawFunds(address(usdc), withdrawAmount);
        assertEq(usdc.balanceOf(address(gameAirdrop)), INITIAL_USDC_FUNDING - withdrawAmount);
        vm.stopPrank();
    }

    function testFail_StartGameWithInsufficientETH() public {
        vm.startPrank(player1);
        gameAirdrop.startGame{value: INITIAL_ETH_ENTRY_FEE - 1}(true);
        vm.stopPrank();
    }

    function testFail_StartGameWithInsufficientUSDC() public {
        vm.startPrank(player1);
        usdc.approve(address(gameAirdrop), INITIAL_USDC_ENTRY_FEE - 1);
        gameAirdrop.startGame(false);
        vm.stopPrank();
    }

    function testFail_RecordRewardWithInsufficientBalance() public {
        vm.startPrank(owner);
        gameAirdrop.withdrawFunds(address(0), INITIAL_FUNDING);
        gameAirdrop.recordReward(player1, true);
        vm.stopPrank();
    }

    function testFail_ClaimRewardWithNoRewards() public {
        vm.startPrank(player1);
        gameAirdrop.claimReward(true);
        vm.stopPrank();
    }

    function testFail_NonOwnerSetEntryFee() public {
        vm.startPrank(player1);
        gameAirdrop.setEntryFee(true, 0.0002 ether);
        vm.stopPrank();
    }

    function testFail_NonOwnerWithdrawFunds() public {
        vm.startPrank(player1);
        gameAirdrop.withdrawFunds(address(0), 0.5 ether);
        vm.stopPrank();
    }

    function test_CompleteFlow_FundAndClaim() public {
        // 1. Fund the contract with additional ETH
        uint256 fundingAmount = 0.5 ether;
        vm.startPrank(owner);
        gameAirdrop.fundContract{value: fundingAmount}();
        assertEq(address(gameAirdrop).balance, INITIAL_FUNDING + fundingAmount);
        vm.stopPrank();

        // 2. Record a reward for player1
        vm.prank(owner);
        gameAirdrop.recordReward(player1, true);

        // 3. Player1 claims their reward
        vm.startPrank(player1);
        uint256 balanceBefore = player1.balance;
        gameAirdrop.claimReward(true);
        assertEq(player1.balance - balanceBefore, ETH_PAYOUT);
        vm.stopPrank();

        // 4. Verify the contract balance decreased
        assertEq(address(gameAirdrop).balance, INITIAL_FUNDING + fundingAmount - ETH_PAYOUT);
    }

    function test_TransferOwnership() public {
        address newOwner = makeAddr("newOwner");
        
        // Transfer ownership
        vm.startPrank(owner);
        gameAirdrop.transferOwnership(newOwner);
        assertEq(gameAirdrop.owner(), newOwner);
        vm.stopPrank();

        // Verify old owner can't call owner functions
        vm.startPrank(owner);
        vm.expectRevert(abi.encodeWithSelector(GameAirdrop.OnlyOwner.selector));
        gameAirdrop.setEntryFee(true, 0.0002 ether);
        vm.stopPrank();

        // Verify new owner can call owner functions
        vm.startPrank(newOwner);
        gameAirdrop.setEntryFee(true, 0.0002 ether);
        assertEq(gameAirdrop.ethEntryFee(), 0.0002 ether);
        vm.stopPrank();
    }

    function test_TransferOwnershipToZeroAddress() public {
        vm.startPrank(owner);
        vm.expectRevert(bytes("Invalid new owner"));
        gameAirdrop.transferOwnership(address(0));
        vm.stopPrank();
    }

    function test_NonOwnerTransferOwnership() public {
        address newOwner = makeAddr("newOwner");
        vm.startPrank(player1);
        vm.expectRevert(abi.encodeWithSelector(GameAirdrop.OnlyOwner.selector));
        gameAirdrop.transferOwnership(newOwner);
        vm.stopPrank();
    }
} 