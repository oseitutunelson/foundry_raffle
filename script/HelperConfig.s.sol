//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from 'forge-std/Script.sol';
import {VRFCoordinatorV2Mock} from '@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol';
import {LinkToken} from '../test/mocks/LinkToken.sol';

contract HelperConfig is Script{
   struct NetworkConfig{
    uint256 entranceFee;
    uint256 interval;
    address vrfCordinator;
    bytes32 gasLane;
    uint64 subscriptionId;
    uint32 callBackGasLimit;
    address link;
   }

   NetworkConfig public activeNetworkConfig;

   constructor(){
    if(block.chainid == 11155111){
        activeNetworkConfig = getSepolia();
    }else{

    }
   }

   //getSepolia chain
   function getSepolia() public pure returns (NetworkConfig memory){
      return NetworkConfig({
        entranceFee : 0.01 ether,
        interval : 30,
        vrfCordinator : 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625,
        gasLane : 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
        subscriptionId : 0,
        callBackGasLimit : 500000,
        link : 0x779877A7B0D9E8603169DdbD7836e478b4624789
      });
   }

   //getAnvilChain
   function getAnvilChain() public returns (NetworkConfig memory){
    if(activeNetworkConfig.vrfCordinator != address(0)){
        return activeNetworkConfig;
    }
   
    uint96 base_fee = 0.25 ether;
    uint96 gasLinkPrice = 1e9;

    vm.startBroadcast();
     VRFCoordinatorV2Mock vrfCoordinator = new VRFCoordinatorV2Mock(base_fee,gasLinkPrice);
     LinkToken lnk = new LinkToken();
    vm.stopBroadcast();

    return NetworkConfig({
        entranceFee : 0.01 ether,
        interval : 30,
        vrfCordinator : address(vrfCoordinator),
        gasLane : 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
        subscriptionId : 0,
        callBackGasLimit : 500000,
        link  : address(lnk)
    });
   }
}