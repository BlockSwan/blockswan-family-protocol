const { ethers } = require("hardhat");
const getRandomSigners = (amount) => {
	const signers = [];
	for (let i = 0; i < amount; i++) {
		signers.push(ethers.Wallet.createRandom());
	}
	return signers;
};

module.exports = {
	getRandomSigners,
};
