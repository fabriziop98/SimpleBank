// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract SimpleBank {

    struct User {
        bool enrolled;
        uint balance;
    }

    mapping(address => User) users;

    /* Let's make sure everyone knows who owns the bank. */
    address owner;

    /* Add an argument for this event, an accountAddress */
    event LogEnrolled(address _address);

    /* Add 2 arguments for this event, an accountAddress and an amount */
    event LogDepositMade(address _address, uint256 _amount);

    /* Create an event that logs Withdrawals 
    It should log 3 arguments: 
    the account address, the amount withdrawn, and the new balance. */
    event LogWithdrawal(address _address, uint256 _amount, uint256 _newAmount);


    modifier isEnrolled(address _address){
        require(users[_address].enrolled, "Account is not registered");
        _;
    }

    modifier validAmount(uint256 _amount){
        require(_amount > 0, "Amount is not valid");
        _;
    }

    constructor() {
        owner = msg.sender;
    }
    
    // Function to receive Ether
    receive() external payable {}

    /// notice Get balance
    /// return The balance of the user
    function getBalance() public view isEnrolled(msg.sender) returns(uint256) {
        return users[msg.sender].balance;
    }

    /// @notice Enroll a customer with the bank
    /// @return The users enrolled status
    // Emit the appropriate event
    function enroll() public returns (bool) {
        require(!users[msg.sender].enrolled, "User already enrolled");
        users[msg.sender].enrolled = true;
        emit LogEnrolled(msg.sender);
        return users[msg.sender].enrolled;
    }

    /// @notice Deposit ether into bank
    /// @return The balance of the user after the deposit is made
    // This function can receive ether
    // Users should be enrolled before they can make deposits
    function deposit(address _address, uint256 _amount) public payable 
            isEnrolled(msg.sender)
            isEnrolled(_address)
            validAmount(_amount) 
        returns (uint) {
        //Updated balances
        users[msg.sender].balance -=  _amount;
        users[_address].balance += _amount;
        //Send ETH
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Failed to send ETH");
        emit LogDepositMade(_address, _amount);
        return users[msg.sender].balance;
    }

    /// notice Withdraw ether from bank
    /// param withdrawAmount amount you want to withdraw
    /// return The balance remaining for the user
    // Emit the appropriate event
    function withdraw(uint withdrawAmount) external 
            isEnrolled(msg.sender)
            validAmount(withdrawAmount)
        returns (uint) {
        //Updated balances
        users[msg.sender].balance -= withdrawAmount;
        //Send ETH
        (bool success, ) = msg.sender.call{value: withdrawAmount}("");
        require(success, "Failed to send ETH");
        emit LogWithdrawal(msg.sender, withdrawAmount, users[msg.sender].balance);
        return users[msg.sender].balance;
    }

    /// @notice Withdraw remaining ether from bank
    /// @return bool transaction success
    // Emit the appropriate event
    function withdrawAll() external
            isEnrolled(msg.sender)
        returns (bool) {
        require (users[msg.sender].balance <= 0, "Insuficient funds");
        uint ammountToWithdraw = users[msg.sender].balance;
        users[msg.sender].balance = 0;
        (bool success, ) = msg.sender.call{value: ammountToWithdraw}("");
        require(success, "Failed to send ETH");
        emit LogWithdrawal(msg.sender, ammountToWithdraw, users[msg.sender].balance);
        return success;
    }

}
