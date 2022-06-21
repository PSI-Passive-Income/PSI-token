// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "./interfaces/IPSI.sol";
import "./interfaces/dex/IDPexRouter.sol";
import "./abstracts/BaseFeeAggregator.sol";

contract FeeAggregator is BaseFeeAggregator {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    /**
     * @notice psi token contract
     */
    address public psi;

    //== CONSTRUCTOR ==
    /**
     * @dev Initializes the contract setting the deployer as the initial Governor.
     */
    function initialize(address _router, address _baseToken, address _psi) public initializer {
        __BaseFeeAggregator_init(_router, _baseToken);
        psi = _psi;
    }

    /**
     * @notice set a new PSI address
     * @param _psi psi token address
     */
    function setPSIAddress(address _psi) external onlyOwner {
        psi = _psi;
    }

    /**
     * @notice sells all fees for PSI and reflects them over the PSI holders
     */
    function reflectFees(uint256 deadline) external override onlyOwner ensure(deadline) {
        uint256 psiBalanceBefore = IERC20Upgradeable(psi).balanceOf(address(this));
        _sellFeesToPSI();
        uint256 psiFeeBalance = IERC20Upgradeable(psi).balanceOf(address(this)) - psiBalanceBefore;
        if (tokensGathered[psi] > 0) {
            psiFeeBalance += tokensGathered[psi];
            tokensGathered[psi] = 0;
        }

        IPSI(psi).reflect(psiFeeBalance);
    }
    /**
     * @notice sells a single fee for PSI and reflects them over the PSI holders
     */
    function reflectFee(address token, uint256 deadline) external override onlyOwner ensure(deadline) {
        require(_feeTokens.contains(token), "FeeAggregator: NO_FEE_TOKEN");
        uint256 psiBalanceBefore = IERC20Upgradeable(psi).balanceOf(address(this));
        uint256 psiFeeBalance;
        if (token == psi) {
            psiFeeBalance = tokensGathered[psi];
            require(psiFeeBalance > 0, "FeeAggregator: NO_FEE_TOKEN_BALANCE");
        } else {
            _sellFeeToPSI(token);
            psiFeeBalance = IERC20Upgradeable(psi).balanceOf(address(this)) - psiBalanceBefore;
        }

        IPSI(psi).reflect(psiFeeBalance);
    }
    function _sellFeesToPSI() internal {
        for(uint256 idx = 0; idx < _feeTokens.length(); idx++) {
            address token = _feeTokens.at(idx);
            uint256 tokenBalance = IERC20Upgradeable(token).balanceOf(address(this));
            if (token != baseToken && token != psi && tokenBalance > 0) {
                tokensGathered[token] = 0;
                address[] memory path = new address[](2);
                path[0] = token;
                path[1] = baseToken;
                IDPexRouter(router).swapAggregatorToken(tokenBalance, path, address(this));
            }
        }

        _sellBaseTokenToPSI();
    }
    function _sellFeeToPSI(address token) internal {
        uint256 tokenBalance = IERC20Upgradeable(token).balanceOf(address(this));
        require(tokenBalance > 0, "FeeAggregator: NO_FEE_TOKEN_BALANCE");
        if (token != baseToken && token != psi && tokenBalance > 0) {
            tokensGathered[token] = 0;
            address[] memory path = new address[](3);
            path[0] = token;
            path[1] = baseToken;
            path[2] = psi;
            IDPexRouter(router).swapAggregatorToken(tokenBalance, path, address(this));
        } else if(token == baseToken) {
            _sellBaseTokenToPSI();
        }
    }
    function _sellBaseTokenToPSI() internal {
        uint256 balance = IERC20Upgradeable(baseToken).balanceOf(address(this));
        if (balance <= 0) return;

        tokensGathered[baseToken] = 0;
        address[] memory path = new address[](2);
        path[0] = baseToken;
        path[1] = psi;
        IDPexRouter(router).swapAggregatorToken(balance, path, address(this));
    }
}