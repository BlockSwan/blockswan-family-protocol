const { ethers } = require("hardhat");
const { ONE_DAY } = require("./constants");
const { advanceBy } = require("./time");
const { expect } = require("chai");

async function deployProtocol({ signers, instances }) {
	let contracts = [];
	for (const signer of signers) {
	}

	return { contracts };
}

async function mintUSDCApproveFactory(signer, usdc, gigFactory) {
	usdc.connect(signer).mint();
	usdc.approve(gigFactory.address, 100000000000);
}

async function createGigAndCloseTrial(
	buyer,
	seller,
	usdc,
	gigFactory,
	GigImplementation,
	judges,
	userSoul
) {
	await mintUSDCApproveFactory(buyer, usdc, gigFactory);
	await gigFactory
		.connect(buyer)
		.createGig(usdc.address, seller.address, 50000000, "IPFSLINK");
	let x = await gigFactory.nbGigs();
	let newGigAddress = await gigFactory.getGig(x - 1);
	let newGig = GigImplementation.attach(newGigAddress);

	await newGig.connect(seller).acceptOrder();
	await newGig.connect(buyer).callTrial("NEWLOGS");
	for (const judge of judges) {
		await newGig.connect(judge).vote(Math.floor(Math.random() * 5));
	}
	await advanceBy(ONE_DAY * 3);
	await newGig.connect(buyer).endTrial();

	for (const judge of judges) {
		let balance = await userSoul.getUserWeight(judge.address, usdc.address);
		if (balance > 0) {
			await gigFactory.connect(judge).withdrawJudgeRevenues(usdc.address);
		} else {
			await expect(
				gigFactory.connect(judge).withdrawJudgeRevenues(usdc.address)
			).to.be.reverted;
		}
	}
}

module.exports = {
	mintUSDCApproveFactory,
	createGigAndCloseTrial,
};
