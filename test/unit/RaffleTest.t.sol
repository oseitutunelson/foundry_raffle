//SPDX-License-Identifier:MIT

pragma solidity ^0.8.18;

import {Test} from 'forge-std/Test.sol';
import {Raffle} from '../../src/Raffle.sol';
import {DeployRaffle} from '../../script/DeployRaffle.s.sol';
import {HelperConfig} from '../../script/HelperConfig.s.sol';

contract RaffleTest is Test{
  /** Events */
  event EnteredRaffle(address indexed player);

    Raffle raffle;
    HelperConfig helperConfig;

    address public PLAYER = makeAddr("player");
    uint256 public constant USER_STARTING_BALANCE = 10 ether;

    uint256 entranceFee;
    uint256 interval;
    address vrfCordinator;
    bytes32 gasLane;
    uint64 subscriptionId;
    uint32 callBackGasLimit;
    

   //setup test
   function setUp() external{
     DeployRaffle deployRaffle = new DeployRaffle();
     (raffle,helperConfig) = deployRaffle.run();

     (
         entranceFee,
         interval,
         vrfCordinator,
         gasLane,
         subscriptionId,
         callBackGasLimit,
         
         
       ) = helperConfig.activeNetworkConfig();

       vm.deal(PLAYER,USER_STARTING_BALANCE);

   }

    function testRaffleIsInitializingInOpenState() public view{
    assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
   }

   function testEnterRaffleWithNotEnoughBalance() public{
    vm.prank(PLAYER);
    vm.expectRevert(Raffle.Raffle__NotEnoughEthSent.selector);
    raffle.enterRaffle();
   }

   function testRecordPlayersWhenTheyEnter() public{
    vm.prank(PLAYER);
    raffle.enterRaffle{value : entranceFee}();
    address playerRecorded = raffle.getPlayer(0);
    assert(playerRecorded == PLAYER);
   }

   function testEmitOnEnterRaffle() public{
    vm.prank(PLAYER);
    vm.expectEmit(true,false,false,false,address(raffle));
    emit EnteredRaffle(PLAYER);
    raffle.enterRaffle{value: entranceFee}( );
   }

  //  function testCannotEnterRaffleWhenCalculating() public{
  //   vm.prank(PLAYER);
  //   raffle.enterRaffle{value : entranceFee}();
  //   vm.warp(block.timestamp + interval + 1);
  //   vm.roll(block.number + 1);

  //   raffle.performUpKeep("");

  //   vm.expectRevert(Raffle.Raffle__NotOpen.selector);
  //   vm.prank(PLAYER);
  //   raffle.enterRaffle{value : entranceFee}();
  //  }
}