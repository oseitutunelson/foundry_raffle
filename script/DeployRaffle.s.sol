//SPDX-License-Identifier:MIT

pragma solidity ^0.8.18;

import {Script} from 'forge-std/Script.sol';
import {Raffle} from '../src/Raffle.sol';
import {HelperConfig} from './HelperConfig.s.sol';
import {CreateSubscription} from './Interaction.s.sol';
import {FundSubscription} from './Interaction.s.sol';
import {AddConsumer} from './Interaction.s.sol';

contract DeployRaffle is Script{
    //function to deploy
    function run() external returns (Raffle,HelperConfig){
       HelperConfig helperConfig = new HelperConfig();
       (
        uint256 entranceFee,
        uint256 interval,
        address vrfCordinator,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callBackGasLimit,
        address link
       ) = helperConfig.activeNetworkConfig();

       if(subscriptionId == 0){
          CreateSubscription createSubscription = new CreateSubscription();
          subscriptionId = createSubscription.createSubscription(vrfCordinator);

          //Fund subscription
          FundSubscription fundSubscription = new FundSubscription();
          fundSubscription.fundSubscription(
            vrfCordinator,subscriptionId,link
          );
       }

       vm.startBroadcast();
       Raffle raffle= new Raffle
       (entranceFee,
       interval,
       vrfCordinator,
       gasLane,
       subscriptionId,
       callBackGasLimit
       );
       vm.stopBroadcast();

       AddConsumer addConsumer = new AddConsumer();
       addConsumer.addConsumer(address(raffle),vrfCordinator,subscriptionId);
       return (raffle,helperConfig);
    }
}