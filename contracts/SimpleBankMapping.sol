// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "hardhat/console.sol";

contract SimpleBankMapping {

    /* We want to protect our users balance from other contracts */
    mapping(address => uint) balances;

    /* We want to create a getter function and allow 
    contracts to be able to see if a user is enrolled.  */
    mapping(address => bool) enrolled;

    /* Let's make sure everyone knows who owns the bank. */
    address payable public owner;

    /* Add an argument for this event, an accountAddress */
    event LogEnrolled(address _address);

    /* Add 2 arguments for this event, an accountAddress and an amount */
    event LogDepositMade(address accountAddress, uint256 _amount);

    /* Create an event that logs Withdrawals 
    It should log 3 arguments: 
    the account address, the amount withdrawn, and the new balance. */
    event LogWithdrawal(address _address, uint256 _amount, uint256 _newAmount);


    modifier isEnrolled(address _address){
        require(enrolled[_address], "Account is not registered");
        _;
    }

    modifier validAmount(uint256 _amount){
        require(_amount > 0, "Amount is not valid");
        _;
    }

    constructor() payable {
        owner = payable(msg.sender);
        enrolled[owner] = true;
        balances[msg.sender] = msg.value;
    }

    
    // Function to receive Ether
    receive() external payable {}



    /// notice Get balance
    /// return The balance of the user
    function getBalance() public view isEnrolled(msg.sender) returns(uint256) {
        return balances[msg.sender];
    }

    /// @notice Enroll a customer with the bank
    /// @return The users enrolled status
    // Emit the appropriate event
    function enroll() public returns (bool) {
        require(!enrolled[msg.sender], "User already enrolled");
        enrolled[msg.sender] = true;
        emit LogEnrolled(msg.sender);
        return enrolled[msg.sender];
    }

    /// @notice Deposit ether into bank
    /// @return The balance of the user after the deposit is made
    // This function can receive ether
    // Users should be enrolled before they can make deposits
    function deposit(address _address, uint256 _amount) external payable 
            isEnrolled(msg.sender)
            isEnrolled(_address)
            validAmount(_amount) 
        returns (uint) {
        //Updated balances
        balances[msg.sender] = balances[msg.sender] - _amount;
        balances[_address] = balances[_address] + _amount;
        //Send ETH
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Failed to send ETH");
        emit LogDepositMade(_address, _amount);
        return balances[msg.sender];
    }

    /// notice Withdraw ether from bank
    /// param withdrawAmount amount you want to withdraw
    /// return The balance remaining for the user
    // Emit the appropriate event
    function withdraw(uint withdrawAmount) external 
            isEnrolled(msg.sender)
            validAmount(withdrawAmount)
        returns (uint) {
        uint256 newBalance = balances[msg.sender] - withdrawAmount;
        //Updated balances
        balances[msg.sender] = newBalance;
        //Send ETH
        (bool success, ) = msg.sender.call{value: withdrawAmount}("");
        require(success, "Failed to send ETH");
        emit LogWithdrawal(msg.sender, withdrawAmount, balances[msg.sender]);
        return balances[msg.sender];
    }

    /// @notice Withdraw remaining ether from bank
    /// @return bool transaction success
    // Emit the appropriate event
    function withdrawAll() external
            isEnrolled(msg.sender)
        returns (bool) {
        uint256 amountToWithdraw = balances[msg.sender];
        require (balances[msg.sender] > 0, "Insuficient funds");
        balances[msg.sender] = 0;
        (bool success, ) = msg.sender.call{value: amountToWithdraw}("");
        require(success, "Failed to send ETH");
        emit LogWithdrawal(msg.sender, amountToWithdraw, balances[msg.sender]);
        return success;
    }

}
