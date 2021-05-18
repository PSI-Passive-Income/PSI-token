// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import "../interfaces/IIncome.sol";

contract IncomeMinter {
    address private _income;

    constructor(address income) {
        _income = income;
    }

    function mintIncome(uint256 amount) external returns (bool) {
        return IIncome(_income).mint(amount);
    }
}