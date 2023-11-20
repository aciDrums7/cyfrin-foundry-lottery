// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {Script, console} from "forge-std/Script.sol";
import {Lottery} from "../src/Lottery.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script {
    function createSubscriptionUsingConfig() public returns (uint64) {
        HelperConfig helperConfig = new HelperConfig();
        (, , address vrfCoordinator, , , , ) = helperConfig
            .activeNetworkConfig();
        return createSubscription(vrfCoordinator);
    }

    function createSubscription(
        address _vrfCoordinator
    ) public returns (uint64) {
        console.log("Creating subscription on chainID:", block.chainid);
        vm.startBroadcast();
        uint64 subId = VRFCoordinatorV2Mock(_vrfCoordinator)
            .createSubscription();
        vm.stopBroadcast();
        console.log("Your subscriptionID is:", subId, "\n");
        if (block.chainid != 31337) {
            console.log("Please update subscriptionId in HelperConfig.s.sol");
        }
        return subId;
    }

    function run() external returns (uint64) {
        return createSubscriptionUsingConfig();
    }
}

contract FundSubscription is Script {
    uint96 public constant FUND_AMOUNT = 3 ether; // LINK

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        (
            ,
            ,
            address vrfCoordinator,
            ,
            uint64 subId,
            ,
            address linkToken
        ) = helperConfig.activeNetworkConfig();
        fundSubscription(vrfCoordinator, subId, linkToken);
    }

    //? Function to fund a subscription, as like through the Chainlink Docs UI
    function fundSubscription(
        address _vrfCoordinator,
        uint64 _subId,
        address _linkToken
    ) public {
        console.log("Funding subscriptionID:", _subId);
        console.log("Using vrfCoordinator:", _vrfCoordinator);
        console.log("On ChainID:", block.chainid, "\n");
        if (block.chainid == 31337) {
            vm.startBroadcast();
            VRFCoordinatorV2Mock(_vrfCoordinator).fundSubscription(
                _subId,
                FUND_AMOUNT
            );
            vm.stopBroadcast();
        } else {
            vm.startBroadcast();
            LinkToken(_linkToken).transferAndCall(
                _vrfCoordinator,
                FUND_AMOUNT,
                abi.encode(_subId)
            );
            vm.stopBroadcast();
        }
    }

    function run() external {
        fundSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script {
    function addConsumer(
        address _lottery,
        address _vrfCoordinator,
        uint64 _subId
    ) public {
        console.log("Adding consumer contract:", _lottery);
        console.log("Using vrfCoordinator:", _vrfCoordinator);
        console.log("On ChainID:", block.chainid);
        vm.startBroadcast();
        VRFCoordinatorV2Mock(_vrfCoordinator).addConsumer(_subId, _lottery);
        vm.stopBroadcast();
    }

    function addConsumerUsingConfig(address _lottery) public {
        HelperConfig helperConfig = new HelperConfig();
        (, , address vrfCoordinator, , uint64 subId, , ) = helperConfig
            .activeNetworkConfig();
        addConsumer(_lottery, vrfCoordinator, subId);
    }

    function run() external {
        address lottery = DevOpsTools.get_most_recent_deployment(
            "Lottery",
            block.chainid
        );
        addConsumerUsingConfig(lottery);
    }
}
