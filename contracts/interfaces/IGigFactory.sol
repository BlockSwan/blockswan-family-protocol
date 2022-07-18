// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IGigFactory {
	function adminTax() external view returns (uint256);

	function owner() external view returns (address);

	function trialTax() external view returns (uint256);

	function judgeRetribution() external view returns (uint256);

	function affiliateRetribution() external view returns (uint256);

	function protocolRetribution() external view returns (uint256);

	function firstAffiliateFee() external view returns (uint256);

	function secondAffiliateFee() external view returns (uint256);

	function autoRefundDelay() external view returns (uint256);

	function endTrialDelay() external view returns (uint256);

	function emitStatusEvent(address _thisAddress, uint8 _status) external;

	function emitVoteAdded(
		address _address,
		address _voter,
		uint8 _vote
	) external;
}

