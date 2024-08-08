// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.12.0;

interface IKaijuFinanceLiquidToken is IERC20 {
    function mint(address user, uint256 amount) external;
    function burn(address from, uint256 value) external returns (bool);
}
