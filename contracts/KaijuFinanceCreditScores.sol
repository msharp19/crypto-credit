// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.12.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract KaijuFinanceCreditScores is Ownable, ReentrancyGuard
{
    struct CreditScore {
        string OverallScore;
        uint256 LastUpdatedAt;
        bool Active;
    }

    mapping(address => CreditScore) _creditScores;

    // Score is an encrypted string
    function updateCreditScore(address user, string memory score) external onlyOwner nonReentrant returns(CreditScore memory){
        CreditScore storage creditScore = _creditScores[user];

        creditScore.OverallScore = score;
        creditScore.Active = true;
        creditScore.LastUpdatedAt = block.timestamp;

        return creditScore;
    }
	
	
}