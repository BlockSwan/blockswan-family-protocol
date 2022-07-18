const { expect } = require("chai");
const { ethers } = require("hardhat");
const { ZERO_ADDRESS } = require("../helpers/constants");

describe("User Soul Unit Test", () => {
	let USDC, usdc, UserSoul, userSoul, owner, user1, user2, user3;
	let ticker, name, soulOwner, gigFactory, paymentToken;
	let soul0, soul1, soul2;

	beforeEach(async () => {
		[owner, user1, user2, user3] = await ethers.getSigners();
		USDC = await ethers.getContractFactory("FakeUSDC");
		usdc = await USDC.deploy();
		UserSoul = await ethers.getContractFactory("UserSoul");

		userSoul = await UserSoul.deploy(owner.address);
		soulOwner = await userSoul.owner();
		gigFactory = await userSoul.gigFactory();

		await userSoul.connect(owner).mint("BlockSwan", ZERO_ADDRESS);
		await userSoul.connect(user1).mint("Oscar", owner.address);
		await userSoul.connect(user2).mint("Quentin", user1.address);

		soul0 = {
			identity: await userSoul.getUserIdentity(owner.address),
			firstInviter: await userSoul.getFirstInviter(owner.address),
			secondInviter: await userSoul.getSecondInviter(owner.address),
		};
		soul1 = {
			identity: await userSoul.getUserIdentity(user1.address),
			firstInviter: await userSoul.getFirstInviter(user1.address),
			secondInviter: await userSoul.getSecondInviter(user1.address),
		};

		soul2 = {
			identity: await userSoul.getUserIdentity(user2.address),
			firstInviter: await userSoul.getFirstInviter(user2.address),
			secondInviter: await userSoul.getSecondInviter(user2.address),
		};
	});

	describe("Deployment", () => {
		it("Should set owner to deployer address", async () => {
			expect(soulOwner).to.equal(owner.address);
		});
		it("Should set the gigFactory address", async () => {
			expect(gigFactory).to.equal(owner.address);
		});
		it("Should have the correct guetters", async () => {
			let totalValidVotes = await userSoul.totalValidVotes();
			expect(totalValidVotes).to.equal(0);
			let balanceWeight = await userSoul.balanceWeight();

			expect(balanceWeight).to.equal(0);
			let userBalance = await userSoul.getInviterBalance(
				owner.address,
				usdc.address
			);
			expect(userBalance).to.equal(0);
		});
	});
	describe("Management", () => {
		it("Owner should be able to modify the Gig Factory address", async () => {
			await userSoul.changeGigFactory(user1.address);
			let newGigFactoryAddress = await userSoul.gigFactory();
			expect(newGigFactoryAddress).to.equal(user1.address);
		});
		it("Other users should not modify the Gig Factory address", async () => {
			await expect(userSoul.connect(user1).changeGigFactory(user2.address)).to
				.be.reverted;
		});
	});
	describe("Mints", () => {
		it("Should not mint if already minted", async () => {
			await expect(userSoul.connect(user1).mint("Michel", owner.address)).to.be
				.reverted;

			let hasSoul = await userSoul.hasSoul(owner.address);
			expect(hasSoul).to.equal(true);
			hasSoul = await userSoul.hasSoul(user3.address);
			expect(hasSoul).to.equal(false);
			[validVotes, successSell, successBuy, failBuy, failSell, toTrial] =
				await userSoul.getUser(owner.address);
			expect([
				validVotes,
				successSell,
				successBuy,
				failBuy,
				failSell,
				toTrial,
			]).to.eql([0, 0, 0, 0, 0, 0]);
		});
		it("Should not mint if inviter is minter", async () => {
			await expect(userSoul.connect(user3).mint("Michel", user3.address)).to.be
				.reverted;
		});
		it("Should set inviters 1 and 2 to owner", async () => {
			expect(soul0.identity).to.equal("BlockSwan");
			expect(soul0.firstInviter).to.equal(owner.address);
			expect(soul0.secondInviter).to.equal(owner.address);
		});
		it("Should set inviters 1 and 2 respectively to inviter and owner", async () => {
			expect(soul1.firstInviter).to.equal(owner.address);
			expect(soul1.secondInviter).to.equal(owner.address);
			expect(soul2.firstInviter).to.equal(user1.address);
			expect(soul2.secondInviter).to.equal(owner.address);
		});
		it("Should set inviters 1 and 2 respectively to user2 and user1", async () => {
			await userSoul.connect(user3).mint("Gonzague", user2.address);
			expect(await userSoul.getFirstInviter(user3.address)).to.equal(
				user2.address
			);
			expect(await userSoul.getSecondInviter(user3.address)).to.equal(
				user1.address
			);
		});
	});

	describe("Burn", () => {
		it("Should not burn if not minted previously", async () => {
			await expect(userSoul.connect(user3).burn()).to.be.reverted;
		});
		it("Should burn, decrease the balance weight and delete user soul", async () => {
			await userSoul.burn();
			identity = await userSoul.getUserIdentity(owner.address);
			expect(identity).to.equal("");
			balanceWeight = await userSoul.balanceWeight();
			expect(balanceWeight).to.equal(0);
			hasSoul = await userSoul.hasSoul(owner.address);
			expect(hasSoul).to.equal(false);
		});
	});
	describe("Update", () => {
		it("Only owner should be able to set user as judge", async () => {
			isJudge = await userSoul.isJudge(user1.address);

			expect(isJudge).to.equal(false);
			await userSoul.setJudge(user1.address);
			isJudge = await userSoul.isJudge(user1.address);
			expect(isJudge).to.equal(true);

			await userSoul.setJudge(user1.address);
			isJudge = await userSoul.isJudge(user1.address);
			expect(isJudge).to.equal(false);
			await expect(userSoul.connect(user1).setJudge(user1.address)).to.be
				.reverted;
		});
		it("Only owner should be able to set user as ban", async () => {
			isBan = await userSoul.isBan(user1.address);

			expect(isBan).to.equal(false);
			await userSoul.setBan(user1.address);
			isBan = await userSoul.isBan(user1.address);
			expect(isBan).to.equal(true);

			await userSoul.setBan(user1.address);
			isBan = await userSoul.isBan(user1.address);
			expect(isBan).to.equal(false);
			await expect(userSoul.connect(user1).setBan(user1.address)).to.be
				.reverted;
		});
		it("Only Gig contracts can update balances and judge weight", async () => {
			await expect(userSoul.onTrial(owner.address, user1.address)).to.be
				.reverted;
			await expect(userSoul.incrValidVotes(owner.address)).to.be.reverted;
		});

		it("Only factory can decrease user judge weight", async () => {
			await expect(
				userSoul
					.connect(user1)
					.decreaseUserJudgeWeight(user2.address, usdc.address)
			).to.be.reverted;
			await userSoul.decreaseUserJudgeWeight(user1.address, usdc.address);
			expect(
				await userSoul.getUserWeight(user1.address, usdc.address)
			).to.equal(0);
		});
		it("Should modify identity if user has a soul", async () => {
			await userSoul.changeIdentity("Oscar");
			newIdentity = await userSoul.getUserIdentity(owner.address);
			expect(newIdentity).to.equal("Oscar");
			await expect(userSoul.connect(user3).changeIdentity("NEW")).to.be
				.reverted;
		});
	});
	describe("Withdrawal", () => {
		it("Should not allow user to withdraw if balance < 0", async () => {
			await expect(userSoul.withdrawInviterRevenues(usdc.address)).to.be
				.reverted;
		});
	});
	describe("Events", () => {
		it("Should emit a Mint", async () => {
			await expect(userSoul.connect(user3).mint("oscar", ZERO_ADDRESS))
				.to.emit(userSoul, "Mint")
				.withArgs(user3.address, owner.address, owner.address);
		});
		it("Should emit a Burn", async () => {
			await expect(userSoul.connect(user2).burn())
				.to.emit(userSoul, "Burn")
				.withArgs(user2.address);
		});
		it("Should emit a Judge", async () => {
			await expect(userSoul.setJudge(user2.address))
				.to.emit(userSoul, "Judge")
				.withArgs(user2.address, true);
		});
		it("Should emit a Ban", async () => {
			await expect(userSoul.setBan(user2.address))
				.to.emit(userSoul, "Ban")
				.withArgs(user2.address, true);
		});
	});
});
