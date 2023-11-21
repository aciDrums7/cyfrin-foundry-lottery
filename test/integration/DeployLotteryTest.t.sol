// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {DeployLottery} from "../../script/DeployLottery.s.sol";
import {Lottery} from "../../src/Lottery.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract InteractionsTest is Test {
    // uint64 subId;

    function setUp() external {
        // (, , , , subId, , , ) = helperConfig.activeNetworkConfig();
    }

    modifier skipAnvil() {
        if (block.chainid == 31337) {
            return;
        }
        _;
    }

    modifier skipFork() {
        if (block.chainid != 31337) {
            return;
        }
        _;
    }

    /////////////////////
    //* run            //
    /////////////////////

    function test_RunCreatesSubscriptionOnAnvilChain() public skipFork {
        HelperConfig helperConfig = new HelperConfig();
        (, HelperConfig deployConfig) = new DeployLottery().deployLottery(
            helperConfig
        );
        (, , , , uint64 subId, , , ) = deployConfig.activeNetworkConfig();
        assert(subId == 1);
    }

    function test_RunGetsCorrectSubIdForNonAnvilChains() public skipAnvil {
        HelperConfig helperConfig = new HelperConfig();
        (, , , , uint64 subId, , , ) = helperConfig.activeNetworkConfig();
        (, HelperConfig deployConfig) = new DeployLottery().deployLottery(
            helperConfig
        );
        (, , , , uint64 deployedSubId, , , ) = deployConfig
            .activeNetworkConfig();
        assert(subId == deployedSubId);
    }
}
