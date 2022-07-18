/**
 * @type import('hardhat/config').HardhatUserConfig
 */

require("@nomiclabs/hardhat-waffle");
require("hardhat-gas-reporter");
require("solidity-coverage");
const dotenv = require("dotenv");
dotenv.config();

const gasPriceApi = {
	eth: "https://api.etherscan.io/api?module=proxy&action=eth_gasPrice",
	bnb: "https://api.bscscan.com/api?module=proxy&action=eth_gasPrice",
	matic: "https://api.polygonscan.com/api?module=proxy&action=eth_gasPrice",
	avax: "https://api.snowtrace.io/api?module=proxy&action=eth_gasPrice",
};

module.exports = {
	solidity: "0.8.4",
	settings: {
		optimizer: {
			enabled: true,
			runs: 200,
		},
	},
	gasReporter: {
		enabled: process.env.GAS_REPORTER_ENABLED,
		noColors: false,
		currency: "USD",
		coinmarketcap: process.env.COINMARKETCAP_API_KEY,
		token: "MATIC",
		gasPriceApi: gasPriceApi.matic,
		showTimeSpent: false,
	},
};
