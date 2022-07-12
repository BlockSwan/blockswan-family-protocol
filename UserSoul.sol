// SPDX-License-Identifier: GPL-3.0
///@author Oscarmacieira Quant11111

pragma solidity >=0.7.0 <0.9.0;

import "./Adminable.sol";
import "./USDCoin.sol";

contract UserSoul is Adminable, USDCoin {
    /**
     * @notice A bit more details on what's inside the User structure:
     identity => the user identity name
     isJudge => is the user availble to vote on conflict resolution
     vote => the number of votes the user has submited.
     successSell => the number of gigs sold without passing by a trial
     successBuy => the number of gigs bought without passing by a trial
     failSell => the number of gigs sold that went throught a trial
     failBuy => the number of gigs bought that went throught a trial
     grade => the userGrade on a scale of 5;
     invitedBy => the wallet address that invited the Users;
     invitations => the array of wallet address invited by the users
     
     * @dev Do we really need all these when we can listed from event
      submited by the Gig Contract?
     */
    struct User {
        string identity;
        bool isJudge;
        uint24 votes;
        uint24 validVotes;
        uint16 judgeWeight;  ///@dev judgeWeight is the indicator of what a judge can withdraw sur la judgesBalance (judgeWeight/balanceWeight)
        //uint24 successSell;
        //uint24 successBuy; 
        //uint24 failSell;
        //uint24 failBuy; 
        //uint8  grade;
        // address invitedBy;
        // address[] invitations;
    }

    /// @dev list of Users within the BFP.
    mapping (address => User) public users;

    
    string public name = "BFP User Soul"; /// @dev Full token name.
    string public ticker = "BFPuS"; /// @dev Short token name.
    /// @dev returns true if smart-contract.
    bytes32 private zeroHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
    uint32 public balanceWeight;
    uint public totalVotes;
    uint public totalValidVotes;
    
    event Mint(address _user);
    event Burn(address _user);
    event Update(address _user);
    event Judge(address _user, bool isJudge);


    /// @dev constructor
    constructor () {}
    

    /**
     * @dev mint a new token pointing to a user address and data if user not already exists 
     * and is called by the user. when user created by setting an identity, other parameters are autoset on 0 or false.
     * the function can only be called by someone whose identity is 0/inexistant.
     * @param _identity the User name
     * 
     */

    function mint(string memory _identity) external {
        require(keccak256(bytes(users[msg.sender].identity)) == zeroHash, "User already exists");
        users[msg.sender].identity = _identity;
        emit Mint(msg.sender);
    }

    /** 
     * @dev The token owner can destroy the token thus delete his account. 
     **/

    function burn() external {
        require(hasSoul(msg.sender), "Need a Soul Token to update it");
        balanceWeight = balanceWeight-users[msg.sender].judgeWeight;  ///@dev that way, the sum of all judgeWeight always equal to balanceWeight
        delete users[msg.sender];
        emit Burn(msg.sender);
    }

    /**
     * @dev the owner can operator the set or unset a judge as owner.
     * @param _user the address that will have his User judge bool inverted
     */
    function setJudge(address _user) external isAdmin {
        require(hasSoul(_user), "Need a Soul Token to update it");
        users[_user].isJudge = !users[_user].isJudge;
        emit Judge(_user, users[_user].isJudge);
    }

    function withdraw() external {
        uint _amount = USDc.balanceOf(address(this))*users[msg.sender].judgeWeight/balanceWeight;
        balanceWeight = balanceWeight - users[msg.sender].judgeWeight;
        users[msg.sender].judgeWeight = 0;
        USDc.transfer(msg.sender, _amount); //à remplacer
    }

    
    /**
     * @dev return true if the address possesses a BFP User Soul false otherwise 
     * @param _user the address to check the token possession
     **/
    function hasSoul(address _user) private view returns (bool) {
        if (keccak256(bytes(users[_user].identity)) == zeroHash) {
            return false;
        } else {
            return true;
        }
    }
    ///@notice returns true if the user is a judge
    function isJudge(address _user) external view returns(bool){
        return(users[_user].isJudge);
    }


}