// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "./IBEP20.sol";

interface IPSI is IBEP20 {
    //== Include or Exclude account from earning fees ==
    function setAccountExcludedFromFees(address account, bool excluded) external;
    function isExcludedFromFeeRetrieval(address account) external view returns (bool);
    function setAccountExcludedFromFeeRetrieval(address account, bool excluded) external;
    function isExcludedFromFeePayment(address account) external view returns (bool);
    function setAccountExcludedFromFeePayment(address account, bool excluded) external;

    //== Fees ==
    function totalFees() external view returns (uint256);
    function setReflectionFee(uint256 fee) external;

    //== Reflection ==
    function reflect(uint256 tAmount) external;
    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) external view returns(uint256);
    function tokenFromReflection(uint256 rAmount) external view returns(uint256);
}