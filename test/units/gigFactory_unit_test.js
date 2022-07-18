const { getContractFactory } = require("@nomiclabs/hardhat-ethers/types");
const { expect } = require("chai");
const { ethers } = require("hardhat");
const { ONE_DAY, ONE_YEAR } = require("../helpers/constants");

describe("Gig Factory Unit Test", () => {
	let USDC,
		usdc,
		UserSoul,
		userSoul,
		GigFactory,
		gigFactory,
		GigV1,
		gigV1,
		Beacon,
		beacon;
	let owner, user1, user2, user3;
	let firstGig;

	beforeEach(async () => {
		[owner, user1, user2, user3] = await ethers.getSigners();
		USDC = await ethers.getContractFactory("FakeUSDC");
		UserSoul = await ethers.getContractFactory("UserSoul");
		GigV1 = await ethers.getContractFactory("GigV1");
		Beacon = await ethers.getContractFactory("GigBeacon");
		GigFactory = await ethers.getContractFactory("GigFactory");

		usdc = await USDC.deploy();
		userSoul = await UserSoul.deploy(owner.address);
		gigV1 = await GigV1.deploy();
		gigFactory = await GigFactory.deploy(gigV1.address, userSoul.address);

		await userSoul.setJudge(user2.address);
		await userSoul.setJudge(user3.address);
		await userSoul.changeGigFactory(gigFactory.address);
	});
	describe("Fee Management", () => {
		it("Should be able to change trial tax fee by owner", async () => {
			await gigFactory.changeTrialTax(10);
		});
		it("Should be able to change admin tax fee by owner", async () => {
			await gigFactory.changeAdminTax(10);
			expect(await gigFactory.adminTax()).to.equal(10);
		});
		it("Should not be able to set admin or trail tax higher then 10%", async () => {
			await expect(gigFactory.changeAdminTax(20)).to.be.reverted;
		});
		it("Should change the retribution model by owner", async () => {
			await gigFactory.changeRetributionModel(30, 30, 40);
		});
		it("Should not change the retribution model if not equal to 100", async () => {
			await expect(gigFactory.changeRetributionModel(100, 200, 300)).to.be
				.reverted;
		});
		it("Should not change the retribution model if protocol fee is lower then  20%", async () => {
			await expect(gigFactory?.changeRetributionModel(50, 40, 10)).to.be
				.reverted;
		});
		it("Should change the auto refund delay and end trial delay", async () => {
			await gigFactory.changeAutoRefundDelay(ONE_DAY * 5);
			expect(await gigFactory.autoRefundDelay()).to.equal(ONE_DAY * 5);
			await gigFactory.changeEndTrialDelay(ONE_DAY * 5);
		});
		it("Should not allow to set respectively autoRefund/trial delays to 7 and 14 days", async () => {
			await expect(gigFactory.changeEndTrialDelay(ONE_YEAR)).to.be.reverted;
			await expect(gigFactory.changeAutoRefundDelay(ONE_YEAR)).to.be.reverted;
		});
	});
	describe("Ownership & beacon management", () => {
		beforeEach(async () => {
			let beacon_address = await gigFactory.getBeacon();
			beacon = await Beacon.attach(beacon_address);
		});
		it("Should only change beacon ownership if called by owner", async () => {
			expect(await beacon.owner()).to.equal(owner.address);
			await expect(
				beacon.connect(user1).changeOwnership(user1.address)
			).to.be.revertedWith("Only for Owner");
			await beacon.changeOwnership(user1.address);
		});
		it("Should update implementation by owner", async () => {
			expect(await gigFactory.getImplementation()).to.equal(gigV1.address);
			let gigV2 = await GigV1.deploy();
			await beacon.update(gigV2.address);
		});
	});
	describe("User Soul management", () => {
		it("Should update user soul contract address by owner", async () => {
			let userSoul2 = await UserSoul.deploy(gigFactory.address);

			await gigFactory.changeUserSoulAddress(userSoul2.address);
			let newUserSoul = await gigFactory.userSoul();
			expect(newUserSoul).to.equal(userSoul2.address);
		});
	});
});
