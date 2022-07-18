const { expect } = require("chai");
const { ethers } = require("hardhat");
const { ONE_DAY, ONE_YEAR } = require("../helpers/constants");
const { advanceBy } = require("../helpers/time");
const {
	mintUSDCApproveFactory,
	createGigAndCloseTrial,
} = require("../helpers/actions");

describe("User Soul Integration Test", () => {
	let USDC, usdc, UserSoul, userSoul, GigFactory, gigFactory, GigV1, gigV1;
	let owner, user1, user2, user3, user4;
	let firstGig;

	beforeEach(async () => {
		[owner, user1, user2, user3, user4] = await ethers.getSigners();
		USDC = await ethers.getContractFactory("FakeUSDC");
		UserSoul = await ethers.getContractFactory("UserSoul");
		GigV1 = await ethers.getContractFactory("GigV1");
		GigFactory = await ethers.getContractFactory("GigFactory");

		usdc = await USDC.deploy();
		userSoul = await UserSoul.deploy(owner.address);
		gigV1 = await GigV1.deploy();
		gigFactory = await GigFactory.deploy(gigV1.address, userSoul.address);

		await userSoul.setJudge(user2.address);
		await userSoul.setJudge(user3.address);
		await userSoul.setJudge(user4.address);
		await userSoul.changeGigFactory(gigFactory.address);
	});
	it("Inviters should be able to withdraw if balance token balance >0", async () => {
		await createGigAndCloseTrial(
			owner,
			user1,
			usdc,
			gigFactory,
			GigV1,
			[user2, user3],
			userSoul
		);
		let balance = await userSoul.getInviterBalance(owner.address, usdc.address);
		if (balance === 0) {
		  await expect(userSoul.withdrawInviterRevenues(usdc.address)).to.be
				.reverted;
		} else {
			await userSoul.withdrawInviterRevenues(usdc.address);
		}
	});
	it("Should retribute the proper inviters", async () => {
		await userSoul.connect(owner).mint("Oscar", user2.address);
		await userSoul.connect(user1).mint("Quentin", user3.address);
		await createGigAndCloseTrial(
			owner,
			user1,
			usdc,
			gigFactory,
			GigV1,
			[user4, user3],
			userSoul
		);
	});
});
