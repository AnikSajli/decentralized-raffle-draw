// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";

/* Errors */
error Raffle_NotEnoughBalance();
error Raffle_TransferFailed();
error Raffle_NotOpen();
error Raffle_UpkeepNotNeeded(uint256 currentBalance, uint256 playerCount, uint256 raffleState);

contract Raffle is VRFConsumerBaseV2, AutomationCompatibleInterface {
    /* Type declarations */
    enum RaffleState {
        OPEN,
        CALCULATING
    }
    
    /* State variables */
    uint256 private immutable i_entranceFee;
    address payable[] private s_participants;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private immutable i_callbackGasLimit;
    uint32 private constant NUM_WORDS = 1;

    address private s_recentWinner;
    RaffleState private s_raffleState;
    uint256 private s_lastTimeStamp;
    uint256 private immutable i_interval;

    /* Events */
    event RaffleEnter(address indexed player);
    event RequestedRaffleWinner(uint256 indexed requestId);
    event WinnerSelected(address indexed winner);

    constructor (
        uint256 entranceFee, 
        address vrfCoordinatorV2, 
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit,
        uint256 interval
    ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_entranceFee = entranceFee;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_raffleState = RaffleState.OPEN;
        s_lastTimeStamp = block.timestamp;
        i_interval = interval;
    }

    /* Functions */
    function enterRaffle() public payable {
        // require(msg.value >= i_entranceFee, "Not enough balance!");
        if (msg.value < i_entranceFee) {
            revert Raffle_NotEnoughBalance();
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle_NotOpen();
        }

        s_participants.push(payable(msg.sender));
    }

    function performUpkeep (bytes calldata) external {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle_UpkeepNotNeeded(address(this).balance, s_participants.length, uint256(s_raffleState)); 
        }
        s_raffleState = RaffleState.CALCULATING;
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
        emit RequestedRaffleWinner(requestId);
    }

    function checkUpkeep(bytes calldata) public override returns(bool upkeepNeeded, bytes memory) {
        bool isOpen = (RaffleState.OPEN == s_raffleState);
        bool timePassed = ((block.timestamp - s_lastTimeStamp) > i_interval);
        bool hasPlayers = (s_participants.length > 0);
        bool hasBalance = address(this).balance > 0;
        upkeepNeeded = (isOpen && timePassed && hasPlayers && hasBalance);
    }

    function fulfillRandomWords(uint256, /* requestId */uint256[] memory randomWords) internal override {
        uint256 indexOfWinner = randomWords[0] % s_participants.length;
        address payable recentWinner = s_participants[indexOfWinner];
        s_recentWinner = recentWinner;
        s_raffleState = RaffleState.OPEN;
        s_lastTimeStamp = block.timestamp;
        s_participants = new address payable[](0);
        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle_TransferFailed();
        }
        emit WinnerSelected(recentWinner);
    }

    /* View functions */
    function getRecentWinner() public view returns(address) {
        return s_recentWinner;
    }

    function getEntranceFee() public view returns(uint256) {
        return i_entranceFee;
    }

    function getParticipant(uint256 index) public view returns(address) {
        return s_participants[index];
    } 
}