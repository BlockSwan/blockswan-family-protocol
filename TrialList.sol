// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import './Adminable.sol';

contract TrialList is Adminable {

    mapping(address=>bool) public jugeList;

    function addOnList(address _newJugeAddress) external checkIfAdmin{
        jugeList[_newJugeAddress] = true ;
    }
    
    modifier isListed {
        require(jugeList[msg.sender]==true);
        _;
    }

}