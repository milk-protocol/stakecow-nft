// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20 {

	constructor() public ERC20("TOKEN", "TOKEN") {

	}

	function mint(address to, uint amount) public {
		_mint(to, amount);
	}
}