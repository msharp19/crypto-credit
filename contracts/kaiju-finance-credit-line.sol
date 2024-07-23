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

    Credit[] _allCredit;
    mapping(address => uint256[]) _usersCredit;

    event CreditCreated(uint256 indexed Id, uint256 AmountLent, uint256 AmountExpected, string indexed symbol, uint256 paybackDate, uint256 CreatedAt);
    event CreditPaidBackAt(uint256 indexed Id, uint256 LateFees, uint256 CreatedAt);

    function issueCredit(address user, uint256 amountLent, uint256 amountExpected, string memory symbol, uint256 paybackDate) external onlyOwner nonReentrant{
        // Create credit line
        Credit memory credit = Credit(_currentCreditId++, amountLent, amountExpected, user, symbol, paybackDate, block.timestamp, true, 0, 0);
 
        _allCredit.push(credit);
        _usersCredit[user].push(_allCredit.length);

        // Fire event
        emit CreditCreated(credit.Id, amountLent, amountExpected, symbol, paybackDate, credit.CreatedAt);
    }

    function payBackCredit(address user, uint256 id, uint256 lateFee) external nonReentrant onlyOwner {
        uint256[] memory usersCredits = _usersCredit[user];

        for (uint256 i = 0; i< usersCredits.length; i++) 
        {
            Credit storage credit = _allCredit[i];

            if(credit.Id == id)
            {
                // Check credit exists
                require(credit.Active, 'Credit doesnt exist');    

                // Check credit has not already been paid back
                require(credit.PaidBackAt == 0, 'Credit doesnt require payback');  

                credit.PaidBackAt = block.timestamp;
                credit.LateFee = lateFee;
                credit.Active = false;

                emit CreditPaidBackAt(credit.Id, lateFee, credit.PaidBackAt);
            }
        }

    }
}