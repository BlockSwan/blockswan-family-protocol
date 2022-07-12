// SPDX-License-Identifier: GPL-3.0
///@author Quant11111

pragma solidity >=0.7.0 <0.9.0;

import "./Adminable.sol";
import "./USDCoin.sol";

interface Facto {
    function incrVotes(address _user) external;
    function incrValidVotes(address _user) external;
    function isJudge(address _user) external view returns(bool);
}

contract Escrow is Adminable, USDCoin {
    event status(address indexed _thisAddress, TransactionState _thisState);
    enum TransactionState{ UNCONFIRMED, CONFIRMED, TRIAL}
    

    //variables :
    TransactionState thisState = TransactionState.UNCONFIRMED;
    Facto public factory ;
    address  public buyer ;
    address  public seller ;
    uint[] public weiPrices ; //prices array (one price per milestone)
    uint8 adminTaxes = 4; //fees in % if function called by user
    uint8 trialTaxes = 5; //fees in % if function called by admin
    uint TimeStamp ;

    uint8[5] public trialVotes; //array storing the votes for trial
    address[] voted0;
    address[] voted1;
    address[] voted2;
    address[] voted3;
    address[] voted4;


    mapping(address=>bool) private hasVoted;

    ///@dev modifiers
    modifier unconfirmed{
        require(thisState == TransactionState.UNCONFIRMED);
        _;
    }
    modifier confirmed{
        require(thisState == TransactionState.CONFIRMED);
        _;
    }
    modifier trial{
        require(thisState == TransactionState.TRIAL);
        _;
    }
    modifier isBuyer{
        require(msg.sender == buyer);
        _;
    }
    modifier isSeller{
        require(msg.sender == seller);
        _;
    }
    modifier isActor{
        require(msg.sender == buyer || msg.sender == seller);
        _;
    }
    

    constructor(address  _buyer, address  _seller, uint[] memory _weiPrices){   
        factory = Facto(msg.sender);
        weiPrices = _weiPrices;
        buyer = _buyer ; 
        seller = _seller ; 
        TimeStamp = block.timestamp;
    }

    ///@notice functions callable during unconfirmed period only (State == UNCONFIRMED)//////////////////////////////////////////////////////////////////////

    ///@notice can autoRefund if no confirmation for 2 days

    function autoRefund() external unconfirmed isBuyer{
        require(block.timestamp >= TimeStamp + 172800); //3days = 259200sec // 2days = 172800
        uint _amount = USDc.balanceOf(address(this));
        USDc.transfer(msg.sender, _amount);
    } 

    ///@notice seller accept order and moove the state to CONFIRMED
    function acceptOrder() external unconfirmed isSeller{
        thisState = TransactionState.CONFIRMED;
    }

    ///@notice seller decline order and destruct contract transfering the total balance to buyer as a refund
    ///nb this function wont be likely used because it ll only coste to the seller for no reason..
    /*
    function rejectOrder() external unconfirmed isSeller{
    }
    */


    ///@notice functions callable during Confirmed period only (State == CONFIRMED)//////////////////////////////////////////////////////////////////////

    ///@notice the buyer unlock the payment number "_index"
    ///@dev  1rst milestone index = 0
    function unlockMilestone(uint _index) external confirmed isBuyer{
        USDc.transfer(seller, weiPrices[_index]);
        weiPrices[_index] = 0;
    }
    ///@notice the buyer unlock the remaining milestones
    function unlockAll() public confirmed isBuyer{
        uint _amount;
        for ( uint i = 0 ; i < weiPrices.length ; i++){
            _amount += weiPrices[i];
            weiPrices[i] = 0;
        }
        USDc.transfer(seller, _amount);
    } 

    ///@notice the seller refund the payment number "_index"  !! 1rst milestone index = 0
    function refundMilestone(uint _index) external confirmed isSeller{
        USDc.transfer(buyer, weiPrices[_index]);
        weiPrices[_index] = 0;
    }

    ///@notice the seller refund the remaining milestones
    function refundAll() external confirmed isSeller{
        uint _amount;
        for ( uint i = 0 ; i < weiPrices.length ; i++){
            _amount += weiPrices[i];
            weiPrices[i] = 0;
        }
        USDc.transfer(buyer, _amount);
    } 

    ///@notice the buyer or the seller call the trial
    function callTrial() external confirmed isActor{
        thisState = TransactionState.TRIAL;
        TimeStamp = block.timestamp;
    }


    ///@notice functions callable during Trial period only (State == TRIAL)//////////////////////////////////////////////////////////////////////
    
    function vote(uint8 _vote) external {
        require(factory.isJudge(msg.sender) && 0<=_vote && _vote<5 && !hasVoted[msg.sender]);
        hasVoted[msg.sender] = true;
        if (_vote < 1) {
            voted0.push(msg.sender);
        } else if (_vote < 2) {
            voted1.push(msg.sender);
        } else if (_vote < 3) {
            voted2.push(msg.sender);
        } else if (_vote <4){
            voted3.push(msg.sender);
        } else {
            voted4.push(msg.sender);
        }
        factory.incrVotes(msg.sender);
    }


    ///@dev all done
    function endTrial() external isActor{
        uint8 finalResult;
        uint maxScore = voted0.length;
        if(voted1.length>=maxScore){            ///@dev verrify vote1 beats vote0
            finalResult = 1;
            maxScore = voted1.length;
        }if(voted2.length>=maxScore){           ///@dev verrify vote2 beats vote1
            finalResult = 2;
            maxScore = voted2.length;
        }if(voted3.length>maxScore){            ///@dev verrify vote3 beats vote2
            finalResult = 3;
            maxScore = voted3.length;
        }if(voted4.length>maxScore){            ///@dev verrify vote4 beats vote3
            finalResult = 4;
            maxScore = voted4.length;
        }if(finalResult == 0){                  ///@dev process vote0 if win
            _transferTrial(0, 100);
            for (uint i = 0 ; i < voted0.length ; i++ ){
                factory.incrValidVotes(voted0[i]);
            }
        }if(finalResult == 1){                  ///@dev process vote1 if win
            _transferTrial(25, 75);
            for (uint i = 0 ; i < voted1.length ; i++ ){
                factory.incrValidVotes(voted1[i]);
            }
        }if(finalResult == 2){                  ///@dev process vote2 if win
            _transferTrial(50, 50);
            for (uint i = 0 ; i < voted2.length ; i++ ){
                factory.incrValidVotes(voted2[i]);
            }
        }if(finalResult == 3){                  ///@dev process vote3 if win
            _transferTrial(75, 25);
            for (uint i = 0 ; i < voted3.length ; i++ ){
                factory.incrValidVotes(voted3[i]);
            }
        }if(finalResult == 4){                  ///@dev process vote4 if win
            _transferTrial(100, 0);
            for (uint i = 0 ; i <= voted4.length ; i++ ){
                factory.incrValidVotes(voted4[i]);
            }
        }
    }
    
    


    ///@dev Privates Functions //////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    ///@dev used in endTrial
    function _transferTrial(uint8 _buyerPercent, uint8 _sellerPercent)private{
        require(_buyerPercent + _sellerPercent == 100);
        uint _adminTaxes = USDc.balanceOf(address(this))*adminTaxes/100;
        uint _trialTaxes = USDc.balanceOf(address(this))*trialTaxes/100;
        USDc.transfer(admin, _adminTaxes);
        USDc.transfer(address(factory), _trialTaxes);
        uint _buyerAmount = USDc.balanceOf(address(this))*_buyerPercent/100;
        uint _sellerAmount = USDc.balanceOf(address(this))*_sellerPercent/100;
        USDc.transfer(buyer, _buyerAmount);                      
        USDc.transfer(seller, _sellerAmount);
    }
    
}