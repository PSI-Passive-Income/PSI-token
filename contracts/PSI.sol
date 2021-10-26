// SPDX-License-Identifier: GPL-3.0-or-later

// Based on the Reflector.Finance contract at https://github.com/reflectfinance/reflect-contracts

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import "./interfaces/IDEXFactory.sol";
import "./interfaces/IDEXRouter.sol";
import "./interfaces/IPSI.sol";

contract PSI is Context, Ownable, ERC20, ERC20Permit, IPSI  {
    using SafeERC20 for IERC20;

    mapping (address => uint256) private _reflectedOwned;
    mapping (address => uint256) private _totalOwned;

    mapping (address => bool) private _addressesExcludedFromFeeRetrieval;
    mapping (address => bool) private _addressesExcludedFromFeePayment;

    uint256 public override reflectionFee = 100; // in basis points, so 1% on default;
    uint256 public override liquidityBuyFee = 100; // in basis points, so 1% on default;
    uint256 public override liquiditySellFee = 100; // in basis points, so 1% on default;
    uint256 public override swapTokensAtAmount = 5 * 10**9;
   
    uint256 private constant MAX = ~uint256(0);
    uint256 private _totalWithoutReflection;
    uint256 private _totalWithReflection;
    uint256 private _totalExcludedWithoutReflection;
    uint256 private _totalExcludedWithReflection;
    uint256 public override totalReflectionFees;

    bool public override swapEnabled;
    address public override oldPsiContract;

    IDEXRouter public override defaultDexRouter;
    address public override defaultPair;
    mapping(address => bool) public override dexPairs;
    address public override liquidityWallet;

    bool private _isSwappingFees;

    constructor (address _oldPsiContract, address _router) 
    ERC20('passive.income', 'PSI')
    ERC20Permit('passive.income') {
        oldPsiContract = _oldPsiContract;
        setAccountExcludedFromFees(_msgSender(), true);
        setAccountExcludedFromFeeRetrieval(_msgSender(), true);
        setAccountExcludedFromFees(address(this), true);
        setAccountExcludedFromFeeRetrieval(address(this), true);

        setLiquidityWallet(_msgSender());
        setDefaultRouter(_router);
    }

    //== ERC functions ==
    function totalSupply() public override(ERC20, IERC20) view returns (uint256) {
        return _totalWithoutReflection;
    }
    function decimals() public pure override(ERC20, IERC20Metadata) returns (uint8) {
        return 9;
    }
    function getOwner() public override view returns (address) {
        return owner();
    }

    function balanceOf(address account) public override(ERC20, IERC20) view returns (uint256) {
        if (isExcludedFromFeeRetrieval(account)) return _totalOwned[account];
        return tokenFromReflection(_reflectedOwned[account]);
    }

    //== Swap old contract ==
    function setSwapEnabled(bool value) external override onlyOwner {
        swapEnabled = value;
    }
    function swapOld() external override {
        require(swapEnabled, "PSI: SWAP_DISABLED");
        uint256 amount = IERC20(oldPsiContract).balanceOf(_msgSender());
        require(amount > 0, "PSI: NOTHING_TO_SWAP");
        IERC20(oldPsiContract).safeTransferFrom(_msgSender(), 0x000000000000000000000000000000000000dEaD, amount);
        _mint(_msgSender(), amount);
    }

    //== Include or Exclude account from earning fees ==
    function setAccountExcludedFromFees(address account, bool excluded) public override onlyOwner() {
        setAccountExcludedFromFeeRetrieval(account, excluded);
        setAccountExcludedFromFeePayment(account, excluded);
    }
    function isExcludedFromFeeRetrieval(address account) public override view returns (bool) {
        return _addressesExcludedFromFeeRetrieval[account];
    }
    function setAccountExcludedFromFeeRetrieval(address account, bool excluded) public override onlyOwner() {
        if (_addressesExcludedFromFeeRetrieval[account] != excluded) {
            if(excluded && _reflectedOwned[account] > 0) {
                _totalOwned[account] = tokenFromReflection(_reflectedOwned[account]);
                _totalExcludedWithoutReflection += _totalOwned[account];
                _totalExcludedWithReflection += _reflectedOwned[account];
            } else if (!excluded) {
                _totalExcludedWithoutReflection -= _totalOwned[account];
                _totalExcludedWithReflection -= _reflectedOwned[account];
                _totalOwned[account] = 0;
            }
            _addressesExcludedFromFeeRetrieval[account] = excluded;
        }
    }
    function isExcludedFromFeePayment(address account) public override view returns (bool) {
        return _addressesExcludedFromFeePayment[account];
    }
    function setAccountExcludedFromFeePayment(address account, bool excluded) public override onlyOwner() {
        if (_addressesExcludedFromFeePayment[account] != excluded) {
            _addressesExcludedFromFeePayment[account] = excluded;
        }
    }

    // Liquidity pairs
    function setDefaultRouter(address _router) public override onlyOwner {
        emit SetDefaultDexRouter(_router, address(defaultDexRouter));
        defaultDexRouter = IDEXRouter(_router);
        defaultPair = IDEXFactory(defaultDexRouter.factory()).createPair(address(this), defaultDexRouter.WETH());
        _setDexPair(defaultPair, true);
    }
    function setDexPair(address pair, bool value) external override onlyOwner {
        require(value || pair != defaultPair, 'PSI: PAIR_IS_DEFAULT');
        _setDexPair(pair, value);
    }
    function _setDexPair(address pair, bool value) private {
        require(dexPairs[pair] != value, 'PSI: ALREADY_SET');
        dexPairs[pair] = value;
        if (value) setAccountExcludedFromFeeRetrieval(pair, true);
        emit SetDexPair(pair, value);
    }
    function setLiquidityWallet(address newLiquidityWallet) public override onlyOwner {
        require(newLiquidityWallet != liquidityWallet, 'PSI: ALREADY_SET');
        emit SetLiquidityWallet(newLiquidityWallet, liquidityWallet);
        liquidityWallet = newLiquidityWallet;
    }

    //== Fees ==
    function setFees(
        uint256 _reflectionFee,
        uint256 _liquidityBuyFee,
        uint256 _liquiditySellFee
    ) external override onlyOwner() {
        reflectionFee = _reflectionFee;
        liquidityBuyFee = _liquidityBuyFee;
        liquiditySellFee = _liquiditySellFee;
    }
    function setSwapTokensAtAmount(uint256 _swapTokensAtAmount) external override onlyOwner() {
        swapTokensAtAmount = _swapTokensAtAmount;
    }

    //== Reflection ==
    function reflect(uint256 tAmount) public override {
        (uint256 rAmount,,,,) = _getValues(_msgSender(), tAmount);
        if (isExcludedFromFeeRetrieval(_msgSender())) _totalOwned[_msgSender()] -= tAmount;
        _reflectedOwned[_msgSender()] -= rAmount;
        _totalWithReflection -= rAmount;
        totalReflectionFees += tAmount;
    }
    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) external override view returns(uint256) {
        require(tAmount <= _totalWithoutReflection, "PSI: Amount cannot be higher then the total supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,) = _getValues(_msgSender(), tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,) = _getValues(_msgSender(), tAmount);
            return rTransferAmount;
        }
    }
    function tokenFromReflection(uint256 rAmount) public override view returns(uint256) {
        require(rAmount <= _totalWithReflection, "PSI: Amount must be less than total reflections");
        uint256 currentRate =  _getSupplyRate();
        return rAmount / currentRate;
    }

    //== Transfer ==
    function _transfer(address sender, address recipient, uint256 amount) internal override {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "ERC20: Transfer amount must be greater than zero");
        require(balanceOf(sender) >= amount, "ERC20: transfer amount exceeds balance");

        amount = _collectLiquidityFee(sender, recipient, amount);
        _transferWithReflection(sender, recipient, amount);
    }
    function _collectLiquidityFee(address sender, address recipient, uint256 amount) private returns (uint256) {
        if (!_isSwappingFees && !isExcludedFromFeePayment(sender) && !isExcludedFromFeePayment(recipient)) {
            uint256 fees;
            if (dexPairs[sender]) fees = (amount * liquidityBuyFee) / 10000;
            else if (dexPairs[recipient]) fees = (amount * liquiditySellFee) / 10000;

            amount -= fees;
            super._transfer(sender, address(this), fees);

            _swapFeesIfAmountIsReached(sender, recipient);
        }
        return amount;
    }
    function _transferWithReflection(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = 
            _getValues(sender, tAmount);

        _reflectedOwned[sender] -= rAmount;
        if (_addressesExcludedFromFeeRetrieval[sender]) {
            _totalOwned[sender] -= tAmount;
            _totalExcludedWithoutReflection -= tAmount;
            _totalExcludedWithReflection -= rAmount;
        }

        _reflectedOwned[recipient] += rTransferAmount;
        if (_addressesExcludedFromFeeRetrieval[recipient]) {
            _totalOwned[recipient] += tTransferAmount;
            _totalExcludedWithoutReflection += tTransferAmount;
            _totalExcludedWithReflection += rTransferAmount;
        }

        _totalWithReflection -= rFee;
        totalReflectionFees += tFee;
        
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _swapFeesIfAmountIsReached(address sender, address recipient) private {
        uint256 contractTokenBalance = balanceOf(address(this));
        
        if (
            contractTokenBalance >= swapTokensAtAmount &&
            !_isSwappingFees &&
            !dexPairs[sender] && // do not swap fees on buys
            sender != liquidityWallet &&
            recipient != liquidityWallet
        ) {
            _isSwappingFees = true;
            swapAndLiquify(contractTokenBalance);
            _isSwappingFees = false;
        }
    }
    function swapAndLiquify(uint256 tokens) private {
        uint256 initialBalance = address(this).balance;
        swapTokensForEth(tokens / 2);
        addLiquidity(tokens / 2, address(this).balance - initialBalance);
        emit SwapAndLiquify(tokens / 2, address(this).balance - initialBalance);
    }
    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = defaultDexRouter.WETH();

        _approve(address(this), address(defaultDexRouter), tokenAmount);

        // make the swap
        defaultDexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(defaultDexRouter), tokenAmount);

        // add the liquidity
        defaultDexRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            liquidityWallet,
            block.timestamp
        );
    }

    //== Get fees, total value and reflected values ==
    function _getValues(address sender, uint256 tAmount) private view 
    returns (uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee) = _getTotalValues(sender, tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getReflectedValues(tAmount, tFee, _getSupplyRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee);
    }
    function _getTotalValues(address sender, uint256 tAmount) private view 
    returns (uint256, uint256) {
        if (_addressesExcludedFromFeePayment[sender]) return (tAmount, 0);
        uint256 tFee = (tAmount * reflectionFee) / 10000;
        return ((tAmount - tFee), tFee);
    }
    function _getReflectedValues(uint256 tAmount, uint256 tFee, uint256 currentRate) private pure 
    returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount * currentRate;
        uint256 rFee = tFee * currentRate;
        return (rAmount, (rAmount - rFee), rFee);
    }

    //== Supply rate ==
    function _getSupplyRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / tSupply;
    }
    function _getCurrentSupply() private view returns(uint256 rSupply, uint256 tSupply) {
        if (_totalExcludedWithReflection > _totalWithReflection || 
            _totalExcludedWithoutReflection > _totalWithoutReflection ||
            (_totalWithReflection - _totalExcludedWithReflection) < (_totalWithReflection / _totalWithoutReflection))
            return (_totalWithReflection, _totalWithoutReflection);

        return (
            _totalWithReflection - _totalExcludedWithReflection,
            _totalWithoutReflection - _totalExcludedWithoutReflection
        );
    }

    //== Mint and Burn ==
    function _mint(address account, uint256 amount) internal override {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalWithoutReflection += amount;
        _totalWithReflection = (MAX - (MAX % _totalWithoutReflection));

        if (_addressesExcludedFromFeeRetrieval[account]) _totalOwned[account] += amount;
        _reflectedOwned[account] += amount * _getSupplyRate();
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }
}