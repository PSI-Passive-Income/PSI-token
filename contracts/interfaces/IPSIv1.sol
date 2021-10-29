// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "./IBEP20.sol";

interface IPSIv1 is IBEP20 {
    function isExcludedFromFeeRetrieval(address account) external view returns (bool);
    function excludeAccountForFeeRetrieval(address account) external;
    function includeAccountForFeeRetrieval(address account) external;
    function isExcludedFromFeePayment(address account) external view returns (bool);
    function excludeAccountFromFeePayment(address account) external;
    function includeAccountFromFeePayment(address account) external;
}