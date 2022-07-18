const { expect } = require("chai");
const { ethers } = require("hardhat");
const { ONE_DAY } = require("../helpers/constants");
const { advanceBy } = require("../helpers/time");

describe("Fake USDC Unit Test", () => {
	let USDC, usdc, owner, user1;
	beforeEach(async () => {
		[owner, user1] = await ethers.getSigners();
		USDC = await ethers.getContractFactory("FakeUSDC");
		usdc = await USDC.deploy();
	});

	it("Should update the mint amount by owner", async () => {
		await usdc.updateMintAmount(100000000);
	});
	it("Should not mint if called during the 5 next minutes", async () => {
		await usdc.mint();
		await expect(usdc.mint()).to.be.revertedWith(
			"You must wait at least 5min between each mint"
		);
	});
});
