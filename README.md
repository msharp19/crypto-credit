# Distributed Loans :credit_card:

A distributed credit system using Solidity

## Contracts

### Finance Liquid Token :dollar:

A token issued upon stake and burned with the withdrawal of that stake

### Finance Reward Token :dollar:

A token issued as a reward for on time payments of loans (no late fees)

### Credit Line :newspaper:

A contract that tracks credit being issued and paid back to a user (externally).

### Stake Lockup  :lock_with_ink_pen:

A contract that allows a user to stake and get credit as a percentage of the stake (externally). The contract also allows for the withdraw of stakes given they are not in use as collateral for an active loan. 

## Test Dapps

Deployed for testing.

Deployers Address: 0x60e1C4DfB97e920D6C227cff4a0f39C4B560224B

| Contract      | Address       | Owner Address | Network       | Blockchain Explorer |
| ------------- | ------------- | ------------- | ------------- | ------------- |
| Finance Liquid Token | TBC.          | TBC.          | Sepolia       | [Sepolina Etherscan](https://sepolia.etherscan.io/address/#readContract) |
| Finance Reward Token | TBC.          | TBC.          | Sepolia       | [Sepolina Etherscan](https://sepolia.etherscan.io/address/#readContract) |
| Credit Line          | TBC.          | TBC.          | Sepolia       | [Sepolina Etherscan](https://sepolia.etherscan.io/address/#readContract) |
| Stake Lockup         | TBC.          | 0x60e1C4DfB97e920D6C227cff4a0f39C4B560224B          | Sepolia       | [Sepolina Etherscan](https://sepolia.etherscan.io/address/#readContract) |

## Deploy Steps

1. Deploy liquid token and reward token
2. Deploy credit line using the reward token address as a constructor arg
3. Set owner of reward token as credit line contract
4. Deploy Stake lockup using the credit line address and the liquid token address as the constructor args
5. Set owner of liquid token as the stake lockup contract

## Workflow

![image](https://github.com/user-attachments/assets/f7ad107e-9ddd-40c3-b04f-cbe8669ae70a)

![image](https://github.com/user-attachments/assets/42543316-1ab8-4ab8-9dcb-03961035340f)

![image](https://github.com/user-attachments/assets/007f4aaa-43fb-4ce2-9c28-19a092e99dc1)

![image](https://github.com/user-attachments/assets/7338619f-c9fd-4187-b632-c25f4b11aa34)




