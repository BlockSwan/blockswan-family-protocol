// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Adminable {

    address payable public admin ;

    constructor(){
        admin = payable(msg.sender);
    }

    modifier checkIfAdmin {
        require(msg.sender == admin);
        _;
    }
}