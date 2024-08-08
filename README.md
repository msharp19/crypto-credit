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

| Contract      | Address       | Network       |
| ------------- | ------------- | ------------- |
| Finance Liquid Token | [0xcdAD459fEEE277DfEE22856D763feb55EdF963ba](https://sepolia.etherscan.io/address/0xcdad459feee277dfee22856d763feb55edf963ba#code)     | Sepolia       | 
| Finance Reward Token | [0xc962e4bdE44632caA916f0689904306E470ed93C](https://sepolia.etherscan.io/address/0xc962e4bde44632caa916f0689904306e470ed93c#code)          | Sepolia       |
| Credit Line          | [0x61f84f38575b73655cBa43bf1e9F3D4FC7a85332](https://sepolia.etherscan.io/address/0x61f84f38575b73655cba43bf1e9f3d4fc7a85332#code)       |  Sepolia       |
| Stake Lockup         | [0x3D6DC33633F739321C1116506a2dDdf1C1b9B014](https://sepolia.etherscan.io/address/0x3d6dc33633f739321c1116506a2dddf1c1b9b014#code)          | Sepolia       |

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




