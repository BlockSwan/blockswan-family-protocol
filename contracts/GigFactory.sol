// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./GigV1.sol";

contract GigBeacon {
	UpgradeableBeacon immutable beacon;

	address public vLogic;
	address private _owner;

	modifier onlyOwner() {
		require(msg.sender == owner(), "Only for Owner");
		_;
	}

	constructor(address _vLogic, address _newOwner) {
		beacon = new UpgradeableBeacon(_vLogic);
		vLogic = _vLogic;
		_owner = _newOwner;
	}

	function changeOwnership(address _newOwner) public onlyOwner {
		_owner = _newOwner;
	}

	function update(address _vLogic) public onlyOwner {
		beacon.upgradeTo(_vLogic);
		vLogic = _vLogic;
	}

	function implementation() public view returns (address) {
		return beacon.implementation();
	}

	function owner() public view returns (address) {
		return _owner;
	}
}

contract GigFactory is Ownable {
	using SafeERC20 for IERC20;
	IUserSoul private _userSoul;

	uint256 private _autoRefundDelay = 3 * 24 * 60 * 60;
	uint256 private _endTrialDelay = 3 * 24 * 60 * 60; 
	uint256 private _adminTax = 4; // %
	uint256 private _trialTax = 9; // %

	uint256 private _judgeRetribution = 35; // %
	uint256 private _affiliateRetribution = 5; // %
	uint256 private _protocolRetribution = 60; // %

	uint256 private _firstAffiliateFee = 67; // %
	uint256 private _secondAffiliateFee = 33; // %

	mapping(uint256 => address) private _gigs;
	mapping(address => bool) private _isGig;
	uint256 private _nbGigs;

	GigBeacon immutable beacon;

	event JudgeWidthdrawal(address _user, uint256 _amount);
	event GigStatusChange(address _address, uint8 _status);
	event GigVoteAdded(address _address, address _voter, uint8 _vote);
	event GigCreated(address _gigAddress, address _buyer, address _seller);

	modifier taxController(uint256 _newFee) {
		require(_newFee <= 10, "Fee can't be set as high");
		_;
	}

	modifier isGig() {
		require(_isGig[msg.sender], "Must be call by a gig contract");
		_;
	}

	constructor(address _vLogic, address _newUserSoul) {
		beacon = new GigBeacon(_vLogic, owner());
		_userSoul = IUserSoul(_newUserSoul);
	}

	function withdrawJudgeRevenues(address _token) public {
		uint256 _amount = _userSoul.getUserWeight(msg.sender, _token);
		require(_amount > 0, "Can't withdraw 0");
		IERC20 payWith = IERC20(_token);
		_userSoul.decreaseUserJudgeWeight(msg.sender, _token);
		payWith.safeTransfer(msg.sender, _amount);
	}

	function changeAdminTax(uint256 _newFee)
		public
		taxController(_newFee)
		onlyOwner
	{
		_adminTax = _newFee;
	}

	function changeTrialTax(uint256 _newFee)
		public
		taxController(_newFee)
		onlyOwner
	{
		_trialTax = _newFee;
	}

	function changeRetributionModel(
		uint256 _newJudgeRetribution,
		uint256 _newAffiliateRetribution,
		uint256 _newProtocolRetribution
	) public onlyOwner {
		require(_newProtocolRetribution >= 20, "Retribution can't be set as high");
		require(
			_newJudgeRetribution +
				_newAffiliateRetribution +
				_newProtocolRetribution ==
				100,
			"Reetirbution must be equal to 100%"
		);
		_judgeRetribution = _newJudgeRetribution;
		_affiliateRetribution = _newAffiliateRetribution;
		_protocolRetribution = _newProtocolRetribution;
	}

	function changeAutoRefundDelay(uint256 _newDayDelay) public onlyOwner {
		require(_newDayDelay <= 604800, "Auto refund Delay can't be as high");
		_autoRefundDelay = _newDayDelay;
	}

	function changeEndTrialDelay(uint256 _newDayDelay) public onlyOwner {
		require(_newDayDelay <= 1209600, "End Trial Delay can't be as high");
		_endTrialDelay = _newDayDelay;
	}

	function createGig(
		IERC20 _token,
		address _seller,
		uint256 _price,
		string memory _metadata
	) external returns (address) {
		IERC20 _paymentToken = IERC20(_token);
		require(
			!_userSoul.isBan(_seller) && !_userSoul.isBan(msg.sender),
			"Buyer or seller should not be ban"
		);

		require(
			_paymentToken.balanceOf(msg.sender) >= _price,
			"User don't have enough money"
		);
		BeaconProxy proxy = new BeaconProxy(
			address(beacon),
			abi.encodeWithSelector(
				GigV1(address(0)).initialize.selector,
				_token,
				msg.sender,
				_seller,
				_price,
				_metadata,
				_nbGigs,
				address(_userSoul)
			)
		);

		_gigs[_nbGigs] = address(proxy);
		_isGig[address(proxy)] = true;
		_nbGigs++;
		_paymentToken.safeTransferFrom(msg.sender, address(proxy), _price);

		emit GigCreated(address(proxy), msg.sender, _seller);
		return address(proxy);
	}

	function emitStatusEvent(address _address, uint8 _status) external isGig {
		emit GigStatusChange(_address, _status);
	}

	function emitVoteAdded(
		address _address,
		address _voter,
		uint8 _vote
	) external isGig {
		emit GigVoteAdded(_address, _voter, _vote);
	}

	function changeUserSoulAddress(address _newUserSoul) public onlyOwner {
		_userSoul = IUserSoul(_newUserSoul);
	}

	function nbGigs() public view returns (uint256) {
		return _nbGigs;
	}

	function userSoul() public view returns (address) {
		return address(_userSoul);
	}

	function getImplementation() public view returns (address) {
		return beacon.implementation();
	}

	function getBeacon() public view returns (address) {
		return address(beacon);
	}

	function getGig(uint256 _x) public view returns (address) {
		return _gigs[_x];
	}

	function adminTax() external view returns (uint256) {
		return _adminTax;
	}

	function trialTax() external view returns (uint256) {
		return _trialTax;
	}

	function judgeRetribution() external view returns (uint256) {
		return _judgeRetribution;
	}

	function affiliateRetribution() external view returns (uint256) {
		return _affiliateRetribution;
	}

	function protocolRetribution() external view returns (uint256) {
		return _protocolRetribution;
	}

	function firstAffiliateFee() external view returns (uint256) {
		return _firstAffiliateFee;
	}

	function secondAffiliateFee() external view returns (uint256) {
		return _secondAffiliateFee;
	}

	function endTrialDelay() external view returns (uint256) {
		return _endTrialDelay;
	}

	function autoRefundDelay() external view returns (uint256) {
		return _autoRefundDelay;
	}

	function isFromGigFactory(address _address) external view returns (bool) {
		return _isGig[_address];
	}
}
