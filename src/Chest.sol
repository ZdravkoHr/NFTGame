// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import {Ownable} from "@openzeppelin-contracts/access/Ownable.sol";


error InvalidType();

contract Chest is VRFConsumerBaseV2,Ownable {
    // ~~~VRF stats~~~
    VRFCoordinatorV2Interface private immutable VRF;
    uint64 private immutable subID;
    bytes32 private immutable gasLane;
    uint32 private immutable callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    // ~~~Chest stats~~~
    enum PrizeType {
        Weapon,
        Potion,
        Coin
    }

    struct Common{
        uint256 ID; //ID in ERC1155 amount in ERC20
        uint256 chance;// Chance
    }

    struct Prize {
        PrizeType prizeTypes;
        Common common;
    }

    uint256 chanceBIP = 10000; // 10k, 1 == 0.01
    uint256 private interval;
    // requestId => user
    mapping (uint256 => address) public userReqestID;
    mapping (uint256 => Prize) public prizes;

    uint256[] private winnables;
    


    constructor(
        address _vrf,
        uint64 _subscriptionId,
        bytes32 _gasLane, // keyHash
        uint256 _interval,
        uint32 _callbackGasLimit,
        address world
    ) VRFConsumerBaseV2(vrfCoordinatorV2) Ownable(world){
        VRF = VRFCoordinatorV2Interface(_vrf);
        gasLane = _gasLane;
        interval = _interval;
        subID = _subscriptionId;
        callbackGasLimit = _callbackGasLimit;
    }

    function addPrize(Prize prize) external onlyOwner{
       
    }

    function removePrize(Prize prize) external onlyOwner{

    }

    function roll() external {
        
        uint256 requestId = VRF.requestRandomWords(
            gasLane, subID, REQUEST_CONFIRMATIONS, callbackGasLimit, NUM_WORDS
        );
        userReqestID[requestId] = msg.sender;
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        address player = userReqestID[requestId];
        randomWords[0] % loots.length;
        
        if (!success) {
            revert Raffle__TransferFailed();
        }
        emit WinnerPicked(recentWinner);
    }
}
// Hash user addres with random word and use that hash to score a percentage and check to find the prize that user has won, afterwards they can claim them
