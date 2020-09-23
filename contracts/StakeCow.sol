// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/**
 * NFT for https://stakecow.com
 */
contract StakeCow is ERC721, Ownable {
	mapping (address => bool) public minters;
  uint256 public constant MAX_SUPPLY = 1000;

	uint256 public currentTokenID = 0;
	
  constructor() public ERC721("StakeCow.com", "COW") {
    _setBaseURI("https://nft.stakecow.com/cow/");
  }

  function maxSupply() public pure returns (uint256) {
    return MAX_SUPPLY;
  }

  function setBaseURI(string memory baseURI_) public onlyOwner {
    _setBaseURI(baseURI_);
  }

  function addMinter(address minter) public onlyOwner {
  	minters[minter] = true;
  }

  function removeMinter(address minter) public onlyOwner {
  	minters[minter] = false;
  }

  modifier onlyMinter() {
    require(minters[msg.sender], "Not minter");
    _;
  }

  function mint(address to) public onlyMinter {
    require(totalSupply() <= MAX_SUPPLY, "Exceeds max supply");
  	_mint(to, currentTokenID);
  	currentTokenID++;
  }
}
