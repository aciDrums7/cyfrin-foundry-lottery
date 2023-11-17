/* Layout of Contract:
version
imports
errors
interfaces, libraries, contracts
Type declarations
State variables
Events
Modifiers
Functions

Layout of Functions:
constructor
receive function (if exists)
fallback function (if exists)
external
public
internal
private
view & pure functions */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";

/**
 * @title A sample Lottery Contract
 * @author Edoardo Carradori
 * @notice This contract is for creating a sample lottery
 * @dev Implements Chainlink VRFv2 & Automation
 */
contract Lottery is VRFConsumerBaseV2, AutomationCompatibleInterface {
    /**
     * Errors
     */
    error Lottery__NotEnoughEthSent();
    error Lottery__TransferFailed();
    error Lottery__LotteryNotOpen();
    error Lottery_UpkeepNotNeeded(
        uint256 balance,
        uint256 nPlayers,
        uint256 lotteryState
    );

    /**
     * Type declaration
     */
    enum LotteryState {
        OPEN, // 0
        CALCULATING // 1
    }

    /**
     * State Variables
     */

    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    uint256 private immutable i_entranceFee;
    //? @dev Duration of the lottery in seconds
    uint256 private immutable i_interval;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;

    address payable[] private s_players;
    uint256 private s_lastTimestamp;
    address private s_recentWinner;
    LotteryState private s_lotteryState;
    /**
     * Events
     */
    event EnteredLottery(address indexed player);
    event PickedWinner(address indexed winner);

    constructor(
        uint256 _entranceFee,
        uint256 _interval,
        address _vrfCoordinator,
        bytes32 _gasLane,
        uint64 _subscriptionId,
        uint32 _callbackGasLimit
    ) VRFConsumerBaseV2(_vrfCoordinator) {
        i_entranceFee = _entranceFee;
        i_interval = _interval;
        i_vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
        i_gasLane = _gasLane;
        i_subscriptionId = _subscriptionId;
        i_callbackGasLimit = _callbackGasLimit;

        s_lastTimestamp = block.timestamp;
        s_lotteryState = LotteryState.OPEN;
    }

    // CEI -> Checks, Effects, Interactions
    function enterLottery() external payable {
        // Checks
        if (msg.value < i_entranceFee) {
            revert Lottery__NotEnoughEthSent();
        }
        if (s_lotteryState != LotteryState.OPEN) {
            revert Lottery__LotteryNotOpen();
        }

        // Effects (on our contract)
        s_players.push(payable(msg.sender));
        //! Whenever a storage var is updated, an EVENT should be emitted!
        //1. Makes migration easier
        //2. Makes front end "indexing" easier
        emit EnteredLottery(msg.sender);

        // Interactions (with other contracts)
    }

    //? When is the winner supposed to be picked?
    /**
     * @dev This is the function that the Chainlink Automation node calls
     * to see if it's time to perform an upkeep.
     * The following should be true for this to return true:
     *  1. The time interval has passed between lottery runs;
     *  2. The lottery is in the OPEN statr
     *  3. The contract has ETH (aka, players)
     *  4. (Implicit) The subscription is funded with LINK
     */
    function checkUpkeep(
        bytes memory /* checkData */
    )
        public
        view
        override
        returns (bool upkeepNeeded, bytes memory /* performData */)
    {
        bool timeHasPassed = (block.timestamp - s_lastTimestamp) >= i_interval;
        bool isLotteryOpen = s_lotteryState == LotteryState.OPEN;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;
        upkeepNeeded = (timeHasPassed &&
            isLotteryOpen &&
            hasBalance &&
            hasPlayers);
        return (upkeepNeeded, "0x0"); //? '0x0' -> black bytes object
    }

    // Be automatically called
    function performUpkeep(bytes calldata /* performData */) external override {
        // Checks
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Lottery_UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_lotteryState)
            );
        }

        // Effects (on our contract)
        s_lotteryState = LotteryState.CALCULATING;

        // Interactions (with other contracts)
        i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
    }

    //? Chainlink VRF returns the random values in a callback to the fulfillRandomWords() function
    function fulfillRandomWords(
        uint256 /* _requestId */,
        uint256[] memory _randomWords
    ) internal override {
        // Checks

        // Effects (on our contract)
        uint256 indexOfWinner = _randomWords[0] % s_players.length;
        address payable winner = s_players[indexOfWinner];
        s_recentWinner = winner;
        s_lotteryState = LotteryState.OPEN;

        s_players = new address payable[](0);
        s_lastTimestamp = block.timestamp;
        emit PickedWinner(winner);
        // Interactions (with other contracts)

        (bool success, ) = winner.call{value: address(this).balance}("");
        if (!success) {
            revert Lottery__TransferFailed();
        }
    }

    /**
     * Getter Functions
     */

    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }

    function getLotteryState() external view returns (LotteryState) {
        return s_lotteryState;
    }

    function getPlayer(uint256 indexOfPlayer) external view returns (address) {
        return s_players[indexOfPlayer];
    }
}
