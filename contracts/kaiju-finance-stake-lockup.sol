// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.12.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract KaijuFinanceStakeLockup is Ownable, ReentrancyGuard
{
    struct Stake {
       uint256 Id;
       uint256 AmountStaked;
       uint256 AmountToReceive;   
       uint256 CreatedAt;
       uint256 CanCollectAt;
       uint256 CollectedAt;
       bool Active;
    }

    uint256 _minimumStakeAmount = 1000000000000000;
    uint256 _earnRate = 1;
    uint256 _currentStakeId = 1;
    uint256 _lockupTime = 10000;

    mapping(address => Stake[]) _allUsersStakes;

    IERC20 _kaijuFinanceToken;

    constructor(address kaijuFinanceTokenAddress){
        _kaijuFinanceToken = IERC20(kaijuFinanceTokenAddress);
    }

    event EthStaked(uint256 indexed Id, address indexed user, uint256 AmountStaked, uint256 AmountToReceive, uint256 CreatedAt);
    event StakeCollected(uint256 indexed Id, address indexed user, uint256 AmountReceived, uint256 CollectedAt);
 
    function stake() external payable nonReentrant{       
        // Validate stake amount
        require(msg.value >= _minimumStakeAmount, 'Minimum stake amount not met');

        // Calculate the amount to recieve after lockup
        uint256 amountToReceive = msg.value * _earnRate;

        // Calculate when to collect
        uint256 canCollectAt = block.timestamp + _lockupTime;
    
        // Create new stake record
        Stake memory newStake = Stake(_currentStakeId++, msg.value, amountToReceive, block.timestamp, canCollectAt, 0, true);
        _allUsersStakes[msg.sender].push(newStake);

        // TODO: Reference the kaiju token contract definition NOT IERC20
        _kaijuFinanceToken.mint(msg.sender, amountToReceive);

        emit EthStaked(newStake.Id, msg.sender, msg.value, amountToReceive, block.timestamp);
    }

    function withdrawStake(uint256 id) external nonReentrant {
        // Get all the users stakes
        Stake[] memory userStakes = _allUsersStakes[msg.sender];

        // Try to find the stake with the id specified
        for (uint256 i = 0; i<userStakes.length; i++) 
        {
            // Get the iterations stake
            Stake memory userStake = userStakes[i];

            // Check if the id supplied matches
            if(userStake.Id == id)
            {
                // Ensure its now time to collect
                require(userStake.CanCollectAt <= block.timestamp, 'Please wait until the lockup period has finished to collect');

                // Ensure it has not already been collected
                require(userStake.CollectedAt == 0, '');

                // Ensure contract has enough to honor the withdraw
                require(address(this).balance >= userStake.AmountToReceive, 'The contract needs additional funding before this can be completed');

                // Ensure can collect tokens
                require(_kaijuFinanceToken.allowance(msg.sender, address(this)) == userStake.AmountToReceive, 'Please approve the exact amount of tokens required');
 
                // Collect
                _kaijuFinanceToken.safeTransferFrom(msg.sender, address(this), userStake.AmountToReceive);

                // Mark as collected
                userStake.CollectedAt = block.timestamp;
                userStake.Active = false;

                // Send back value
                payable(msg.sender).transfer(userStake.AmountToReceive);

                emit StakeCollected(userStake.Id, msg.sender, userStake.AmountToReceive, block.timestamp);
            }
        }
    }
}