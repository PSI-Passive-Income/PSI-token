// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import "./IBEP20.sol";

interface IPSI is IBEP20 {
    //== Increase and decrease allowance ==
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

    //== Include or Exclude account from earning fees ==
    function isExcludedFromFeeRetrieval(address account) external view returns (bool);
    function excludeAccountForFeeRetrieval(address account) external;
    function includeAccountForFeeRetrieval(address account) external;
    function isExcludedFromFeePayment(address account) external view returns (bool);
    function excludeAccountFromFeePayment(address account) external;
    function includeAccountFromFeePayment(address account) external;

    //== Fees ==
    function totalFees() external view returns (uint256);
    function changeFee(uint256 fee) external;

    //== Reflection ==
    function reflect(uint256 tAmount) external;
    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) external view returns(uint256);
    function tokenFromReflection(uint256 rAmount) external view returns(uint256);
}