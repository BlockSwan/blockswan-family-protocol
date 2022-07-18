const { expect } = require("chai");
const { ethers } = require("hardhat");
const { ONE_DAY, ONE_YEAR } = require("../helpers/constants");
const { advanceBy } = require("../helpers/time");
const {
	mintUSDCApproveFactory,
	createGigAndCloseTrial,
} = require("../helpers/actions");
const { getRandomSigners } = require("../helpers/utils");

describe("Gig Factory Integration Test", () => {
	let USDC, usdc, UserSoul, userSoul, GigFactory, gigFactory, GigV1, gigV1;
	let owner,
		user1,
		user2,
		user3,
		user4,
		user5,
		user6,
		user7,
		user8,
		user9,
		user10;
	let firstGig;

	beforeEach(async () => {
		[
			owner,
			user1,
			user2,
			user3,
			user4,
			user5,
			user6,
			user7,
			user8,
			user9,
			user10,
		] = await ethers.getSigners();
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
		await userSoul.changeGigFactory(gigFactory.address);
	});
	it("Should only be callable by a created gig", async () => {
		await expect(gigFactory.emitStatusEvent(user1.address, 5)).to.be.reverted;
	});
	it("Should not create a new gig if buyer or seller is ban", async () => {
		userSoul.setBan(user1.address);
		await expect(
			gigFactory.createGig(usdc.address, user1.address, 200, "METADATA")
		).to.be.reverted;
	});
	it("Should not create a gig if user balance < price", async () => {
		await expect(
			gigFactory.createGig(usdc.address, user1.address, 200, "METADATA")
		).to.be.reverted;
	});
	describe("Judge Withdrawal", () => {
		it("Should not withdraw if balance = 0", async () => {
			await expect(gigFactory.withdrawJudgeRevenues(usdc.address)).to.be
				.reverted;
		});
		it("Should allow user to withdraw there judge revenues", async () => {
			let voters = [
				user2,
				user3,
				user4,
				user5,
				user6,
				user7,
				user8,
				user9,
				user10,
			];
			for (const voter of voters) {
				await userSoul.setJudge(voter.address);
			}
			createGigAndCloseTrial(
				owner,
				user1,
				usdc,
				gigFactory,
				GigV1,
				voters,
				userSoul
			);
		});
	});
});
