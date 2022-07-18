// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "hardhat/console.sol";
import "./interfaces/IGigFactory.sol";
import "./interfaces/IUserSoul.sol";

contract GigV1 is Initializable {
	using SafeERC20 for IERC20;
	IERC20 private _paymentToken;
	IGigFactory private _gigFactory;
	IUserSoul private _userSoul;
	uint256 private _gigIndex;
	address private _buyer;
	address private _seller;
	string private _metadata;
	string private _logs;
	uint256 private _price;
	uint256 private _timeStamp;

	address[] private _voted0;
	address[] private _voted1;
	address[] private _voted2;
	address[] private _voted3;
	address[] private _voted4;

	mapping(address => bool) private hasVoted;

	enum GigState {
		UNCONFIRMED,
		CONFIRMED,
		TRIAL,
		DONE
	}

	GigState private _thisState;

	modifier unconfirmed() {
		require(_thisState == GigState.UNCONFIRMED);
		_;
	}
	modifier confirmed() {
		require(_thisState == GigState.CONFIRMED);
		_;
	}
	modifier trial() {
		require(_thisState == GigState.TRIAL);
		_;
	}
	modifier isBuyer() {
		require(msg.sender == _buyer);
		_;
	}
	modifier isSeller() {
		require(msg.sender == _seller);
		_;
	}
	modifier isActor() {
		require(msg.sender == _buyer || msg.sender == _seller);
		_;
	}

	modifier isAuthorized() {
		require(
			_userSoul.isJudge(msg.sender) == true ||
				msg.sender == _buyer ||
				msg.sender == _seller
		);
		_;
	}

	function initialize(
		IERC20 _newPaymentToken,
		address _newBuyer,
		address _newSeller,
		uint256 _newPrice,
		string memory _newMetadata,
		uint256 _newIndex,
		IUserSoul _newUserSoul
	) public initializer {
		_gigFactory = IGigFactory(msg.sender);
		_paymentToken = IERC20(_newPaymentToken);
		_userSoul = IUserSoul(_newUserSoul);
		_buyer = _newBuyer;
		_seller = _newSeller;
		_price = _newPrice;
		_metadata = _newMetadata;
		_timeStamp = block.timestamp;
		_thisState = GigState.UNCONFIRMED;
		_gigIndex = _newIndex;
	}

	function autoRefund() external unconfirmed isBuyer {
		require(block.timestamp >= _timeStamp + _gigFactory.autoRefundDelay());
		uint256 _amount = _paymentToken.balanceOf(address(this));
		_transfer(msg.sender, _amount);
		_thisState = GigState.DONE;
		_gigFactory.emitStatusEvent(address(this), 3);
	}

	function acceptOrder() external unconfirmed isSeller {
		_thisState = GigState.CONFIRMED;
		_gigFactory.emitStatusEvent(address(this), 1);
	}

	function sendAll() public confirmed isActor {
		address _other = msg.sender == _buyer ? _seller : _buyer;
		uint256 _contractBalance = _paymentToken.balanceOf(address(this));
		uint256 _tax = msg.sender == _buyer ? _gigFactory.adminTax() : 0;
		if (_tax > 0) {
			uint256 _taxValue = (_contractBalance * _tax) / 100;
			uint256 _valueToProtocol = (_taxValue *
				_gigFactory.protocolRetribution()) / 100;
			uint256 _valueToAffiliate = (_taxValue *
				_gigFactory.affiliateRetribution()) / 100;

			uint256 _valueToJudge = (_taxValue * _gigFactory.judgeRetribution()) /
				100;

			_userSoul.increaseInvitersBalance(
				_buyer,
				_seller,
				_valueToAffiliate,
				address(_paymentToken)
			);
			_userSoul.onGigSuccess(_buyer, _seller);
			_transfer(_gigFactory.owner(), _valueToProtocol);
			_transfer(address(_userSoul), _valueToAffiliate);
			_transfer(address(_gigFactory), _valueToJudge);
		} else {
			_userSoul.onGigFail(_buyer, _seller);
		}
		_transfer(_other, _paymentToken.balanceOf(address(this)));
		_thisState = GigState.DONE;
		_gigFactory.emitStatusEvent(address(this), 3);
	}

	function callTrial(string memory _newLogs) external confirmed isActor {
		_logs = _newLogs;
		_thisState = GigState.TRIAL;
		_timeStamp = block.timestamp + _gigFactory.endTrialDelay();
		_gigFactory.emitStatusEvent(address(this), 2);
		_userSoul.onTrial(_buyer, _seller);
		_userSoul.onGigFail(_buyer, _seller);
	}

	function vote(uint8 _vote) external trial {
		require(
			_userSoul.isJudge(msg.sender) &&
				!_userSoul.isBan(msg.sender) &&
				_vote <= 4 &&
				!hasVoted[msg.sender] &&
				msg.sender != _buyer &&
				msg.sender != _seller
		);
		hasVoted[msg.sender] = true;
		if (_vote == 0) {
			_voted0.push(msg.sender);
		} else if (_vote == 1) {
			_voted1.push(msg.sender);
		} else if (_vote == 2) {
			_voted2.push(msg.sender);
		} else if (_vote == 3) {
			_voted3.push(msg.sender);
		} else {
			_voted4.push(msg.sender);
		}
		_gigFactory.emitVoteAdded(address(this), msg.sender, _vote);
	}

	function endTrial() external isActor trial {
		require(block.timestamp >= _timeStamp);
		address[] memory voted0 = _voted0;
		address[] memory voted1 = _voted1;
		address[] memory voted2 = _voted2;
		address[] memory voted3 = _voted3;
		address[] memory voted4 = _voted4;
		uint256 _length0 = voted0.length;
		uint256 _length1 = voted1.length;
		uint256 _length2 = voted2.length;
		uint256 _length3 = voted3.length;
		uint256 _length4 = voted4.length;
		uint256 maxScore = _length0;
		address[] memory _winning = voted0;
		uint8 _buyerPercent;
		uint8 _sellerPercent = 100;

		if (_length1 >= maxScore) {
			maxScore = _length1;
			_winning = voted1;
			_buyerPercent = 25;
			_sellerPercent = 75;
		}
		if (_length2 >= maxScore) {
			maxScore = _length2;
			_buyerPercent = 50;
			_sellerPercent = 50;
			_winning = voted2;
		}
		if (_length3 > maxScore) {
			maxScore = _length3;
			_buyerPercent = 75;
			_sellerPercent = 25;
			_winning = voted3;
		}
		if (_length4 > maxScore) {
			maxScore = _length4;
			_buyerPercent = 100;
			_sellerPercent = 0;
			_winning = voted4;
		}
		_thisState = GigState.DONE;
		_gigFactory.emitStatusEvent(address(this), 3);
		_transferTrial(_buyerPercent, _sellerPercent, maxScore, _winning);
	}

	function _transferTrial(
		uint8 _buyerPercent,
		uint8 _sellerPercent,
		uint256 _maxScore,
		address[] memory _winning
	) private {
		uint256 _contractBalance = _paymentToken.balanceOf(address(this));
		uint256 _taxValue = (_contractBalance * _gigFactory.trialTax()) / 100;
		uint256 _valueToProtocol = (_taxValue * _gigFactory.protocolRetribution()) /
			100;
		uint256 _valueToAffiliate = (_taxValue *
			_gigFactory.affiliateRetribution()) / 100;

		uint256 _valueToJudge = (_taxValue * _gigFactory.judgeRetribution()) / 100;

		uint256 _valueToActors = _contractBalance - _taxValue;

		for (uint256 i = 0; i < _maxScore; i++) {
			_userSoul.incrValidVotes(
				_winning[i],
				address(_paymentToken),
				_valueToJudge / _maxScore
			);
		}

		_userSoul.increaseInvitersBalance(
			_buyer,
			_seller,
			_valueToAffiliate,
			address(_paymentToken)
		);
		_userSoul.onGigSuccess(_buyer, _seller);
		_transfer(_gigFactory.owner(), _valueToProtocol);
		_transfer(address(_userSoul), _valueToAffiliate);
		_transfer(address(_gigFactory), _valueToJudge);
		_transfer(_buyer, (_valueToActors * _buyerPercent) / 100);
		_transfer(_seller, (_valueToActors * _sellerPercent) / 100);
	}

	function paymentToken() external view returns (IERC20) {
		return _paymentToken;
	}

	function gigFactory() external view returns (IGigFactory) {
		return _gigFactory;
	}

	function userSoul() external view returns (IUserSoul) {
		return _userSoul;
	}

	function gigIndex() external view returns (uint256) {
		return _gigIndex;
	}

	function buyer() external view returns (address) {
		return _buyer;
	}

	function seller() external view returns (address) {
		return _seller;
	}

	function price() external view returns (uint256) {
		return _price;
	}

	function timestamp() external view returns (uint256) {
		return _timeStamp;
	}

	function metadata() external view isActor returns (string memory) {
		return _metadata;
	}

	function readTrialMetadata()
		external
		view
		isAuthorized
		trial
		returns (string memory)
	{
		return _metadata;
	}

	function readTrialLogs()
		external
		view
		isAuthorized
		trial
		returns (string memory)
	{
		return _logs;
	}

	function logs() external view isActor returns (string memory) {
		return _logs;
	}

	function state() external view returns (GigState) {
		return _thisState;
	}

	function _transfer(address _to, uint256 _amount) private {
		_paymentToken.safeTransfer(_to, _amount);
	}
}
