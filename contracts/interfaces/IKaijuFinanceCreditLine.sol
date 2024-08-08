// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.12.0;

interface IKaijuFinanceCreditLine {
    function getRequiredCollateralAmount(address user) external view returns(uint256);
}
