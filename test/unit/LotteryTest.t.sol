//1 Arrange
//2 Act
//3 Assert

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {DeployLottery} from "../../script/DeployLottery.s.sol";
import {Lottery} from "../../src/Lottery.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract LotteryTest is Test {
    event EnteredLottery(address indexed player);

    Lottery lottery;
    HelperConfig helperConfig;

    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint64 subscriptionId;
    uint32 callbackGasLimit;

    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_USER_BALANCE = 10 ether;

    function setUp() external {
        DeployLottery deployer = new DeployLottery();
        (lottery, helperConfig) = deployer.run();
        (
            entranceFee,
            interval,
            vrfCoordinator,
            gasLane,
            subscriptionId,
            callbackGasLimit,

        ) = helperConfig.activeNetworkConfig();
        vm.deal(PLAYER, STARTING_USER_BALANCE);
    }

    /////////////////////
    //* Lottery        //
    /////////////////////

    function testLotteryInitializesInOpenState() public view {
        assert(lottery.getLotteryState() == Lottery.LotteryState.OPEN);
    }

    /////////////////////
    //* enterLottery   //
    /////////////////////

    function testEnterLotteryRevertsWhenYouDontPayEnough() public {
        //1 Arrange
        vm.prank(PLAYER);

        //2 Act / Assert
        vm.expectRevert(Lottery.Lottery__NotEnoughEthSent.selector);
        lottery.enterLottery();
    }

    function testEnterLotteryRecordsPlayersWhenTheyEnter() public {
        //1 Arrange
        vm.prank(PLAYER);

        //2 Act
        lottery.enterLottery{value: entranceFee}();
        address playerRecorded = lottery.getPlayer(0);

        //3 Assert
        assert(playerRecorded == PLAYER);
    }

    function testEnterLotteryEmitsEventOnEntrance() public {
        //1 Arrange
        vm.prank(PLAYER);
        vm.expectEmit(true, false, false, false, address(lottery));

        //2 Act / Assert
        emit EnteredLottery(PLAYER);
        lottery.enterLottery{value: entranceFee}();
    }

    function testCantEnterWhenLotteryIsCalculating() public {
        //1 Arrange
        vm.prank(PLAYER);
        lottery.enterLottery{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        //? Not required but Patrick likes it
        vm.roll(block.number + 1);
        lottery.performUpkeep("");

        //2 Act / Assert
        vm.expectRevert(Lottery.Lottery__LotteryNotOpen.selector);
        vm.prank(PLAYER);
        lottery.enterLottery{value: entranceFee}();
    }

    /////////////////////
    //* checkUpkeep    //
    /////////////////////

    function testCheckUpkeepReturnsFalseIfItHasNoBalance() public {
        //1 Arrange
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        //2 Act
        (bool upkeepNeeded, ) = lottery.checkUpkeep("");

        //3 Assert
        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsFalseIfLotteryNotOpen() public {
        //1 Arrange
        vm.prank(PLAYER);
        lottery.enterLottery{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        lottery.performUpkeep("");

        //2 Act
        (bool upkeepNeeded, ) = lottery.checkUpkeep("");

        //3 Assert
        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsFalseIfEnoughTimeHasntPassed() public {
        //1 Arrange
        vm.prank(PLAYER);
        lottery.enterLottery{value: entranceFee}();
        //2 Act
        (bool upkeepNeeded, ) = lottery.checkUpkeep("");
        //3 Assert
        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsTrueIfAllConditionsAreMet() public {
        //1 Arrange
        vm.prank(PLAYER);
        lottery.enterLottery{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        //2 Act
        (bool upkeepNeeded, ) = lottery.checkUpkeep("");
        //3 Assert
        assert(upkeepNeeded);
    }
}
