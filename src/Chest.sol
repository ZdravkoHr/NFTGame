// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {VRFCoordinatorV2Interface} from "@chainlink/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Player} from "./Player.sol";

error InvalidType();
// Hash user addres with random word and use that hash to score a percentage and check to find the prize that user has won, afterwards they can claim them

contract Chest is VRFConsumerBaseV2, Ownable {
    // ~~~VRF stats~~~
    VRFCoordinatorV2Interface public immutable VRF;
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

    mapping(uint256 ID => mapping(uint256 time => bool claimed)) public claimed;

    uint256 public constant BIP = 100000; // 100k, 1 == 0.001
    uint256 public interval;
    uint256 public blockInterval; // used to prevent addressLottery manipulation
    uint256 public lastTimeCalled;
    uint256 public currentNumber;
    uint256 public currentID;

    uint256 weaponCount;
    uint256 potionCount;
    uint256 coinCount;

    uint256[] public weaponChances;
    uint256[] public potionChances;
    uint256[] public coinChances;

    mapping (PrizeType types => mapping(uint256 id => uint256)) public chances;

    Player public player;

    constructor(
        address _vrf,
        address _player,
        uint64 _subscriptionId,
        bytes32 _gasLane, // keyHash
        uint256 _interval, // 1 week
        uint256 _blockInterval, // 1 day
        uint32 _callbackGasLimit,
        address _world
    ) VRFConsumerBaseV2(_vrf) Ownable(_world) {
        VRF = VRFCoordinatorV2Interface(_vrf);
        player = Player(_player);
        gasLane = _gasLane;
        interval = _interval;
        subID = _subscriptionId;
        callbackGasLimit = _callbackGasLimit;
        blockInterval = _blockInterval;
    }

    function addPrize(PrizeType itemType, uint256 chance) external onlyOwner {
        if (chance > BIP) revert IncorrectChance();


        if (itemType == PrizeType.Weapon) {
            if(chances[PrizeType.Weapon][weaponCount] <= chance) revert ChanceTooSmall();

            weaponCount++;
            weaponChances.push(chance);
            chances[PrizeType.Weapon][weaponCount] = chance;

        } else if (itemType == PrizeType.Potion) {
            if(chances[PrizeType.Potion][potionCount] <= chance) revert ChanceTooSmall();

            potionCount++;
            potionChances.push(chance);
            chances[PrizeType.Potion][potionCount] = chance;

        } else if (itemType == PrizeType.Coin) {
            if(chances[PrizeType.Coin][coinCount] <= chance) revert ChanceTooSmall();

            coinCount++;
            coinChances.push(chance);
            chances[PrizeType.Coin][coinCount] = chance;

        } else {
            revert IncorrectItemType();
        }
    }

    function removePrize(Prize memory prize) external onlyOwner {}

    function claimPrize(uint256 playerID) external {
        if (claimed[playerID][lastTimeCalled]) revert AlreadyClaimed();
        if (player.regeteredTime(playerID) - blockInterval > lastTimeCalled) revert TooLateToPlay();

        uint256 luckyNumber = uint256(bytes32(keccak256(abi.encodePacked(playerID, currentNumber))));
        uint256 itemType = luckyNumber % 3;
        uint256 itemNumber = luckyNumber % BIP;

        if (itemType == uint256(PrizeType.Weapon)) {} else if (itemType == uint256(PrizeType.Potion)) {} else {}

        laimed[playerID][lastTimeCalled] = true;
    }

    function roll() external {
        if (block.timestamp + interval <= lastTimeCalled) {
            revert TooEarly();
        }
        lastTimeCalled = block.timestamp;
        currentID = VRF.requestRandomWords(gasLane, subID, REQUEST_CONFIRMATIONS, callbackGasLimit, NUM_WORDS);
    }

    function adminRoll() external onlyOnwer {
        // if the first revert an admin can save this week's raffle
        lastTimeCalled = block.timestamp;
        currentID = VRF.requestRandomWords(gasLane, subID, REQUEST_CONFIRMATIONS, callbackGasLimit, NUM_WORDS);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        currentNumber = randomWords[0];
    }
}
