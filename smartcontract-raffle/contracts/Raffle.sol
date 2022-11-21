// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

error Raffle_NotEnoughBalance();

contract Raffle {
    /* State variables */
    uint256 private immutable i_entranceFee;
    address payable[] private s_participants;

    constructor(uint256 entranceFee) {
        i_entranceFee = entranceFee;
    }

    function enterRaffle() public payable {
        // require(msg.value >= i_entranceFee, "Not enough balance!");
        if (msg.value < i_entranceFee) {
            revert Raffle_NotEnoughBalance();
        }
        s_participants.push(payable(msg.sender));
    }

    // function selectRandomWinner() {

    // }
}