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

error Lottery__NotEnoughEthSent();

/**
 * @title A sample Lottery Contract
 * @author Edoardo Carradori
 * @notice This contract is for creating a sample lottery
 * @dev Implements Chainlink VRFv2 & Automation
 */
contract Lottery {
    uint256 private immutable i_entranceFee;
    //? @dev Duration of the lottery in seconds
    uint256 private immutable i_interval;
    address payable[] private s_players;
    uint256 private s_lastTimestamp;

    /**
     * Events
     */
    event EnteredLottery(address indexed player);

    constructor(uint256 _entranceFee, uint256 _interval) {
        i_entranceFee = _entranceFee;
        i_interval = _interval;
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
    }

    /**
     * Getter Functions
     */

    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}
