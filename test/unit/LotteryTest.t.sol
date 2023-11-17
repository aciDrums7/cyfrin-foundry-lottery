// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {DeployLottery} from "../../script/DeployLottery.s.sol";
import {Lottery} from "../../src/Lottery.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract LotteryTest is Test {
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
            callbackGasLimit
        ) = helperConfig.activeNetworkConfig();
        vm.deal(PLAYER, STARTING_USER_BALANCE);
    }

    function testLotteryInitializesInOpenState() public view {
        assert(lottery.getLotteryState() == Lottery.LotteryState.OPEN);
    }

    /////////////////////
    // enterLottery    //
    /////////////////////

    function testLotteryRevertsWhenYouDontPayEnough() public {
        //1 Arrange
        vm.prank(PLAYER);

        //2 Act / Assert
        vm.expectRevert(Lottery.Lottery__NotEnoughEthSent.selector);
        lottery.enterLottery();
    }

    function testLotteryRecordsPlayersWhenTheyEnter() public {
        //1 Arrange
        vm.prank(PLAYER);

        //2 Act
        lottery.enterLottery{value: entranceFee}();
        address playerRecorded = lottery.getPlayer(0);

        //3 Assert
        assert(playerRecorded == PLAYER);
    }
}
