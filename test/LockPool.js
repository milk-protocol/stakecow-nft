const { accounts, contract } = require('@openzeppelin/test-environment');
const { expect } = require('chai');
const { toBN } = require('web3-utils');
const { BN, expectEvent, expectRevert, time, constants } = require('@openzeppelin/test-helpers');

const [ admin, deployer, user, minter ] = accounts;

const Cow = contract.fromArtifact('StakeCow');
const LockPool = contract.fromArtifact('LockPool');
const Token = contract.fromArtifact('Token');

describe("LockPool", function() {
	const BASE = new BN('10').pow(new BN('18'))

	it("should create LockPool contract successfully", async ()=> {
		let cow = await Cow.new({from: admin});
		expect(await cow.owner()).to.equal(admin);
		let supply = await cow.totalSupply();
		expect(supply.toString()).to.equal("0");
	});

	it("only minter can mint", async() => {
		let cow = await Cow.new({from: admin});
		await expectRevert(
			cow.mint(user, { from:  user}), "Not minter"
		);
		await cow.addMinter(minter, { from: admin });
		await cow.mint(user, { from:  minter});
		let balance = await cow.balanceOf(user);
		expect(balance).be.bignumber.to.equal("1");
	});

	it("lock token and mint", async() => {
		let cow = await Cow.new({from: admin});
		let token = await Token.new();
		let lockPool = await LockPool.new(cow.address, token.address, {from: admin});
		await cow.addMinter(lockPool.address, { from: admin })

		let amount = toBN(1000).mul(BASE);
		await token.mint(user, amount);
		await token.approve(lockPool.address, amount, {from: user});

		
		await expectRevert(
			lockPool.lock({from: user}), "Not start"
		)
		let startTime = await lockPool.startTime();
		time.increaseTo(startTime.toNumber() + 1);

		await lockPool.lock({from: user});
		let balance = await token.balanceOf(user);
		expect(balance.toString()).to.equal(toBN(970).mul(BASE).toString())

		let cowBalance = await cow.balanceOf(user);
		expect(cowBalance.toNumber()).to.equal(1);

		await expectRevert(
			lockPool.redeem({ from:  user}), "Locking"
		);
		await time.increase(7 * 24 * 3600 + 1);
		await lockPool.redeem({ from:  user});

		let balanceAfter = await token.balanceOf(user);
		expect(balanceAfter.toString()).to.equal(toBN(1000).mul(BASE).toString())
	});

	it("updateLockParams", async() => {
		let cow = await Cow.new({from: admin});
		let token = await Token.new();
		let lockPool = await LockPool.new(cow.address, token.address, {from: admin});
		await cow.addMinter(lockPool.address, { from: admin })
		await cow.addMinter(deployer, { from: admin })

			
		let mints = Array(51).fill(0).map(i=>{
			return cow.mint(admin, {from: deployer})
		});
		await Promise.all(mints)

		let amount = toBN(1000).mul(BASE);
		await token.mint(user, amount);
		await token.approve(lockPool.address, amount, {from: user});
		
		await lockPool.lock({from: user});

		let period = await lockPool.lockPeriod();
		let lockAmount = await lockPool.lockAmount();

		expect(period.toNumber()).to.equal(7 * 24 * 3600)
		expect(lockAmount.toString()).to.equal(toBN(300).mul(BASE.div(toBN(10))).toString())

		let balance = await token.balanceOf(user);
		expect(balance.toString()).to.equal(toBN(9700).mul(BASE.div(toBN(10))).toString())
	});

});