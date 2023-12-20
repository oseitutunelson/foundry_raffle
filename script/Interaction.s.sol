//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script,console} from 'forge-std/Script.sol';
import {HelperConfig} from './HelperConfig.s.sol';
import {VRFCoordinatorV2Mock} from '@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol';
import {LinkToken} from '../test/mocks/LinkToken.sol';
import {DevOpsTools} from 'lib/foundry-devops/src/DevOpsTools.sol';

contract CreateSubscription is Script{
   //subscription configuration
   function createSubscriptionConfig() public returns (uint64){
     HelperConfig helperConfig = new HelperConfig();
    (,,address vrfCordinator,,,,) = helperConfig.activeNetworkConfig();
     return createSubscription(vrfCordinator);
   }

   function createSubscription(address vrfCordinator) public returns (uint64){
    console.log("Created subscription ", block.chainid);
    vm.startBroadcast();
    uint64 subId = VRFCoordinatorV2Mock(vrfCordinator).createSubscription();
    vm.stopBroadcast();
    console.log("Your subId is",subId);
    return subId;
   }

    //function to run
    function run() external returns (uint64){
        return createSubscriptionConfig();
    }
}

contract FundSubscription is Script{
    uint96 public constant FUND_ETHER = 3 ether;

    function fundSubscriptionConfig() public{
        HelperConfig helperConfig = new HelperConfig();
    (,,address vrfCordinator,,uint64 subId,,address link) = helperConfig.activeNetworkConfig();
    fundSubscription(vrfCordinator,subId,link);
    }

    function fundSubscription(address vrfCordinator,uint64 subId,address link) public{
        if(block.chainid == 31337){
            vm.startBroadcast();
            VRFCoordinatorV2Mock(vrfCordinator).fundSubscription(subId,FUND_ETHER);
            vm.stopBroadcast();
        }else{
            vm.startBroadcast();
            LinkToken(link).transferAndCall(
                vrfCordinator,FUND_ETHER,abi.encode(subId)
            );
            vm.stopBroadcast();
        }
    }

    function run() external{
        fundSubscriptionConfig();
    }
}

contract AddConsumer is Script{
    function addConsumer(address raffle,address vrfCordinator,uint64 subId) public{
        vm.startBroadcast();
        VRFCoordinatorV2Mock(vrfCordinator).addConsumer(subId,raffle); 
        vm.stopBroadcast();
    }

    function addConsumerUsingConfig(address raffle) public{
        HelperConfig helperConfig = new HelperConfig();
        (,,address vrfCordinator,,uint64 subId,,) = helperConfig.activeNetworkConfig(); 
        addConsumer(raffle,vrfCordinator,subId);
    }

    function run() external{
        address raffle = DevOpsTools.get_most_recent_deployment(
            "Raffle",
            block.chainid
        );
        addConsumerUsingConfig(raffle);
    }
}