// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.12.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract KaijuFinanceCreditLine is Ownable, ReentrancyGuard
{
    struct Credit {
        uint256 Id;
        uint256 AmountLent;
        uint256 AmountExpected;
        address User;
        string Symbol;
        uint256 PaybackDate;
        uint256 CreatedAt;
        bool Active;        
        uint256 PaidBackAt;
        uint256 LateFee;
    }

    uint256 _currentCreditId = 1;
    uint256 _collateralPercentToIssue = 20;

    Credit[] _allCredit;
    mapping(address => uint256[]) _usersCreditIndex;
    mapping(address => uint256) _usersCurrentCreditIndex;

    event CreditCreated(uint256 indexed Id, uint256 AmountLent, uint256 AmountExpected, string indexed symbol, uint256 paybackDate, uint256 CreatedAt);
    event CreditPaidBackAt(uint256 indexed Id, uint256 LateFees, uint256 CreatedAt);

    function issueCredit(address user, uint256 amountLent, uint256 amountExpected, string memory symbol, uint256 paybackDate) external onlyOwner nonReentrant
    {
        // Check there isn't outstanding credit
        uint256 usersCurrentIssuedCreditTotal = getUsersActiveCreditIssuedTotal(user);
        require(usersCurrentIssuedCreditTotal > 0,'User has outstanding credit line');
        
        // Create credit line
        Credit memory credit = Credit(_currentCreditId++, amountLent, amountExpected, user, symbol, paybackDate, block.timestamp, true, 0, 0);
 
        // Add credit
        _allCredit.push(credit);

        // Map credit
        uint256 newIndex = _allCredit.length-1;
        _usersCreditIndex[user].push(newIndex);
        _usersCurrentCreditIndex[user] = newIndex;

        // Fire event
        emit CreditCreated(credit.Id, amountLent, amountExpected, symbol, paybackDate, credit.CreatedAt);
    }

    function payBackCredit(address user, uint256 lateFee) external nonReentrant onlyOwner 
    {
        // Check there are credit lines to pay back
        require(_allCredit.length > 0, 'No credits entered into system to pay');

        // Check the user has a current credit line to pay back
        uint256 usersCurrentCreditLineIndex = _usersCurrentCreditIndex[user];
        Credit storage usersCurrentCreditLine = _allCredit[usersCurrentCreditLineIndex];
        require(usersCurrentCreditLine.User == user, 'User has no credit to pay back');

        // Check credit exists
        require(usersCurrentCreditLine.Active, 'Credit doesnt exist');    

        // Check credit has not already been paid back
        require(usersCurrentCreditLine.PaidBackAt == 0, 'Credit doesnt require payback');  

        usersCurrentCreditLine.PaidBackAt = block.timestamp;
        usersCurrentCreditLine.LateFee = lateFee;
        usersCurrentCreditLine.Active = false;

        emit CreditPaidBackAt(usersCurrentCreditLine.Id, lateFee, usersCurrentCreditLine.PaidBackAt);
    }

    function getUsersActiveCreditIssuedTotal(address user) public view returns(uint256)
    {
        // If there are credit lines then check that there isnt a current active one (only allowed one active)
        if(_allCredit.length > 0)
        {
            // Check for users current credit
            uint256 usersCurrentCreditLineIndex = _usersCurrentCreditIndex[user];

            // Try to get the users current credit status
            Credit memory usersCurrentCreditLine = _allCredit[usersCurrentCreditLineIndex];
      
            // If the current credit line for a user doesnt already exist, then no need to do below
            // If no credit line exists then the credit line selected will be of index 0 BUT not the users
            if(usersCurrentCreditLine.User == user)
            {
                if(usersCurrentCreditLine.PaidBackAt > 0){
                    return 0;
                }

                return usersCurrentCreditLine.AmountLent;
            }
        }

        return 0;
    }

    function getCollateralAmount(address user) external view returns(uint256)
    {
        uint256 usersCreditTotal = getUsersActiveCreditIssuedTotal(user);
        
        return (usersCreditTotal / _collateralPercentToIssue) * 100;
    }
}
