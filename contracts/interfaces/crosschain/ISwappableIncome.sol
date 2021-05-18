// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import "../IIncome.sol";
import "./IAnyswapV4ERC20.sol";

interface ISwappableIncome is IIncome, IAnyswapV4ERC20 {
    function getOwner() external override(IBEP20, IAnyswapV4ERC20) view returns (address);
}