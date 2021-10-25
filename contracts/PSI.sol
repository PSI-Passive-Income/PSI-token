// SPDX-License-Identifier: GPL-3.0-or-later

// Based on the Reflector.Finance contract at https://github.com/reflectfinance/reflect-contracts

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import "./interfaces/IPSI.sol";

contract PSI is Context, Ownable, ERC20, IPSI  {
    mapping (address => uint256) private _reflectedOwned;
    mapping (address => uint256) private _totalOwned;

    mapping (address => bool) private _addressesExcludedFromFeeRetrieval;
    mapping (address => bool) private _addressesExcludedFromFeePayment;

    uint256 private reflectionFee = 100; // 1% on default, x100;
   
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _totalWithoutReflection = 0.018183 * 10**6 * 10**9;
    uint256 private _totalWithReflection = (MAX - (MAX % _totalWithoutReflection));
    uint256 private _totalExcludedWithoutReflection = 0;
    uint256 private _totalExcludedWithReflection = 0;
    uint256 private _totalFees;

    constructor () 
    ERC20('passive.income', 'PSI') {
        _reflectedOwned[_msgSender()] = _totalWithReflection;
        setAccountExcludedFromFees(_msgSender(), true);
        emit Transfer(address(0), _msgSender(), _totalWithoutReflection);
    }

    //== ERC functions ==
    function totalSupply() public override(ERC20, IERC20) pure returns (uint256) {
        return _totalWithoutReflection;
    }
    function decimals() public pure override(ERC20, IERC20Metadata) returns (uint8) {
        return 9;
    }
    function getOwner() public override view returns (address) {
        return owner();
    }

    function balanceOf(address account) public override(ERC20, IERC20) view returns (uint256) {
        if (_addressesExcludedFromFeeRetrieval[account]) return _totalOwned[account];
        return tokenFromReflection(_reflectedOwned[account]);
    }

    //== Include or Exclude account from earning fees ==
    function setAccountExcludedFromFees(address account, bool excluded) public override onlyOwner() {
        setAccountExcludedFromFeeRetrieval(account, excluded);
        setAccountExcludedFromFeePayment(account, excluded);
    }
    function isExcludedFromFeeRetrieval(address account) external override view returns (bool) {
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
    function isExcludedFromFeePayment(address account) external override view returns (bool) {
        return _addressesExcludedFromFeePayment[account];
    }
    function setAccountExcludedFromFeePayment(address account, bool excluded) public override onlyOwner() {
        if (_addressesExcludedFromFeePayment[account] != excluded) {
            _addressesExcludedFromFeePayment[account] = excluded;
        }
    }

    //== Fees ==
    function totalFees() public override view returns (uint256) {
        return _totalFees;
    }
    function setReflectionFee(uint256 fee) external override onlyOwner() {
        reflectionFee = fee;
    }

    //== Reflection ==
    function reflect(uint256 tAmount) public override {
        address sender = _msgSender();
        (uint256 rAmount,,,,) = _getValues(sender, tAmount);
        if (_addressesExcludedFromFeeRetrieval[sender]) 
            _totalOwned[sender] = _totalOwned[sender] - tAmount;
        _reflectedOwned[sender] = _reflectedOwned[sender] - rAmount;
        _totalWithReflection = _totalWithReflection - rAmount;
        _totalFees = _totalFees + tAmount;
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
        
        _transferWithReflection(sender, recipient, amount);
    }
    function _transferWithReflection(address sender, address recipient, uint256 tAmount) internal {
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
        _totalFees += tFee;
        
        emit Transfer(sender, recipient, tTransferAmount);
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

        return (_totalWithReflection - _totalExcludedWithReflection, _totalWithoutReflection - _totalExcludedWithoutReflection);
    }
}