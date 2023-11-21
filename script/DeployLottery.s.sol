// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {Lottery} from "../src/Lottery.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "./Interactions.s.sol";

contract DeployLottery is Script {
    function run() external returns (Lottery, HelperConfig) {
        return deployLotteryUsingConfig();
    }

    function deployLotteryUsingConfig() public returns (Lottery, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        return deployLottery(helperConfig);
    }

    function deployLottery(
        HelperConfig _helperConfig
    ) public returns (Lottery, HelperConfig) {
        (
            uint256 entranceFee,
            uint256 interval,
            address vrfCoordinator,
            bytes32 gasLane,
            uint64 subscriptionId,
            uint32 callbackGasLimit,
            address linkToken,
            uint256 deployerKey
        ) = _helperConfig.activeNetworkConfig();

        if (subscriptionId == 0) {
            subscriptionId = createAndFundSubscription(
                _helperConfig,
                vrfCoordinator,
                linkToken,
                deployerKey
            );
        }

        vm.startBroadcast(deployerKey);
        Lottery lottery = new Lottery(
            entranceFee,
            interval,
            vrfCoordinator,
            gasLane,
            subscriptionId,
            callbackGasLimit
        );
        vm.stopBroadcast();

        addConsumer(lottery, vrfCoordinator, subscriptionId, deployerKey);

        return (lottery, _helperConfig);
    }

    function createAndFundSubscription(
        HelperConfig _helperConfig,
        address _vrfCoordinator,
        address _linkToken,
        uint256 _deployerKey
    ) public returns (uint64 subscriptionId) {
        //1 We are going to need to create a subscription!
        subscriptionId = new CreateSubscription().createSubscription(
            _vrfCoordinator,
            _deployerKey
        );
        _helperConfig.setSubscriptionId(subscriptionId);

        //2 Once created, we need to fund it
        new FundSubscription().fundSubscription(
            _vrfCoordinator,
            subscriptionId,
            _linkToken,
            _deployerKey
        );
    }

    function addConsumer(
        Lottery _lottery,
        address _vrfCoordinator,
        uint64 _subscriptionId,
        uint256 _deployerKey
    ) public {
        new AddConsumer().addConsumer(
            address(_lottery),
            _vrfCoordinator,
            _subscriptionId,
            _deployerKey
        );
    }
}
