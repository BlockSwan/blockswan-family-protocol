// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IUserSoul {
	function getFirstInviter(address _user) external view returns (address);

	function isJudge(address _user) external view returns (bool);

	function isBan(address _user) external view returns (bool);

	function incrValidVotes(
		address _user,
		address _token,
		uint256 _amount
	) external;

	function onGigSuccess(address _buyer, address _seller) external;

	function onGigFail(address _buyer, address _seller) external;

	function onTrial(address _buyer, address _seller) external;

	function increaseInvitersBalance(
		address _buyer,
		address _seller,
		uint256 _amount,
		address _token
	) external;

	function decreaseUserJudgeWeight(address _user, address _token) external;

	function getInviterBalance(address _user, address _token)
		external
		view
		returns (uint256);

	function getUserWeight(address _user, address _token)
		external
		returns (uint256);
}
