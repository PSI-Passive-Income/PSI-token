// SPDX-License-Identifier: GPL-3.0-or-later

// Based on the Reflector.Finance contract at https://github.com/reflectfinance/reflect-contracts

pragma solidity ^0.7.4;

import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IPSI.sol";

contract PSI is Context, IPSI, Ownable {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping (address => uint256) private _reflectedOwned;
    mapping (address => uint256) private _totalOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    EnumerableSet.AddressSet private _addressesExcludedFromFeeRetrieval;
    mapping (address => bool) private _addressesExcludedFromFeePayment;

    uint256 private _fee = 100; // 1% on default, x100;
   
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _totalWithoutReflection = 0.018183 * 10**6 * 10**9;
    uint256 private _totalWithReflection = (MAX - (MAX % _totalWithoutReflection));
    uint256 private _totalFees;

    string private _name = 'passive.income';
    string private _symbol = 'PSI';
    uint8 private _decimals = 9;

    constructor () {
        _totalOwned[_msgSender()] = _totalWithoutReflection;
        _reflectedOwned[_msgSender()] = _totalWithReflection;
        _addressesExcludedFromFeeRetrieval.add(_msgSender());
        _addressesExcludedFromFeePayment[_msgSender()] = true;
        emit Transfer(address(0), _msgSender(), _totalWithoutReflection);
    }

    //== BEP20 functions ==
    function totalSupply() public override pure returns (uint256) {
        return _totalWithoutReflection;
    }
    function decimals() public override view returns (uint8) {
        return _decimals;
    }
    function symbol() public override view returns (string memory) {
        return _symbol;
    }
    function getOwner() public override view returns (address) {
        return owner();
    }
    function name() public override view returns (string memory) {
        return _name;
    }
    function balanceOf(address account) public override view returns (uint256) {
        if (_addressesExcludedFromFeeRetrieval.contains(account)) return _totalOwned[account];
        return tokenFromReflection(_reflectedOwned[account]);
    }
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, 
            "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    //== Increase and decrease allowance ==
    function increaseAllowance(address spender, uint256 addedValue) public override virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public override virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, 
            "ERC20: decreased allowance below zero"));
        return true;
    }

    //== Approval ==
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    //== Include or Exclude account from earning fees ==
    function isExcludedFromFeeRetrieval(address account) public override view returns (bool) {
        return _addressesExcludedFromFeeRetrieval.contains(account);
    }
    function excludeAccountForFeeRetrieval(address account) external override onlyOwner() {
        require(!_addressesExcludedFromFeeRetrieval.contains(account), "PSI: Address already excluded");
        if(_reflectedOwned[account] > 0) {
            _totalOwned[account] = tokenFromReflection(_reflectedOwned[account]);
        }
        _addressesExcludedFromFeeRetrieval.add(account);
    }
    function includeAccountForFeeRetrieval(address account) external override onlyOwner() {
        require(_addressesExcludedFromFeeRetrieval.contains(account), "PSI: Address already included");
        _addressesExcludedFromFeeRetrieval.remove(account);
        _totalOwned[account] = 0;
    }
    function isExcludedFromFeePayment(address account) public override view returns (bool) {
        return _addressesExcludedFromFeePayment[account];
    }
    function excludeAccountFromFeePayment(address account) external override onlyOwner() {
        require(!_addressesExcludedFromFeePayment[account], "PSI: Address already excluded");
        _addressesExcludedFromFeePayment[account] = true;
    }
    function includeAccountFromFeePayment(address account) external override onlyOwner() {
        require(_addressesExcludedFromFeePayment[account], "PSI: Address already included");
        _addressesExcludedFromFeePayment[account] = false;
    }

    //== Fees ==
    function totalFees() public override view returns (uint256) {
        return _totalFees;
    }
    function changeFee(uint256 fee) external override onlyOwner() {
        _fee = fee;
    }

    //== Reflection ==
    function reflect(uint256 tAmount) public override {
        address sender = _msgSender();
        (uint256 rAmount,,,,) = _getValues(sender, tAmount);
        if (_addressesExcludedFromFeeRetrieval.contains(sender)) 
            _totalOwned[sender] = _totalOwned[sender].sub(tAmount);
        _reflectedOwned[sender] = _reflectedOwned[sender].sub(rAmount);
        _totalWithReflection = _totalWithReflection.sub(rAmount);
        _totalFees = _totalFees.add(tAmount);
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
        return rAmount.div(currentRate);
    }

    //== Transfer ==
    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "ERC20: Transfer amount must be greater than zero");
        if (_addressesExcludedFromFeeRetrieval.contains(sender) && 
            !_addressesExcludedFromFeeRetrieval.contains(recipient)) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_addressesExcludedFromFeeRetrieval.contains(sender) && 
            _addressesExcludedFromFeeRetrieval.contains(recipient)) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_addressesExcludedFromFeeRetrieval.contains(sender) && 
            !_addressesExcludedFromFeeRetrieval.contains(recipient)) {
            _transferStandard(sender, recipient, amount);
        } else if (_addressesExcludedFromFeeRetrieval.contains(sender) && 
            _addressesExcludedFromFeeRetrieval.contains(recipient)) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
    }
    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = 
            _getValues(sender, tAmount);
        _reflectedOwned[sender] = _reflectedOwned[sender].sub(rAmount);
        _reflectedOwned[recipient] = _reflectedOwned[recipient].add(rTransferAmount);       
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = 
            _getValues(sender, tAmount);
        _reflectedOwned[sender] = _reflectedOwned[sender].sub(rAmount);
        _totalOwned[recipient] = _totalOwned[recipient].add(tTransferAmount);
        _reflectedOwned[recipient] = _reflectedOwned[recipient].add(rTransferAmount);           
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = 
            _getValues(sender, tAmount);
        _totalOwned[sender] = _totalOwned[sender].sub(tAmount);
        _reflectedOwned[sender] = _reflectedOwned[sender].sub(rAmount);
        _reflectedOwned[recipient] = _reflectedOwned[recipient].add(rTransferAmount);   
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
        // exclude from transfer fee?
    }
    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = 
            _getValues(sender, tAmount);
        _totalOwned[sender] = _totalOwned[sender].sub(tAmount);
        _reflectedOwned[sender] = _reflectedOwned[sender].sub(rAmount);
        _totalOwned[recipient] = _totalOwned[recipient].add(tTransferAmount);
        _reflectedOwned[recipient] = _reflectedOwned[recipient].add(rTransferAmount);        
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _totalWithReflection = _totalWithReflection.sub(rFee);
        _totalFees = _totalFees.add(tFee);
    }

    //== Get fees and total and reflected values ==
    function _getValues(address sender, uint256 tAmount) private view 
    returns (uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee) = _getTotalValues(sender, tAmount);
        uint256 currentRate =  _getSupplyRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getReflectedValues(tAmount, tFee, currentRate);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee);
    }
    function _getTotalValues(address sender, uint256 tAmount) private view 
    returns (uint256, uint256) {
        if (_addressesExcludedFromFeePayment[sender]) return (tAmount, 0);
        uint256 tFee = tAmount.mul(_fee).div(10000);
        uint256 tTransferAmount = tAmount.sub(tFee);
        return (tTransferAmount, tFee);
    }
    function _getReflectedValues(uint256 tAmount, uint256 tFee, uint256 currentRate) private pure 
    returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee);
        return (rAmount, rTransferAmount, rFee);
    }

    //== Supply rate ==
    function _getSupplyRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }
    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _totalWithReflection;
        uint256 tSupply = _totalWithoutReflection;
        for (uint256 i = 0; i < _addressesExcludedFromFeeRetrieval.length(); i++) {
            if (_reflectedOwned[_addressesExcludedFromFeeRetrieval.at(i)] > rSupply || 
                _totalOwned[_addressesExcludedFromFeeRetrieval.at(i)] > tSupply) 
                return (_totalWithReflection, _totalWithoutReflection);
            
            rSupply = rSupply.sub(_reflectedOwned[_addressesExcludedFromFeeRetrieval.at(i)]);
            tSupply = tSupply.sub(_totalOwned[_addressesExcludedFromFeeRetrieval.at(i)]);
        }
        if (rSupply < _totalWithReflection.div(_totalWithoutReflection)) 
            return (_totalWithReflection, _totalWithoutReflection);

        return (rSupply, tSupply);
    }
}