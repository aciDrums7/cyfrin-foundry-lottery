//1 Arrange
//2 Act
//3 Assert

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {DeployLottery} from "../../script/DeployLottery.s.sol";
import {Lottery} from "../../src/Lottery.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

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

    modifier lotteryEntered() {
        vm.prank(PLAYER);
        lottery.enterLottery{value: entranceFee}();
        _;
    }

    modifier timePassed() {
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _;
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

    function testEnterLotteryRecordsPlayersWhenTheyEnter()
        public
        /*1 Arrange */ lotteryEntered
    {
        //2 Act
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

    function testCantEnterWhenLotteryIsCalculating()
        public
        /*1 Arrange */ lotteryEntered
        timePassed
    {
        //1 Arrange
        lottery.performUpkeep("");

        //2 Act / Assert
        vm.expectRevert(Lottery.Lottery__LotteryNotOpen.selector);
        vm.prank(PLAYER);
        lottery.enterLottery{value: entranceFee}();
    }

    /////////////////////
    //* checkUpkeep    //
    /////////////////////

    function testCheckUpkeepReturnsFalseIfItHasNoBalance()
        public
        /*1 Arrange */ timePassed
    {
        //2 Act
        (bool upkeepNeeded, ) = lottery.checkUpkeep("");

        //3 Assert
        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsFalseIfLotteryNotOpen()
        public
        /*1 Arrange */ lotteryEntered
        timePassed
    {
        //1 Arrange
        lottery.performUpkeep("");

        //2 Act
        (bool upkeepNeeded, ) = lottery.checkUpkeep("");

        //3 Assert
        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsFalseIfEnoughTimeHasntPassed()
        public
        /*1 Arrange */ lotteryEntered
    {
        //2 Act
        (bool upkeepNeeded, ) = lottery.checkUpkeep("");
        //3 Assert
        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsTrueIfAllConditionsAreMet()
        public
        /*1 Arrange */ lotteryEntered
        timePassed
    {
        //2 Act
        (bool upkeepNeeded, ) = lottery.checkUpkeep("");
        //3 Assert
        assert(upkeepNeeded);
    }

    /////////////////////
    //* performUpkeep  //
    /////////////////////

    function testPerformUpkeepCanOnlyRunIfCheckUpkeepIsTrue()
        public
        /*1 Arrange */ lotteryEntered
        timePassed
    {
        //2 Act / Assert
        lottery.performUpkeep("");
        //? Since there isn't a expectNotRevert() function, if we run performUpkeep
        //? and it goes through without reverting, the test is successful
    }

    function testPerformUpkeepRevertsIfCheckUpkeepIsFalse() public {
        //1 Arrange
        uint256 currentBalance = 0;
        uint256 numPlayers = 0;
        Lottery.LotteryState lotteryState = Lottery.LotteryState.OPEN;

        //2 Act / Assert
        vm.expectRevert(
            abi.encodeWithSelector(
                Lottery.Lottery_UpkeepNotNeeded.selector,
                currentBalance,
                numPlayers,
                lotteryState
            )
        );
        lottery.performUpkeep("");
    }

    //? What if I need to test using the output of an event?
    function testPerformUpkeepUpdatesLotteryStateAndEmitsRequestId()
        public
        /*1 Arrange */ lotteryEntered
        timePassed
    {
        //2 Act
        vm.recordLogs();
        lottery.performUpkeep(""); // calls requestRandomWords that emits RandomWordsRequested(...)
        Vm.Log[] memory recordedEvents = vm.getRecordedLogs();
        //? topic[0] -> the event itself, consequent indexes are event's params
        bytes32 requestId = recordedEvents[0].topics[2];
        Lottery.LotteryState lotteryState = lottery.getLotteryState();

        //3 Assert
        assert(uint256(requestId) > 0);
        assert(lotteryState == Lottery.LotteryState.CALCULATING);
    }

    /////////////////////////
    //* fulfillRandomWords //
    /////////////////////////

    function testFulfillRandomWordsCanOnlyBeCalledAfterPerformUpkeep(
        /* FUZZ TESTING*/ uint256 randomRequestId
    ) public /*1 Arrange */ lotteryEntered timePassed {
        //1 Arrange
        vm.expectRevert("nonexistent request");
        VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(
            randomRequestId,
            address(lottery)
        );
    }
}
