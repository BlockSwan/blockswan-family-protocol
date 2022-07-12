// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

/*
* @dev Quant11111
* @notice Contract storing our current BlockSwan admin address
 */

contract BlockSwan {

    address payable public blockSwan;
    address payable public oldAddress;

    constructor(){
        blockSwan = payable(msg.sender);
    }

    modifier isBlockSwan {
        require(msg.sender == blockSwan);
        _;
    }
    modifier isOldAddress{
        require(msg.sender == oldAddress);
        _;
    }

    function changeBlockSwanAddress(address payable _newAddress) public isBlockSwan{
        oldAddress = blockSwan;
        blockSwan = _newAddress;
    }

    function restaureOldAddress() public isOldAddress{
        blockSwan = oldAddress ;
    }

    

}