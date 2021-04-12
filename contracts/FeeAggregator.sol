// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.7.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/GSN/ContextUpgradeable.sol";
import "@passive-income/dpex-peripheral/contracts/interfaces/IDPexRouter.sol";
import "./interfaces/IFeeAggregator.sol";
import "./interfaces/IPSI.sol";
import "./abstracts/PSIGovernable.sol";

contract FeeAggregator is IFeeAggregator, Initializable, ContextUpgradeable, PSIGovernable {
    using SafeERC20 for IERC20;
    using AddressUpgradeable for address;
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    //== Variables ==
    EnumerableSet.AddressSet private _feeTokens; // all the token where a fee is deducted from on swap

    /**
     * @notice psi token contract
     */
    address public psi;
    /**
     * @notice base token contract (weth/wbnb)
     */
    address public baseToken;
    /**
     * @notice percentage which get deducted from a swap (1 = 0.1%)
     */
    uint256 public dpexFee;
    /**
     * @notice token fees gathered in the current period
     */
    mapping(address => uint256) public tokensGathered;


    //== CONSTRUCTOR ==
    /**
     * @dev Initializes the contract setting the deployer as the initial Governor.
     */
    function initialize(address _gov_contract, address _baseToken, address _psi) public initializer {
        __Context_init();
        super.initialize(_gov_contract);
        dpexFee = 1;
        psi = _psi;
        baseToken = _baseToken;
    }


    //== MODIFIERS ==
    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'FeeAggregator: EXPIRED');
        _;
    }

    //== VIEW ==
    /**
     * @notice return all the tokens where a fee is deducted from on swap
     */
    function feeTokens() external override view returns (address[] memory) {
        address[] memory tokens = new address[](_feeTokens.length());
        for(uint256 idx = 0; idx < _feeTokens.length(); idx++) {
            tokens[idx] = _feeTokens.at(idx);
        }
        return tokens;
    }
    /**
     * @notice checks if the token is a token where a fee is deducted from on swap
     * @param token fee token to check
     */
    function isFeeToken(address token) public override view returns (bool) {
        return _feeTokens.contains(token);
    }

    /**
     * @notice returns the fee for the amount given
     * @param amount amount to calculate the fee for
     */
    function calculateFee(uint256 amount) public override view returns (uint256 fee, uint256 amountLeft) {
        amountLeft = (amount.mul(1000).sub(amount.mul(dpexFee))).div(1000);
        fee = amount.sub(amountLeft);
    }
    /**
     * @notice returns the fee for the amount given, but only if the token is in the feetokens list
     * @param token token to check if it exists in the feetokens list
     * @param amount amount to calculate the fee for
     */
    function calculateFee(address token, uint256 amount) external override view 
        returns (uint256 fee, uint256 amountLeft)
    {
        if (!_feeTokens.contains(token)) { return (0, amount); }
        return calculateFee(amount);
    }

    //== SET INTERNAL VARIABLES==
    /**
     * @notice add a token to deduct a fee for on swap
     * @param token fee token to add
     */
    function addFeeToken(address token) public override onlyGovernor {
        require(!_feeTokens.contains(token), "FeeAggregator: ALREADY_FEE_TOKEN");
        _feeTokens.add(token);
        IERC20(token).approve(router(), 1e18);
    }
    /**
     * @notice remove a token to deduct a fee for on swap
     * @param token fee token to add
     */
    function removeFeeToken(address token) external override onlyGovernor {
        require(_feeTokens.contains(token), "FeeAggregator: NO_FEE_TOKEN");
        _feeTokens.remove(token);
    }
    /**
     * @notice set the percentage which get deducted from a swap (1 = 0.1%)
     * @param fee percentage to set as fee
     */
    function setDPexFee(uint256 fee) external override onlyGovernor {
        require(fee >= 0 && fee <= 200, "FeeAggregator: FEE_MIN_0_MAX_20");
        dpexFee = fee;
    }
    
    /**
     * @notice Adds a fee to the tokensGathered list. For example from the DPEX router
     * @param token fee token to check
     * @param fee fee to add to the tokensGathered list
     */
    function addTokenFee(address token, uint256 fee) external override {
        require (_feeTokens.contains(token), "Token is not a feeToken");
        tokensGathered[token] += fee;
    }
    /**
     * @notice Adds multiple fees to the tokensGathered list. For example from the DPEX router
     * @param tokens fee tokens to check
     * @param fees fees to add to the tokensGathered list
     */
    function addTokenFees(address[] memory tokens, uint256[] memory fees) external override {
        require (tokens.length == fees.length, "Token is not a feeToken");
        for(uint256 idx = 0; idx < tokens.length; idx++) {
            require (_feeTokens.contains(tokens[idx]), "Token is not a feeToken");
            tokensGathered[tokens[idx]] += fees[idx];
        }
    }

    /**
     * @notice sells all fees for PSI and reflects them over the PSI holders
     */
    function reflectFees(uint256 deadline) external override onlyGovernor ensure(deadline) {
        uint256 psiBalanceBefore = IERC20(psi).balanceOf(address(this));
        _sellFeesToPSI();
        uint256 psiFeeBalance = IERC20(psi).balanceOf(address(this)).sub(psiBalanceBefore);
        if (tokensGathered[psi] > 0) {
            psiFeeBalance += tokensGathered[psi];
            tokensGathered[psi] = 0;
        }

        IPSI(psi).reflect(psiFeeBalance);
    }
    /**
     * @notice sells a single fee for PSI and reflects them over the PSI holders
     */
    function reflectFee(address token, uint256 deadline) external override onlyGovernor ensure(deadline) {
        require(_feeTokens.contains(token), "FeeAggregator: NO_FEE_TOKEN");
        uint256 psiBalanceBefore = IERC20(psi).balanceOf(address(this));
        uint256 psiFeeBalance;
        if (token == psi) {
            psiFeeBalance = tokensGathered[psi];
            require(psiFeeBalance > 0, "FeeAggregator: NO_FEE_TOKEN_BALANCE");
        } else {
            _sellFeeToPSI(token);
            psiFeeBalance = IERC20(psi).balanceOf(address(this)).sub(psiBalanceBefore);
        }

        IPSI(psi).reflect(psiFeeBalance);
    }
    function _sellFeesToPSI() internal {
        for(uint256 idx = 0; idx < _feeTokens.length(); idx++) {
            address token = _feeTokens.at(idx);
            uint256 tokenBalance = IERC20(token).balanceOf(address(this));
            if (token != baseToken && token != psi && tokenBalance > 0) {
                tokensGathered[token] = 0;
                address[] memory path = new address[](2);
                path[0] = token;
                path[1] = baseToken;
                IDPexRouter(router()).swapAggregatorToken(tokenBalance, path, address(this));
            }
        }

        _sellBaseTokenToPSI();
    }
    function _sellFeeToPSI(address token) internal {
        uint256 tokenBalance = IERC20(token).balanceOf(address(this));
        require(tokenBalance > 0, "FeeAggregator: NO_FEE_TOKEN_BALANCE");
        if (token != baseToken && token != psi && tokenBalance > 0) {
            tokensGathered[token] = 0;
            address[] memory path = new address[](3);
            path[0] = token;
            path[1] = baseToken;
            path[2] = psi;
            IDPexRouter(router()).swapAggregatorToken(tokenBalance, path, address(this));
        } else if(token == baseToken) {
            _sellBaseTokenToPSI();
        }
    }
    function _sellBaseTokenToPSI() internal {
        uint256 balance = IERC20(baseToken).balanceOf(address(this));
        if (balance <= 0) return;

        tokensGathered[baseToken] = 0;
        address[] memory path = new address[](2);
        path[0] = baseToken;
        path[1] = psi;
        IDPexRouter(router()).swapAggregatorToken(balance, path, address(this));
    }
}