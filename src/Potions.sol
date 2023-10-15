// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./utils/Events.sol";
import "./utils/Errors.sol";

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ERC1155Burnable} from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";

contract Potion is ERC1155, AccessControl, ERC1155Burnable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor(address owner, address chest) ERC1155("") {
        _grantRole(DEFAULT_ADMIN_ROLE, owner);
        _grantRole(MINTER_ROLE, chest);
    }

    function setURI(string memory uri) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setURI(uri); 
        emit URIset(uri);
    }

    function getURIspecific(uint tokenID) external view returns(string memory){
        return string.concat(_uri,"ID:",toString(tokenID));
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data) public onlyRole(MINTER_ROLE) {
        _mint(account, id, amount, data);
        emit PotionMinted(account,id,amount);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyRole(MINTER_ROLE)
    {
        _mintBatch(to, ids, amounts, data);
        emit BatchPotionMinted(to,ids,amount);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC1155, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
