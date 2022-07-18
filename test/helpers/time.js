const { ethers } = require("hardhat");

const { BigNumber } = ethers;

async function advanceBlock() {
	await ethers.provider.send("evm_mine");
}

async function advanceBy(_nbSec) {
	await ethers.provider.send("evm_increaseTime", [_nbSec]);
	await advanceBlock();
}

module.exports = {
	advanceBlock,
	advanceBy,
};
