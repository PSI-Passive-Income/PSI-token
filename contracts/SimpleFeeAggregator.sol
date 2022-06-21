// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./interfaces/dex/IDEXRouter.sol";
import "./interfaces/dex/IUniswapRouter.sol";
// import "https://github.com/Uniswap/uniswap-v3-periphery/blob/main/contracts/interfaces/IQuoter.sol";
import "./abstracts/BaseFeeAggregator.sol";

contract SimpleFeeAggregator is BaseFeeAggregator {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    /**
     * @notice reflect wallet address
     */
    address public reflectAddress;

    //== CONSTRUCTOR ==
    /**
     * @dev Initializes the contract setting the deployer as the initial Governor.
     */
    function initialize(address _router, address _baseToken, address _reflectAddress) public initializer {
        __BaseFeeAggregator_init(_router, _baseToken);
        reflectAddress = _reflectAddress;
    }

    /**
     * @notice set a new address to reflect to
     * @param _reflectAddress reflect wallet address
     */
    function setReflectAddress(address _reflectAddress) external onlyOwner {
        reflectAddress = _reflectAddress;
    }

    /**
     * @notice sells all fees for PSI and reflects them over the PSI holders
     */
    function reflectFees(uint256 deadline) external override onlyOwner ensure(deadline) {
        _sellFeesToBaseToken(deadline);
        uint256 fee = IERC20Upgradeable(baseToken).balanceOf(address(this));
        IERC20Upgradeable(baseToken).transfer(reflectAddress, fee);
    }
    /**
     * @notice sells a single fee for PSI and reflects them over the PSI holders
     */
    function reflectFee(address token, uint256 deadline) external override onlyOwner ensure(deadline) {
        require(_feeTokens.contains(token), "FeeAggregator: NO_FEE_TOKEN");
        _sellFeeToBaseToken(token, deadline);
        IERC20Upgradeable(baseToken).transfer(reflectAddress, IERC20Upgradeable(baseToken).balanceOf(address(this)));
    }
    function _sellFeesToBaseToken(uint256 deadline) internal {
        for(uint256 idx = 0; idx < _feeTokens.length(); idx++) {
            _sellFeeToBaseToken(_feeTokens.at(idx), deadline);
        }
    }
    function _sellFeeToBaseToken(address token, uint256 deadline) internal {
        uint256 tokenBalance = IERC20Upgradeable(token).balanceOf(address(this));
        if (token != baseToken && tokenBalance > 0) {
            tokensGathered[token] = 0;
            
            ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams(
                token,
                baseToken,
                3000,
                reflectAddress,
                deadline,
                tokenBalance,
                0,
                0
            );
            
            IUniswapRouter(router).exactInputSingle{ value: msg.value }(params);
            IUniswapRouter(router).refundETH();
        }
    }
}