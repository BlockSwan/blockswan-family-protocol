// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./BlockSwan.sol";

contract Adminable {

    address payable public admin ; ///@dev admin = blockswanDAO address  nb : factoryAddress = thisAddress = trialChestAddress

    constructor(){
        BlockSwan bs = BlockSwan(0x5FbDB2315678afecb367f032d93F642f64180aa3); /////@dev paste the deployment address of the BlockSwan contract
        admin = bs.blockSwan();
    }

    modifier isAdmin {
        require(msg.sender == admin);
        _;
    }

    function fetchAdminAddress() public {
        BlockSwan bs = BlockSwan(0x5FbDB2315678afecb367f032d93F642f64180aa3);  ///@dev paste the deployment address of the BlockSwan contract
        admin = bs.blockSwan();
    }
}