// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Player} from "./Player.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {VRFConsumerBaseV2} from "@chainlink/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import {EnumerableSet} from "@openzeppelincontracts/utils/structs/EnumerableSet.sol";
import {VRFCoordinatorV2Interface} from "@chainlink/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

contract Chest is VRFConsumerBaseV2, Ownable {
    using EnumerableSet for EnumerableSet.UintSet;

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

    EnumerableSet.UintSet private weaponChances;
    EnumerableSet.UintSet private potionChances;
    EnumerableSet.UintSet private coinChances;

    mapping(uint256 ID => mapping(uint256 time => bool claimed)) public claimed;

    uint256 public constant BIP = 100000; // 100k, 1 == 0.001
    uint256 public interval;
    uint256 public blockInterval; // used to prevent addressLottery manipulation
    uint256 public lastTimeCalled;
    uint256 public currentNumber;
    uint256 public currentID;

    mapping(PrizeType types => mapping(uint256 id => uint256)) public chances;

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
            if (weaponChances.length() > 0) {
                if (weaponChances.at(weaponChances.length() - 1) >= chance) revert ChanceTooSmall();
            }
            if (!weaponChances.add(chance)) revert WeaponNotAdded(chance);
            
        } else if (itemType == PrizeType.Potion) {
            if (potionChances.length() > 0) {
                if (potionChances.at(potionChances.length() - 1) >= chance) revert ChanceTooSmall();
            }
            if (!potionChances.add(chance)) revert PotionNotAdded(chance);

        } else if (itemType == PrizeType.Coin) {
            if (coinChances.length() > 0) {
                if (coinChances.at(coinChances.length() - 1) >= chance) revert ChanceTooSmall();
            }
            if (!coinChances.add(chance)) revert CoinNotAdded(chance);

        } else {
            revert IncorrectItemType();
        }
    }

    function removePrize(PrizeType itemType, uint256 chance) external onlyOwner {
        if (chance > BIP) revert IncorrectChance();

        if (itemType == PrizeType.Weapon) {
            if (!weaponChances.remove(chance)) revert WeaponNotRemoved(chance);
        } else if (itemType == PrizeType.Potion) {
            if (!potionChances.remove(chance)) revert PotionNotRemoved(chance);
        } else if (itemType == PrizeType.Coin) {
            if (!coinChances.remove(chance)) revert CoinNotRemoved(chance);
        } else {
            revert IncorrectItemType();
        }
    }

    function claimPrize(uint256 playerID) external {
        if (claimed[playerID][lastTimeCalled]) revert AlreadyClaimed();
        if (player.regeteredTime(playerID) - blockInterval > lastTimeCalled) revert TooLateToPlay();

        uint256 luckyNumber = uint256(bytes32(keccak256(abi.encodePacked(playerID, currentNumber))));
        uint256 itemType = luckyNumber % 3;
        uint256 itemChance = luckyNumber % BIP;

        if (itemType == uint256(PrizeType.Weapon)) {
            _itemRoll(weaponChances, itemChance);
        } else if (itemType == uint256(PrizeType.Potion)) {
            _itemRoll(potionChances, itemChance);
        } else {
            _itemRoll(coinChances, itemChance);
        }

        laimed[playerID][lastTimeCalled] = true;
    }

    function _itemRoll(EnumerableSet.UintSet set, uint256 chance) internal {
        uint256 lenght = set.lenght();
        for (uint256 i; i < lenght; i++) {
            if (set.at(i + 1) > chance) {}
        }
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
