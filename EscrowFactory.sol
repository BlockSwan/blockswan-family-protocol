// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import './UserSoul.sol';
import './Escrow.sol';

//////////questions importantes: /////////////////////
/*
est ce que le msg sender pour les contracts créés est l'adresse de la factorie ??
dans ce cas les require du contract EscrowV1 sont inutiles et doivent etre addaptés
 */


contract EscrowGenerator is UserSoul {
    ///@dev uncomment if contracts tracking needed
    //mapping(uint=>address) public escrows;
    mapping(address=>bool) private isEscrow;

    modifier fromEscrow(){
        require(isEscrow[msg.sender]);
        _;
    }

    event escrowDeployed(address indexed _escrowAddress, address _buyer, address _seller);

    //create new EscrowV1
    function newEscrow(uint _transacId, address  _seller, uint[] memory _weiPrices) external {
        uint _weiPricesSum = 0;
        for (uint256 i = 0; i < _weiPrices.length; ++i) {
            _weiPricesSum = ++_weiPrices[i];
        }
        Escrow transac = new Escrow(msg.sender, _seller, _weiPrices);
        USDc.transferFrom(msg.sender, address(transac), _weiPricesSum);
        isEscrow[address(transac)] = true;
        //escrows[_transacId]= address(transac);
    }


    function incrVotes(address _user) external fromEscrow{
        users[_user].votes += 1 ;
    }
    function incrValidVotes(address _user) external fromEscrow{
        users[_user].validVotes +=1;
        users[_user].judgeWeight +=1;
    }
}