// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.12.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "https://raw.githubusercontent.com/msharp19/crypto-credit/main/contracts/interfaces/IKaijuFinanceCreditLine.sol";
import "https://raw.githubusercontent.com/msharp19/crypto-credit/main/contracts/interfaces/IKaijuFinanceLiquidStakingToken.sol";

contract KaijuFinanceStakeLockup is Ownable, ReentrancyGuard 
{
    struct Stake {
       uint256 Id;
       address Owner;
       uint256 AmountStaked;
       uint256 CreatedAt;
       bool Active;
    }

    struct WithdrawnStake {
       uint256 Id;
       address Owner;
       uint256 AmountWithdrawn;
       uint256 CreatedAt;
       bool Active;
    }


    uint256 private _minimumStakeAmount  = 1000000000000000;
    uint256 private _currentStakeId = 1;
    uint256 private _currentWithdrawnStakeId = 1;

    Stake[] private _allStakes;
    WithdrawnStake[] private _allWithdrawnStakes;

    mapping(address => uint256[]) private _allUsersStakeIndexs;
    mapping(address => uint256[]) private _allUsersWithdrawnStakeIndexs;
    mapping(address => uint256) private _usersCurrentStakeTotals;

    IKaijuFinanceLiquidStakingToken private _kaijuFinanceLiquidStakingToken;
    IKaijuFinanceCreditLine private _kaijuFinanceCreditLine;

    constructor(address kaijuFinanceLiquidStakingTokenAddress, address kaijuFinanceCreditLineAddress){
        _kaijuFinanceLiquidStakingToken = IKaijuFinanceLiquidStakingToken(kaijuFinanceLiquidStakingTokenAddress);
        _kaijuFinanceCreditLine = IKaijuFinanceCreditLine(kaijuFinanceCreditLineAddress);
    }

    event EthStaked(uint256 indexed id, address indexed user, uint256 amountStaked, uint256 createdAt);
    event StakeCollected(uint256 indexed id, address indexed user, uint256 amountReceived, uint256 collectedAt);

    function getMaximumWithdrawalAmount(address user) public returns(uint256) {
        // Get the users current staked amount
        uint256 currentStakeAmount = _usersCurrentStakeTotals[user];
        
        // Get the amount required for collateral
        uint256 amountRequiredForCollateral = _kaijuFinanceCreditLine.getRequiredCollateralAmount(user);

        // Get the amount left staked excluding the amount required for collateral
        return (currentStakeAmount - amountRequiredForCollateral);
    }
 
    function stake() external payable nonReentrant{       
        // Validate stake amount
        require(msg.value >= _minimumStakeAmount, 'Minimum stake amount not met');

        // Create new stake record and add it
        Stake memory newStake = Stake(_currentStakeId++, msg.sender, msg.value, block.timestamp, true);
        _allStakes.push(newStake);

        // Calculate the new index and add index to users stakes
        uint256 newStakeIndex = _allStakes.length-1;
        _allUsersStakeIndexs[msg.sender].push(newStakeIndex);

        // Update users stake total
        uint256 usersCurrentStakeTotal = _usersCurrentStakeTotals[msg.sender];
        _usersCurrentStakeTotals[msg.sender] = usersCurrentStakeTotal + msg.value;

        // Mint the liquid staking tokens
        _kaijuFinanceLiquidStakingToken.mint(msg.sender, msg.value);

        // Fire contract event indicatin Eth has been staked
        emit EthStaked(newStake.Id, msg.sender, msg.value, block.timestamp);
    }

    function withdrawStake(uint256 amount) external nonReentrant {

        // Ensure credit isnt already on loan
        uint256 maximumWithdrawAmount = getMaximumWithdrawalAmount(msg.sender);
        require(maximumWithdrawAmount >= amount, 'The withdraw will reduce the collateral below what is required since there is an active loan. Please try a lower amount');

        // Ensure contract has enough to honor the withdraw
        require(address(this).balance >= amount, 'The contract needs additional funding before this can be completed');

        // Ensure the user has the liquid staking tokens to burn
        uint256 liquidTokenBalance = _kaijuFinanceLiquidStakingToken.balanceOf(msg.sender);
        require(liquidTokenBalance >= amount, 'User does not have the liquid stake token balance to complete the withdrawal');

        // Collect
        _kaijuFinanceLiquidStakingToken.burn(msg.sender, amount);

        // Mark as collected
        _usersCurrentStakeTotals[msg.sender] -= amount;
        
        // Create a record
        WithdrawnStake memory stakeWithdrawal = WithdrawnStake(_currentWithdrawnStakeId++, msg.sender, amount, block.timestamp, true);
        _allWithdrawnStakes.push(stakeWithdrawal);
        uint256 newWithdrawnStakeIndex = _allWithdrawnStakes.length-1;
        _allUsersWithdrawnStakeIndexs[msg.sender].push(newWithdrawnStakeIndex);

        // Send back value
        payable(msg.sender).transfer(amount);

        // Fire contract event indication that a stake has been withdrawn by a user
        emit StakeCollected(stakeWithdrawal.Id, msg.sender, amount, block.timestamp);
    }

    // Get and return a users staked total
    function getStakeTotal(address user) view external returns(uint256){
         return _usersCurrentStakeTotals[user];
    }

    // Get and return a stake by its id (id is +1 of index)
    function getStake(uint256 stakeId) view external returns(Stake memory){
         return _allStakes[stakeId - 1];
    }

    // Get and return a page of stakes
    function getPageOfStakes(uint256 pageNumber, uint256 perPage) public view returns(Stake[] memory){
        // Get the total amount remaining
        uint256 totalStakes = _allStakes.length;

        // Get the index to start from
        uint256 startingIndex = pageNumber * perPage;

        // The number of stakes that will be returned (to set array)
        uint256 remaining = totalStakes - startingIndex;
        uint256 pageSize = ((startingIndex+1)>totalStakes) ? 0 : (remaining < perPage) ? remaining : perPage;

        // Create the page
        Stake[] memory pageOfStakes = new Stake[](pageSize);

        // Add each item to the page
        uint256 pageItemIndex = 0;
        for(uint256 i = startingIndex;i < (startingIndex + pageSize);i++){
           
           // Get the stake 
           Stake memory addedStake = _allStakes[i];

           // Add to page
           pageOfStakes[pageItemIndex] = addedStake;

           // Increment page item index
           pageItemIndex++;
        }

        return pageOfStakes;
    }

    // Get and return a page of stakes
    function getPageOfUsersStakes(address user, uint256 pageNumber, uint256 perPage) public view returns(Stake[] memory){
        
        uint256[] memory usersStakeIndexes = _allUsersStakeIndexs[user];

        // Get the total amount remaining
        uint256 totalStakes = usersStakeIndexes.length;

        // Get the index to start from
        uint256 startingIndex = pageNumber * perPage;

        // The number of stakes that will be returned (to set array)
        uint256 remaining = totalStakes - startingIndex;
        uint256 pageSize = ((startingIndex+1)>totalStakes) ? 0 : (remaining < perPage) ? remaining : perPage;

        // Create the page
        Stake[] memory pageOfStakes = new Stake[](pageSize);

        // Add each item to the page
        uint256 pageItemIndex = 0;
        for(uint256 i = startingIndex;i < (startingIndex + pageSize);i++)
        {   
           // Get the stake 
           Stake memory usersStake = _allStakes[usersStakeIndexes[i]];

           // Add to page
           pageOfStakes[pageItemIndex] = usersStake;

           // Increment page item index
           pageItemIndex++;
        }

        return pageOfStakes;
    }

     // Get and return a page of withdrawn stakes
    function getPageOfWithdrawnStakesAscending(uint256 pageNumber, uint256 perPage) public view returns(WithdrawnStake[] memory){
        // Get the total amount remaining
        uint256 totalWithdrawnStakes = _allWithdrawnStakes.length;

        // Get the index to start from
        uint256 startingIndex = pageNumber * perPage;

        // The number of stakes that will be returned (to set array)
        uint256 remaining = totalWithdrawnStakes - startingIndex;
        uint256 pageSize = ((startingIndex+1)>totalWithdrawnStakes) ? 0 : (remaining < perPage) ? remaining : perPage;

        // Create the page
        WithdrawnStake[] memory pageOfWithdrawnStakes = new WithdrawnStake[](pageSize);

        // Add each item to the page
        uint256 pageItemIndex = 0;
        for(uint256 i = startingIndex;i < (startingIndex + pageSize);i++){
           
           // Get the stake 
           WithdrawnStake memory addedStake = _allWithdrawnStakes[i];

           // Add to page
           pageOfWithdrawnStakes[pageItemIndex] = addedStake;

           // Increment page item index
           pageItemIndex++;
        }

        return pageOfWithdrawnStakes;
    }

         // Get and return a page of withdrawn stakes
    function getPageOfWithdrawnStakesDescending(uint256 pageNumber, uint256 perPage) public view returns(WithdrawnStake[] memory){
        // Get the total amount remaining
        uint256 totalWithdrawnStakes = _allWithdrawnStakes.length;

        // Get the index to start from
        uint256 startingIndex = totalWithdrawnStakes - (pageNumber * perPage);

        // The number of stakes that will be returned (to set array)
        uint256 remaining = totalWithdrawnStakes - (pageNumber * perPage);
        uint256 pageSize = ((startingIndex+1)>totalWithdrawnStakes) ? 0 : (remaining < perPage) ? remaining : perPage;

        // Create the page
        WithdrawnStake[] memory pageOfWithdrawnStakes = new WithdrawnStake[](pageSize);

        // Add each item to the page
        uint256 pageItemIndex = 0;
        for(uint256 i = startingIndex;i > 0;i--){
           
           // Get the stake 
           WithdrawnStake memory addedStake = _allWithdrawnStakes[i];

           // Add to page
           pageOfWithdrawnStakes[pageItemIndex] = addedStake;

           // Increment page item index
           pageItemIndex++;
        }

        return pageOfWithdrawnStakes;
    }

    // Get and return a page of stakes
    function getPageOfUsersWithdrawnStakes(address user, uint256 pageNumber, uint256 perPage) public view returns(WithdrawnStake[] memory){
        
        uint256[] memory usersStakeIndexes = _allUsersWithdrawnStakeIndexs[user];

        // Get the total amount remaining
        uint256 totalStakes = usersStakeIndexes.length;

        // Get the index to start from
        uint256 startingIndex = pageNumber * perPage;

        // The number of stakes that will be returned (to set array)
        uint256 remaining = totalStakes - startingIndex;
        uint256 pageSize = ((startingIndex+1)>totalStakes) ? 0 : (remaining < perPage) ? remaining : perPage;

        // Create the page
        WithdrawnStake[] memory pageOfWithdrawnStakes = new WithdrawnStake[](pageSize);

        // Add each item to the page
        uint256 pageItemIndex = 0;
        for(uint256 i = startingIndex;i < (startingIndex + pageSize);i++)
        {   
           // Get the stake 
           WithdrawnStake memory usersStake = _allWithdrawnStakes[usersStakeIndexes[i]];

           // Add to page
           pageOfWithdrawnStakes[pageItemIndex] = usersStake;

           // Increment page item index
           pageItemIndex++;
        }

        return pageOfWithdrawnStakes;
    }
}
