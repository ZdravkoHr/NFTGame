// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./utils/Events.sol";
import "./utils/Errors.sol";

import {Coins} from "./Coins.sol";
import {Player} from "./Player.sol";
import {Item} from "./Item.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {VRFConsumerBaseV2} from "@chainlink/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
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

    struct Prize {
        uint256 amount;
        uint256 ID;
    }

    EnumerableSet.UintSet private weaponChances;
    EnumerableSet.UintSet private potionChances;
    EnumerableSet.UintSet private coinChances;

    mapping(PrizeType prizeType => mapping(uint256 ID => Prize)) public prizes;

    mapping(uint256 ID => mapping(uint256 time => bool claimed)) public claimed;

    uint256 private constant BIP = 100000; // 100k, 1 == 0.001
    uint256 private lastTimeCalled;
    uint256 private currentNumber;
    uint256 private blockInterval; // used to prevent addressLottery manipulation
    uint256 private currentID;
    uint256 private interval;

    Player private playerContract;
    Coins private coinsContract;
    Item private itemContract;

    constructor(
        address _vrf,
        address _player,
        address _coin,
        address _itemContract,
        uint64 _subscriptionId,
        bytes32 _gasLane, // keyHash
        uint256 _interval, // 1 week
        uint256 _blockInterval, // 1 day
        uint32 _callbackGasLimit,
        address _world
    ) VRFConsumerBaseV2(_vrf) Ownable(_world) {
        VRF = VRFCoordinatorV2Interface(_vrf);
        playerContract = Player(_player);
        coinsContract = Coins(_coin);
        itemContract = Item(_itemContract);
        gasLane = _gasLane;
        interval = _interval;
        subID = _subscriptionId;
        callbackGasLimit = _callbackGasLimit;
        blockInterval = _blockInterval;

        if (!weaponChances.add(0)) revert ChanceNotAdded();
        if (!potionChances.add(0)) revert ChanceNotAdded();
        if (!coinChances.add(0)) revert ChanceNotAdded();
    }

    function addChance(PrizeType itemType, uint256 chance, uint256 amount, uint256 ID) external onlyOwner {
        _addChance(itemType, chance, amount, ID);
    }

    function _addChance(PrizeType itemType, uint256 chance, uint256 amount, uint256 ID) internal {
        if (chance > BIP) revert IncorrectChance();

        if (itemType == PrizeType.Weapon) {
            uint256 length = weaponChances.length();
            if (length > 0) {
                if (weaponChances.at(length - 1) >= chance) revert ChanceTooSmall();
            }
            prizes[itemType][length].amount = amount;
            prizes[itemType][length].ID = ID;
            if (!weaponChances.add(chance)) revert WeaponNotAdded(chance);
        } else if (itemType == PrizeType.Potion) {
            uint256 length = weaponChances.length();
            if (length > 0) {
                if (potionChances.at(length - 1) >= chance) revert ChanceTooSmall();
            }
            prizes[itemType][length].amount = amount;
            prizes[itemType][length].ID = ID;
            if (!potionChances.add(chance)) revert PotionNotAdded(chance);
        } else if (itemType == PrizeType.Coin) {
            uint256 length = weaponChances.length();
            if (length > 0) {
                if (coinChances.at(length - 1) >= chance) revert ChanceTooSmall();
            }
            prizes[itemType][length].amount = amount;
            prizes[itemType][length].ID = ID;
            if (!coinChances.add(chance)) revert CoinNotAdded(chance);
        } else {
            revert IncorrectItemType();
        }
        emit Events.ItemAdded(uint256(itemType), chance, ID, amount);
    }

    function addChances(
        PrizeType[] calldata itemTypes,
        uint256[] calldata chances,
        uint256[] calldata amounts,
        uint256[] calldata IDs
    ) external onlyOwner {
        uint256 length = itemTypes.length;
        if (length != chances.length || length != amounts.length || length != IDs.length) {
            for (uint256 i; i < length; i++) {
                _addChance(itemTypes[i], chances[i], amounts[i], IDs[i]);
            }
        }
    }

    function claimPrize(uint256 playerID) external {
        if (claimed[playerID][lastTimeCalled]) revert AlreadyClaimed();
        if (playerContract.regeteredTime(playerID) - blockInterval > lastTimeCalled) revert TooLateToPlay();

        uint256 luckyNumber = uint256(bytes32(keccak256(abi.encodePacked(playerID, currentNumber))));
        uint256 itemType = luckyNumber % 3;
        uint256 itemChance = luckyNumber % BIP;
        uint256 item;
        Prize memory wonPrize;

        if (itemType == uint256(PrizeType.Weapon)) {
            item = _itemRoll(weaponChances, itemChance);
            wonPrize = prizes[PrizeType.Weapon][item];
            itemContract.mint(msg.sender, wonPrize.ID, wonPrize.amount,"");
        } else if (itemType == uint256(PrizeType.Potion)) {
     
            item = _itemRoll(potionChances, itemChance);
            wonPrize = prizes[PrizeType.Potion][item];
            itemContract.mint(msg.sender, wonPrize.ID, wonPrize.amount,"");
        } else {
            item = _itemRoll(coinChances, itemChance);
            coinsContract.mint(msg.sender, prizes[PrizeType.Coin][item].amount);
        }
        claimed[playerID][lastTimeCalled] = true;
    }

    function _itemRoll(EnumerableSet.UintSet storage set, uint256 chance) internal view returns (uint256) {
        uint256 length = set.length();
        for (uint256 i; i < length; i++) {
            if (set.at(i) <= chance) {
                if (set.at(set.length() - 1) == i) {
                    return i;
                } else if (set.at(i + 1) > chance) {
                    return i;
                }
                continue;
            }
        }
    }

    function roll() external {
        if (block.timestamp <= lastTimeCalled + interval) {
            revert TooEarly();
        }
        lastTimeCalled = (block.timestamp / interval) * interval;
        currentID = VRF.requestRandomWords(gasLane, subID, REQUEST_CONFIRMATIONS, callbackGasLimit, NUM_WORDS);
        emit Events.rollReqested(currentID);
    }

    function adminRoll() external onlyOwner {
        // if the first revert an admin can save this week's raffle
        lastTimeCalled = (block.timestamp / interval) * interval;
        currentID = VRF.requestRandomWords(gasLane, subID, REQUEST_CONFIRMATIONS, callbackGasLimit, NUM_WORDS);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        currentNumber = randomWords[0];
        emit Events.NewRandomNumber(block.timestamp, randomWords[0]);
    }
    function getValues(EnumerableSet.UintSet set) external view returns(uint256[] memory){
        return set.values();
    }
}
