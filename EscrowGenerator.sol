// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import './TrialList.sol';
import './TransacEscrow.sol';

//////////questions importantes: /////////////////////
/*
est ce que le msg sender pour les contracts créés est l'adresse de la factorie ??
dans ce cas les require du contract transacEscrow sont inutiles et doivent etre addaptés
 */


contract EscrowGenerator is TrialList {

    mapping(uint=>address) public escrows;


    //create new TransacEscrow
    function newTransacEscrow(uint _transacId, address payable _seller, uint[] memory _weiPrices) external payable{
        uint _weiPricesSum = 0;
        for (uint256 i = 0; i < _weiPrices.length; ++i) {
            _weiPricesSum = ++_weiPrices[i];
        }
        TransacEscrow transac = new TransacEscrow{value: msg.value}(_transacId, payable(msg.sender), _seller, admin, _weiPrices, _weiPricesSum);
        escrows[_transacId]= address(transac);     
    }

    //views
    /*
    function getTransacStatus(uint _transacId) public returns(uint[] memory, bool[] memory){
        TransacEscrow transac = TransacEscrow(escrows[_transacId]);
        return(transac.weiPrices, transac.inProgress);
    }
    */

    //////////////////user Functions ://///////////////////////
    function unlockMilestone(uint _transacId, uint _milestoneIndex) public{
        TransacEscrow transac = TransacEscrow(escrows[_transacId]);
        transac.unlockMilestone(_milestoneIndex, msg.sender);
    }

    function unlockAll(uint _transacId) public{
        TransacEscrow transac = TransacEscrow(escrows[_transacId]);
        transac.unlockAll(msg.sender);
    }

    function refundMilestone(uint _transacId, uint _milestoneIndex) public{
        TransacEscrow transac = TransacEscrow(escrows[_transacId]);
        transac.refundMilestone(_milestoneIndex, msg.sender);
    }

    function refundAll(uint _transacId) public{
        TransacEscrow transac = TransacEscrow(escrows[_transacId]);
        transac.refundAll(msg.sender);
    }



    ////////////////admin Functions : //////////////////////////
    function transferMilestoneAdmin(uint _transacId, uint _milestoneIndex, uint _buyerPercent, uint _sellerPercent) public checkIfAdmin {
        TransacEscrow transac = TransacEscrow(escrows[_transacId]);
        transac.transferMilestoneAdmin(_milestoneIndex, msg.sender, _buyerPercent, _sellerPercent);
    }
    function transferAllAdmin(uint _transacId, uint _buyerPercent, uint _sellerPercent) public checkIfAdmin {
        TransacEscrow transac = TransacEscrow(escrows[_transacId]);
        transac.transferAllAdmin(msg.sender, _buyerPercent, _sellerPercent);
    }

}