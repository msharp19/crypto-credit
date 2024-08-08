// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.12.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract KaijuFinanceRewardToken is IERC20, ERC20, Ownable, ReentrancyGuard
{
    constructor () ERC20('Kaiju Finance Reward Token','KFRT'){
    }

    function mint(address user, uint256 amount) public onlyOwner nonReentrant{
        _mint(user, amount);
    }
}
