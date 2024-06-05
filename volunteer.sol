// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;

import "hardhat/console.sol";

/**
 * @title Volunteer
 */
contract Volunteer {
    address private owner;
    address private charityDestination;
    address private charityRepresentative;

    uint private deadline;
    uint256 minLimit = 0;
    uint256 maxLimit = type(uint256).max;

    mapping (address => uint256) funding;

    address[] private donators;

    uint256 private balance;

    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    event FundingRecieve(address indexed funderAddress, uint256 fundingAmount);
    event FundingWithdraw(address indexed funderAddress, uint256 fundingAmount);
    event MinLimitSet(uint256 limit);


    // modifier to check if caller is owner
    modifier onlyOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    /**
     * @dev Set contract deployer as owner
     */
    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }

    /**
     * @dev setDeadline
     */
   function setDeadline(uint _deadline) external onlyOwner {
        deadline = _deadline;
    }

    /**
     * @dev donate
     */
    function donate() external payable {
        require(msg.value > minLimit && msg.value < maxLimit, "Unable to donate funds. Funding amount should fit into range betweeb minLimit and maxLimit value");
    
        if (funding[msg.sender] == 0) {
            donators.push(msg.sender);
        }

        funding[msg.sender] += msg.value;
        balance += msg.value;
        
        emit FundingRecieve(msg.sender, msg.value);
    }

    /**
     * @dev getBalance
     */
    function getBalance() public view returns (uint256) {
        return balance;
    }

    /**
     * @dev getDonators
     */
    function getDonators() public view returns (address[] memory) {
        return donators;
    }

    /**
     * @dev getDonationsPerAddr
     * @return amount of funds per address
     */
    function getDonationsPerAddr(address _address) public view returns (uint256) {
        return funding[_address];
    }

    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }

    /**
     * @dev set min amount of single donation
     */
    function setDonatMin(uint256 _limit) public {
        minLimit = _limit;
        emit MinLimitSet(minLimit);
    }

    /**
     * @dev set charity representative
     */
    function setCharityRepresentative(address _charityRepresentative) external onlyOwner {
        charityRepresentative = _charityRepresentative;
    }

    modifier onlyCharityRepresentative() {
        require(msg.sender == charityRepresentative, "Only owner charity representative to perform this action");
        _;
    }

    /**
     * @dev set charity destination
     */
    function setCharityDestination(address _charityDestination) external onlyOwner {
        charityDestination = _charityDestination;
    }

    /**
     * @dev withdraw funds
     */
    function withdrawFunds() external payable  onlyCharityRepresentative {
        require(charityDestination != address(0), "Charity address is not set. Unable to send funds");
        require(block.timestamp >= deadline, "Unable to withdraw funds before the deadline");
        
        (bool success, ) = charityDestination.call{value: balance}("");
        require(success, "Transfer failed");
        emit FundingWithdraw(charityDestination, balance);
    }

    fallback() external payable{}
    
    receive() external payable {}
} 
