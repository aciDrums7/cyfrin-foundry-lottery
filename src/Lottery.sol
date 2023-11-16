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
    address payable[] private s_players;

    /**
     * Events
     */
    event EnteredLottery(address indexed player);

    constructor(uint256 _entranceFee) {
        i_entranceFee = _entranceFee;
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

    function pickWinner() public {}

    /**
     * Getter Functions
     */

    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}
