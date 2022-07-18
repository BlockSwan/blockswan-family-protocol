const { expect } = require("chai");
const { ethers } = require("hardhat");
const { ONE_DAY, ONE_YEAR } = require("../helpers/constants");
const { advanceBy } = require("../helpers/time");
const { getRandomSigners } = require("../helpers/utils");

describe("GigV1 Unit Test", () => {
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
	let x;
	async function createGig() {
		await usdc.mint();
		await advanceBy(3600);

		await usdc.approve(gigFactory.address, 1000000000);

		await gigFactory.createGig(
			usdc.address,
			user1.address,
			10000000,
			"IPFSLINK"
		);
		let add = await gigFactory.getGig(x);
		x++;
		firstGig = GigV1.attach(add);
	}

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
		await userSoul.changeGigFactory(gigFactory.address);
		x = 0;

		await createGig();
		await userSoul.setJudge(user2.address);
		await userSoul.setJudge(user3.address);
	});
	describe("Deployment", () => {
		it("Should have the right buyer, seller and price", async () => {
			let buyer, seller, price;
			buyer = await firstGig.buyer();
			seller = await firstGig.seller();
			price = await firstGig.price();
			expect(buyer).to.equal(owner.address);
			expect(seller).to.equal(user1.address);
			expect(price).to.equal(10000000);
		});
		it("Should have the appropriate token, usersoul, and timestamp", async () => {
			let token = await firstGig.paymentToken();
			expect(token).to.equal(usdc.address);
			let soul = await firstGig.userSoul();
			expect(soul).to.equal(userSoul.address);
			await firstGig.timestamp();
		});
		it("Should have the  correct factory and index", async () => {
			expect(await firstGig.gigFactory()).to.equal(gigFactory.address);
			let _x = await firstGig.gigIndex();
			expect(await gigFactory.getGig(_x)).to.equal(firstGig.address);
		});
		it("Should returns the logs and metadata", async () => {
			await firstGig.metadata();
			await firstGig.logs();
		});
	});
	describe("Resctrictions", () => {
		it("Only seller should be able to accept orders", async () => {
			await expect(firstGig.acceptOrder()).to.be.reverted;
		});
		it("Only buyer should auto-refund if gig is unconfirmed and after refund delay", async () => {
			await expect(firstGig.connect(user3).autoRefund()).to.be.reverted;
			advanceBy(ONE_DAY * 3);

			await firstGig.autoRefund();
			await createGig();
			await firstGig.connect(user1).acceptOrder();

			await expect(firstGig.autoRefund()).to.be.reverted;
			await createGig();
			await expect(firstGig.autoRefund()).to.be.reverted;
		});
	});
	describe("Paying Actors", () => {
		it("Should only pay user if called by actors", async () => {
			await expect(firstGig.connect(user3).sendAll()).to.be.reverted;
		});
		it("Should send All only if transaction state is confirmed", async () => {
			await expect(firstGig.callTrial("NEWLOGS")).to.be.reverted;
			await expect(firstGig.sendAll()).to.be.reverted;
		});
		it("Should refund the buyer", async () => {
			await firstGig.connect(user1).acceptOrder();
			await firstGig.connect(user1).sendAll();
		});
		it("Should pay the seller", async () => {
			await firstGig.connect(user1).acceptOrder();
			await firstGig.sendAll();
		});
	});
	describe("Trial", () => {
		describe("Trial Logs and metadata", () => {
			it("Should not return the logs if not actor", async () => {
				await expect(firstGig.connect(user3).logs()).to.be.reverted;
			});
			it("Should read trial metadata  and logs only if state is trial", async () => {
				await firstGig.connect(user1).acceptOrder();
				await expect(firstGig.connect(user3).readTrialMetadata()).to.be
					.reverted;
				await firstGig.callTrial("NewLogs");
				await firstGig.connect(user3).readTrialMetadata();

				await firstGig.connect(user3).readTrialLogs();
				await expect(firstGig.connect(user4).readTrialLogs()).to.be.reverted;
			});
			it("Should not endTrial if timeblock less then trial delay", async () => {
				await firstGig.connect(user1).acceptOrder();
				await firstGig.callTrial("NEWLOGS");
				await advanceBy(ONE_DAY);
				await expect(firstGig.endTrial()).to.be.reverted;
			});
		});
		describe("Conflict Resolution", () => {
			let voters = [];
			async function voteWith(_vote, voters) {
				for (const voter of voters) {
					await firstGig.connect(voter).vote(_vote);
				}
				await advanceBy(ONE_DAY * 3);
				await firstGig.endTrial();
				let state = await firstGig.state();
				expect(state).to.equal(3);

				for (const voter of voters) {
					await gigFactory.connect(voter).withdrawJudgeRevenues(usdc.address);
				}
			}

			beforeEach(async () => {
				voters = [user5, user6, user7, user8, user9, user10];

				await firstGig.connect(user1).acceptOrder();
				for (const voter of voters) {
					await userSoul.setJudge(voter.address);
				}
				await firstGig.callTrial("NEWLOGS");
			});
			it("0% buyers | 100% seller", async () => {
				await voteWith(0, voters);
			});
			it("25% buyers | 75% seller", async () => {
				await voteWith(1, voters);
			});
			it("50% buyers | 50% seller", async () => {
				await voteWith(2, voters);
			});
			it("75% buyers | 25% seller", async () => {
				await voteWith(3, voters);
			});
			it("100% buyers | 0% seller", async () => {
				await voteWith(4, voters);
			});
		});
	});
});
