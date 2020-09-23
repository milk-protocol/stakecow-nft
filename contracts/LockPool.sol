// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./StakeCow.sol";


contract LPTokenWrapper {
	using SafeMath for uint256;
	IERC20 public token;

	constructor(address token_) public {
		token = IERC20(token_);
	}

	uint256 private _totalSupply;
	mapping(address => uint256) private _balances;

	function totalSupply() public view returns (uint256) {
		return _totalSupply;
	}

	function balanceOf(address account) public view returns (uint256) {
		return _balances[account];
	}

	function _stake(uint256 amount) internal {
		_totalSupply = _totalSupply.add(amount);
		_balances[msg.sender] = _balances[msg.sender].add(amount);
		token.transferFrom(msg.sender, address(this), amount);
	}

	function _withdraw(uint256 amount) internal {
		_totalSupply = _totalSupply.sub(amount);
		_balances[msg.sender] = _balances[msg.sender].sub(amount);
		token.transfer(msg.sender, amount);
	}
}

contract LockPool is LPTokenWrapper, Ownable {
	StakeCow public card;
	mapping(address => uint256) public locks;
	uint256 public lockPeriod;
	uint256 public lockAmount;
	uint256 public minted = 0;
	uint256 public startTime = 1600855200; // 2020-09-23 10:00:00 UTC

	event Locked(address indexed user, uint256 amount);
	event Redeemed(address indexed user, uint256 amount);


	constructor(address card_, address token_) public LPTokenWrapper(token_){
		card = StakeCow(card_);
		lockAmount = 30 * 1e18;
		lockPeriod = 7 * 24 * 3600;
	}

	function updateParams(uint256 amount, uint256 period) public onlyOwner {
		require(amount > 0, "Cannot set 0");
		lockAmount = amount;
		lockPeriod = period;
	}

	modifier checkRedeem() {
		require(canRedeem(msg.sender), "Locking");
		_;
	}

	modifier updateLockParams() {
		if(minted > 0 && minted.mod(50) == 0) {
			lockPeriod = lockPeriod.add(24 * 3600);
			lockAmount = lockAmount.add(lockAmount.mul(5).div(100));
		}
		_; 
	}

	function lock() public updateLockParams {
		require(block.timestamp >= startTime, "Not start");
		require(locks[msg.sender] == 0, "Locked");
		require(card.totalSupply() <= card.maxSupply(), "Exceeds max supply");
		super._stake(lockAmount);
		emit Locked(msg.sender, lockAmount);
		locks[msg.sender] = block.timestamp + lockPeriod;
		card.mint(msg.sender);
		minted++;
	}

	function redeem() public checkRedeem {
		super._withdraw(balanceOf(msg.sender));
		emit Redeemed(msg.sender, balanceOf(msg.sender));
		locks[msg.sender] = 0;
	}

	function canRedeem(address user) public view returns (bool) {
		return locks[user] > 0 && locks[user] < block.timestamp;
	}

	function isLocked(address user) public view returns (bool) {
		return locks[user] > 0;
	}

	function unlockTime(address user) public view returns (uint256) {
		return locks[user];
	}
}