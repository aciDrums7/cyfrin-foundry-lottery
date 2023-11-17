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

error Lottery__NotEnoughEthSent();
error Lottery__TransferFailed();

/**
 * @title A sample Lottery Contract
 * @author Edoardo Carradori
 * @notice This contract is for creating a sample lottery
 * @dev Implements Chainlink VRFv2 & Automation
 */
contract Lottery is VRFConsumerBaseV2 {
    /**
     * State Variables
     */

    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    uint256 private immutable i_entranceFee;
    //? @dev Duration of the lottery in seconds
    uint256 private immutable i_interval;
    address payable[] private s_players;
    uint256 private s_lastTimestamp;
    address private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    address private s_recentWinner;

    /**
     * Events
     */
    event EnteredLottery(address indexed player);

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
        i_vrfCoordinator = _vrfCoordinator;
        i_gasLane = _gasLane;
        i_subscriptionId = _subscriptionId;
        i_callbackGasLimit = _callbackGasLimit;
        s_lastTimestamp = block.timestamp;
    }

    function enterLottery() external payable {
        if (msg.value < i_entranceFee) {
            revert Lottery__NotEnoughEthSent();
        }
        s_players.push(payable(msg.sender));
        //! Whenever a storage var is updated, an EVENT should be emitted!
        //1. Makes migration easier
        //2. Makes front end "indexing" easier
        emit EnteredLottery(msg.sender);
    }

    //1. Get a random number
    //2. Use the random number to pick a player
    //3. Be automatically called
    function pickWinner() external {
        //? check to see if enough time has passed
        // 1000 - 500 = 500 > 600 -> NOT PASSING
        if ((block.timestamp - s_lastTimestamp) < i_interval) {
            revert();
        }
        //! Will revert if subscription is not set and funded.
        uint256 requestId = VRFCoordinatorV2Interface(i_vrfCoordinator)
            .requestRandomWords(
                i_gasLane,
                i_subscriptionId,
                REQUEST_CONFIRMATIONS,
                i_callbackGasLimit,
                NUM_WORDS
            );
    }

    //? Chainlink VRF returns the random values in a callback to the fulfillRandomWords() function
    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        uint256 indexOfWinner = _randomWords[0] % s_players.length;
        address payable winner = s_players[indexOfWinner];
        s_recentWinner = winner;
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
}
