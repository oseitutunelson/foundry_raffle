// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions
//SPDX-License-Identifier:MIT

pragma solidity ^0.8.18;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";

/**
 * @title A sample lottery/Raffle contract
 * @author Owusu Osei Tutu Nelson
 * @notice This contract is for creating a sample Raffle
 * @dev Using chainlink VRFv2
 */



contract Raffle is VRFConsumerBaseV2{
    //custom errors
    error Raffle__NotEnoughEthSent();
    error Raffle__WinnerNotPaid();
    error Raffle__NotOpen();
    error Raffle__UpKeepNotNeeded(uint256 currentBalance,uint256 numPlayers,uint256 raffleState);

    /** Type variables */
    enum RaffleState{
        OPEN,
        CALCULATING
    }

    //state variables
    uint16 private constant REQUEST_CONFIRMATION = 3;
    uint32 private constant NUMBER_RANDOM = 1;
    
    //immutable variables
    VRFCoordinatorV2Interface private immutable i_vrfCordinator;
    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callBackGasLimit;
    //duration of raffle in seconds
    
    address payable[] private s_players;
    uint256 private s_lastTimeStamp;
    address private s_recentWinner;
    RaffleState private s_raffleState;

    /** Events */
    event EnteredRaffle(address indexed playerEntered);
    event PickedWinner(address indexed winner);
    event RequestRaffleWinner(uint256 indexed requestWinner);

    constructor 
    (uint256 entranceFee,
    uint256 interval,address vrfCordinator,
    bytes32 gasLane,uint64 subscriptionId,
    uint32 callBackGasLimit) VRFConsumerBaseV2(vrfCordinator)
    {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
        i_vrfCordinator = VRFCoordinatorV2Interface(vrfCordinator);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callBackGasLimit = callBackGasLimit;
        s_raffleState = RaffleState.OPEN;
    }

    //function for user to enter raffle
    function enterRaffle() external payable{
       if(msg.value < i_entranceFee){
        revert Raffle__NotEnoughEthSent();
       }
       if(s_raffleState != RaffleState.OPEN){
        revert Raffle__NotOpen();
       }
       s_players.push(payable(msg.sender));
       emit EnteredRaffle(msg.sender);
    }

    //function for time automation to pick winner
    function checkUpKeep(bytes memory /* checkData */) public view returns (bool upKeepNeeded,bytes memory /* performData */){
        bool timeHasPassed = ((block.timestamp - s_lastTimeStamp) >= i_interval);
        bool isOpen = RaffleState.OPEN == s_raffleState;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;
        upKeepNeeded = (timeHasPassed && isOpen && hasBalance && hasPlayers);
        return (upKeepNeeded,'0x0');
    }

    //function for picking winner of raffle
    // 1. pick a random number
    // 2. use the random number to choose a winner
    // 3. use an interval to pick winner
    function performUpKeep(bytes calldata /* performData */) external{
       (bool upKeepNeeded,) = checkUpKeep("");
      if(!upKeepNeeded){
        revert Raffle__UpKeepNotNeeded(
            address(this).balance,
            s_players.length,
            uint256(s_raffleState)
        );
      }
       s_raffleState = RaffleState.CALCULATING;
       //getting a random number from chainlink vrf
      uint256 requestId = i_vrfCordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATION,
            i_callBackGasLimit,
            NUMBER_RANDOM
        );

        emit RequestRaffleWinner(requestId);
    }

    //fullfill random words
    function fulfillRandomWords(uint256 /*request_id*/,uint256[] memory randomWords)
     internal override{
        uint256 indexWinner = randomWords[0] % s_players.length;
        address payable winner = s_players[indexWinner];
        s_recentWinner = winner;

        s_raffleState = RaffleState.OPEN;

        //reset array of players
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        (bool callSuccess, ) = winner.call{value : address(this).balance}("");
        
        if(!callSuccess){
            revert Raffle__WinnerNotPaid();
        }

        emit PickedWinner(winner);
    }

    /** Getter functions */
    //get entrance fee
    function getEntranceFee() external view returns (uint256){
        return i_entranceFee;
    }

    //get raffle state
    function getRaffleState() external view returns (RaffleState){
       return s_raffleState;
    }

    //getPlayer
    function getPlayer(uint256 indexOfPlayer) external view returns (address){
       return s_players[indexOfPlayer];
    } 
}