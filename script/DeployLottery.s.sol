// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {Lottery} from "../src/Lottery.sol";

contract DeployLottery is Script {
    function run() external returns (Lottery) {}
}
