// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FakeUSDC is ERC20, Ownable {
	constructor() ERC20("FakeUSDC", "fUSDC") {}

	uint256 amountTomint = 50 * 10**6;
	mapping(address => uint256) locktime;

	function updateMintAmount(uint256 _amount) public onlyOwner {
		amountTomint = _amount;
	}

	function mint() public {
		require(
			block.timestamp >= locktime[msg.sender],
			"You must wait at least 5min between each mint"
		);
		locktime[msg.sender] = block.timestamp + 5 minutes;
		_mint(msg.sender, amountTomint);
	}
}
