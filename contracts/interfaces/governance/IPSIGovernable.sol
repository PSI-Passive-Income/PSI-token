// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.7.4;

import "./IGovernable.sol";

interface IPSIGovernable is IGovernable {
    function gasToken() external view returns (address);
    function enableGasPromotion() external view returns (bool);
    function router() external view returns (address);
}
