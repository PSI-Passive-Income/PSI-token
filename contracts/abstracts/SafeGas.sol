// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/ICHI.sol";
import "./PSIGovernable.sol";

abstract contract SafeGas is PSIGovernable {
    /**
     * @notice frees CHI from gas provider to reduce gas costs
     * @dev requires that gas provider has approved this contract to use their CHI
     */
    modifier useCHI {
        uint256 gasStart = gasleft();
        _;
        //uint256 gasSpent = 21000 + gasStart - gasleft() + (16 * msg.data.length);
        if (gasToken() != address(0)) {
            ICHI(gasToken()).freeFromUpTo(ensureGasProvider(), 
                ((21000 + gasStart - gasleft() + (16 * msg.data.length)) + 14154) / 41947);
        }
    }

    /**
     * @notice make it possible to add a single gas provider
     */
    function ensureGasProvider() internal view returns (address) {
        if (enableGasPromotion() && IERC20(gasToken()).balanceOf(address(this)) >= 1) {
            return address(this);
        }
        return msg.sender;
    }
}