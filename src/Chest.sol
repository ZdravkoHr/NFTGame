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

    struct Common {
        uint256 ID; // ID in ERC1155 amount in ERC20
        uint256 chance; // the chance number
    }

    struct Prize {
        PrizeType prizeTypes;
        Common common;
    }

    mapping(uint256 ID => mapping(uint256 time => bool claimed)) public claimed;

    uint256 public constant BIP = 100000; // 100k, 1 == 0.001
    uint256 public interval;
    uint256 public blockInterval; // used to prevent addressLottery manipulation
    uint256 public lastTimeCalled;
    uint256 public currentNumber;
    uint256 public currentID;

    uint256[] public weaponChances;
    uint256[] public potionChances;
    uint256[] public coinChances;

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

    function addPrize(Prize memory prize) external onlyOwner {
        if (prize.common.chance > BIP) revert IncorrectChance();

        if (prize.prizeTypes == PrizeType.Weapon) {
            weaponChances.push(prize.common.chance);
        } else if (prize.prizeTypes == PrizeType.Potion) {
            potionChances.push(prize.common.chance);
        } else if (prize.prizeTypes == PrizeType.Coin) {
            coinChances.push(prize.common.chance);
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
