// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.12.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMintableToken is IERC20 {
    function mint(address user, uint256 amount) external;
}

interface ICreditLine {
    function getCollateralAmount(address sender) external returns(uint256);
}

contract KaijuFinanceStakeLockup is Ownable, ReentrancyGuard 
{
    //using SafeMath for uint256;

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

    struct SupportedToken {
       string Name;
       string Symbol;
       address Address;
       uint256 TokenRate;
       bool Active;
    }

    struct TotalActiveStake {
        uint256 Value;
    }

    uint256 _minimumStakeAmount = 1000000000000000;
    uint256 _earnRate = 1;
    uint256 _currentStakeId = 1;
    uint256 _currentWithdrawnStakeId = 1;

    Stake[] _allStakes;
    WithdrawnStake[] _allWithdrawnStakes;

    mapping(address => uint256[]) _allUsersStakes;
    mapping(address => uint256[]) _allUsersWithdrawnStakes;
    mapping(address => uint256) _usersCurrentStakeTotals;

    mapping(address => SupportedToken) _supportedTokens;

    IERC20 _kaijuFinanceLiquidStakingToken;
    ICreditLine _kaijuFinanceCreditLine;

    constructor(address kaijuFinanceLiquidStakingTokenAddress, address kaijuFinanceCreditLineAddress){
        _kaijuFinanceLiquidStakingToken = IERC20(kaijuFinanceLiquidStakingTokenAddress);
        _kaijuFinanceCreditLine = ICreditLine(kaijuFinanceCreditLineAddress);
    }

    event EthStaked(uint256 indexed Id, address indexed user, uint256 AmountStaked, uint256 CreatedAt);
    event StakeCollected(uint256 indexed Id, address indexed user, uint256 AmountReceived, uint256 CollectedAt);

    function updateSupportedToken(string memory name, string memory symbol, address contractAddress) external onlyOwner nonReentrant{
        SupportedToken memory supportedToken = SupportedToken(name, symbol, contractAddress, 1, true);
        _supportedTokens[contractAddress] = supportedToken;
    }

    function getMaximumWithdrawalAmount(address sender) public returns(uint256) {
        // Get the users current staked amount
        uint256 currentStakeAmount = _usersCurrentStakeTotals[sender];
        
        // Get the amount required for collateral
        uint256 amountRequiredForCollateral = _kaijuFinanceCreditLine.getCollateralAmount(sender);

        // Get the amount left staked excluding the amount required for collateral
        return (currentStakeAmount - amountRequiredForCollateral);
    }
 
    function stake() external payable nonReentrant{       
        // Validate stake amount
        require(msg.value >= _minimumStakeAmount, 'Minimum stake amount not met');

        // Create new stake record
        Stake memory newStake = Stake(_currentStakeId++, msg.sender, msg.value, block.timestamp, true);
        _allStakes.push(newStake);
        uint256 newStakeIndex = _allStakes.length-1;
        _allUsersStakes[msg.sender].push(newStakeIndex);
        uint256 usersCurrentStakeTotal = _usersCurrentStakeTotals[msg.sender];
        _usersCurrentStakeTotals[msg.sender] = usersCurrentStakeTotal + msg.value;

        // TODO: Reference the kaiju token contract definition NOT IERC20
        //_kaijuFinanceLiquidStakingToken.mint(msg.sender, msg.value);

        emit EthStaked(newStake.Id, msg.sender, msg.value, block.timestamp);
    }

    function withdrawStake(uint256 amount) external nonReentrant {

        // Ensure credit isnt already on loan
        uint256 maximumWithdrawAmount = getMaximumWithdrawalAmount(msg.sender);
        require(maximumWithdrawAmount >= amount, 'The withdraw will reduce the collateral below what is required since there is an active loan. Please try a lower amount');

        // Ensure contract has enough to honor the withdraw
         require(address(this).balance >= amount, 'The contract needs additional funding before this can be completed');

        // Ensure can collect tokens
        require(_kaijuFinanceLiquidStakingToken.allowance(msg.sender, address(this)) == amount, 'Please approve the exact amount of tokens required');
 
        // Collect
        //_kaijuFinanceLiquidStakingToken.safeTransferFrom(msg.sender, address(this), amount);

        // Mark as collected
        _usersCurrentStakeTotals[msg.sender] -= amount;
        
        // Create a record
        WithdrawnStake memory stakeWithdrawal = WithdrawnStake(_currentWithdrawnStakeId++, msg.sender, amount, block.timestamp, true);
        _allWithdrawnStakes.push(stakeWithdrawal);
        uint256 newWithdrawnStakeIndex = _allWithdrawnStakes.length-1;
        _allUsersWithdrawnStakes[msg.sender].push(newWithdrawnStakeIndex);

        // Send back value
        payable(msg.sender).transfer(amount);

        // Fire event
        emit StakeCollected(stakeWithdrawal.Id, msg.sender, amount, block.timestamp);
    }
}
