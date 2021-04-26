// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.7.4;

import "./IBEP20.sol";

interface IIncome is IBEP20 {
    function governor() external view returns (address);
    function setGovernor(address newGovernor) external returns (bool);

    function addMintingContract(address mintingContract) external returns (bool);
    function removeMintingContract(address mintingContract) external returns (bool);
    function isMintingContract(address mintingContract) external view returns (bool);
    function mint(uint256 amount) external returns (bool);

    function burn(uint256 amount) external returns (bool);
    function totalBurned() external view returns (uint256);
    function burnRate() external view returns (uint256);
    function changeBurnRate(uint256 newBurnRate) external returns (bool);

    function setAddressExcludedFromBurnRate(address account, bool excluded) external returns (bool);
    function isAddressExcludedFromBurnRate(address account) external view returns (bool);
}