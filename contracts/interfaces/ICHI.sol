// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import "./IBEP20.sol";

interface ICHI is IBEP20 {
    function freeFromUpTo(address _addr, uint256 _amount) external returns (uint256);
}