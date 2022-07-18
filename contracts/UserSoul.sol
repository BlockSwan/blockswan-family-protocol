// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "hardhat/console.sol";

interface IGigFactory {
	function isFromGigFactory(address _caller) external view returns (bool);

	function firstAffiliateFee() external view returns (uint256);

	function secondAffiliateFee() external view returns (uint256);
}

contract UserSoul is Ownable {
	using SafeERC20 for IERC20;
	IGigFactory private _gigFactory;

	struct User {
		string identity;
		mapping(address => uint256) inviterBalance;
		mapping(address => uint256) judgeWeight;
		address[2] inviters;
		uint16 validVotes;
		uint16 successSell;
		uint16 successBuy;
		uint16 failBuy;
		uint16 failSell;
		uint16 toTrial;
		bool isJudge;
		bool isBan;
	}

	mapping(address => User) private users;

	/// @dev returns true if smart-contract.
	bytes32 private zeroHash =
		0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
	uint256 private _balanceWeight;
	uint256 private _totalValidVotes;

	event Mint(address _user, address _inviter0, address _inviter1);
	event Burn(address _user);
	event Judge(address _user, bool isJudge);
	event Ban(address _user, bool isBan);
	event InviterWithdrawal(address _user, uint256 _amount, address _token);
	event InvitersIncrease(
		address _firstBuyerSeller,
		address _secondBuyerInviter,
		address _firstSellerInviter,
		address _secondSellerInviter,
		uint256 _amount,
		address _token
	);

	constructor(address _newGigFactory) {
		_gigFactory = IGigFactory(_newGigFactory);
	}

	modifier fromFactory() {
		require(msg.sender == address(_gigFactory));
		_;
	}

	modifier fromGig() {
		require(_gigFactory.isFromGigFactory(msg.sender));
		_;
	}

	function changeGigFactory(address _newFacto) public onlyOwner {
		_gigFactory = IGigFactory(_newFacto);
	}

	function withdrawInviterRevenues(address _token) public {
		uint256 _amount = users[msg.sender].inviterBalance[_token];
		require(_amount > 0);
		users[msg.sender].inviterBalance[_token] = 0;
		IERC20 _paymentToken = IERC20(_token);
		_paymentToken.safeTransfer(msg.sender, _amount);
		emit InviterWithdrawal(msg.sender, _amount, _token);
	}

	function mint(string memory _identity, address _inviter) external {
		require(!hasSoul(msg.sender) && _inviter != msg.sender);
		_inviter = isZeroAddress(_inviter) ? owner() : _inviter;
		address _secondInviter = users[_inviter].inviters[0];
		_secondInviter = isZeroAddress(_secondInviter) ? owner() : _secondInviter;
		users[msg.sender].identity = _identity;
		users[msg.sender].inviters[0] = _inviter;
		users[msg.sender].inviters[1] = _secondInviter;
		emit Mint(msg.sender, _inviter, _secondInviter);
	}

	function burn() external {
		require(hasSoul(msg.sender));
		delete users[msg.sender];
		emit Burn(msg.sender);
	}

	function setJudge(address _user) external onlyOwner {
		bool judgeStatus = users[_user].isJudge;
		users[_user].isJudge = !judgeStatus;
		emit Judge(_user, !judgeStatus);
	}

	function setBan(address _user) external onlyOwner {
		bool banStatus = users[_user].isBan;
		users[_user].isBan = !banStatus;
		emit Ban(_user, !banStatus);
	}

	function incrValidVotes(
		address _user,
		address _token,
		uint256 _amount
	) external fromGig {
		users[_user].judgeWeight[_token] += _amount;
	}

	function decreaseUserJudgeWeight(address _user, address _token)
		external
		fromFactory
	{
		users[_user].judgeWeight[_token] = 0;
	}

	function onGigSuccess(address _buyer, address _seller) external fromGig {
		users[_buyer].successBuy += 1;
		users[_seller].successSell += 1;
	}

	function onGigFail(address _buyer, address _seller) external fromGig {
		users[_buyer].failBuy += 1;
		users[_seller].failSell += 1;
	}

	function onTrial(address _buyer, address _seller) external fromGig {
		users[_buyer].toTrial += 1;
		users[_seller].toTrial += 1;
	}

	function increaseInvitersBalance(
		address _buyer,
		address _seller,
		uint256 _amount,
		address _token
	) external fromGig {
		address _firstBuyerInviter = getFirstInviter(_buyer);
		address _secondBuyerInviter = getSecondInviter(_buyer);

		if (isZeroAddress(_firstBuyerInviter)) {
			_firstBuyerInviter = owner();
			_secondBuyerInviter = owner();
		}
		address _firstSellerInviter = getFirstInviter(_seller);
		address _secondSellerInviter = getSecondInviter(_seller);

		if (isZeroAddress(_firstSellerInviter)) {
			_firstSellerInviter = owner();
			_secondSellerInviter = owner();
		}
		uint256 _firstValue = (_amount * _gigFactory.firstAffiliateFee()) / 100 / 2;
		uint256 _secondValue = (_amount * _gigFactory.secondAffiliateFee()) /
			100 /
			2;
		users[_firstBuyerInviter].inviterBalance[_token] += _firstValue;
		users[_secondBuyerInviter].inviterBalance[_token] += _secondValue;
		users[_firstSellerInviter].inviterBalance[_token] += _firstValue;
		users[_secondSellerInviter].inviterBalance[_token] += _secondValue;
		emit InvitersIncrease(
			_firstBuyerInviter,
			_secondBuyerInviter,
			_firstSellerInviter,
			_secondSellerInviter,
			_amount,
			_token
		);
	}

	function changeIdentity(string memory _newIdentity) external {
		require(hasSoul(msg.sender));
		users[msg.sender].identity = _newIdentity;
	}

	function getUser(address _user)
		public
		view
		returns (
			uint16,
			uint16,
			uint16,
			uint16,
			uint16,
			uint16
		)
	{
		return (
			users[_user].validVotes,
			users[_user].successSell,
			users[_user].successBuy,
			users[_user].failBuy,
			users[_user].failSell,
			users[_user].toTrial
		);
	}

	function hasSoul(address _user) public view returns (bool) {
		if (keccak256(bytes(users[_user].identity)) == zeroHash) {
			return false;
		} else {
			return true;
		}
	}

	function isJudge(address _user) external view returns (bool) {
		return (users[_user].isJudge);
	}

	function isBan(address _user) external view returns (bool) {
		return (users[_user].isBan);
	}

	function getFirstInviter(address _user) public view returns (address) {
		return (users[_user].inviters[0]);
	}

	function getSecondInviter(address _user) public view returns (address) {
		return (users[_user].inviters[1]);
	}

	function getUserWeight(address _user, address _token)
		public
		view
		returns (uint256)
	{
		return (users[_user].judgeWeight[_token]);
	}

	function getInviterBalance(address _user, address _token)
		public
		view
		returns (uint256)
	{
		return (users[_user].inviterBalance[_token]);
	}

	function gigFactory() public view returns (address) {
		return address(_gigFactory);
	}

	function balanceWeight() public view returns (uint256) {
		return _balanceWeight;
	}

	function totalValidVotes() public view returns (uint256) {
		return _totalValidVotes;
	}

	function getUserIdentity(address _user) public view returns (string memory) {
		return users[_user].identity;
	}

	function isZeroAddress(address _input) public pure returns (bool) {
		return _input == address(0x0000000000000000000000000000000000000000);
	}
}
