// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.7.4;

import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IIncome.sol";

contract Income is Context, IIncome, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    string private _name = 'Income';
    string private _symbol = 'INC';
    uint8 private _decimals = 18;

    uint256 private _burnedSupply;
    uint256 private _currentSupply;

    mapping (address => bool) private _mintingContracts;
    address private _governor;
    uint256 private _burnRate = 100; // 1% on default, x100;
    mapping (address => bool) private _addressesExcludedFromBurnRate;

    constructor() {
        // initial supply op 3.12M. new tokens can only be minted by creating new farms 
        _currentSupply = 3120000 * 10**_decimals;
        _balances[_msgSender()] = _currentSupply;
        _governor = _msgSender();
        _addressesExcludedFromBurnRate[_msgSender()] = true;
        emit Transfer(address(0), msg.sender, _currentSupply);
    }

    //== Modifiers ==
    modifier onlyMintingContract() {
        require(_mintingContracts[_msgSender()], "INCOME: caller is not a minting contract");
        _;
    }
    modifier onlyGovernor() {
        require(_msgSender() == _governor, "INCOME: caller is not a governor");
        _;
    }

    //== Bep20 functions ==
    function getOwner() external override view returns (address) {
        return owner();
    }
    function decimals() external override view returns (uint8) {
        return _decimals;
    }
    function symbol() external override view returns (string memory) {
        return _symbol;
    }
    function name() external override view returns (string memory) {
        return _name;
    }
    function totalSupply() external override view returns (uint256) {
        return _currentSupply;
    }
    function balanceOf(address account) external override view returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) external override view returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]
            .sub(amount, "INCOME: transfer amount exceeds allowance"));
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender]
            .sub(subtractedValue, "INCOME: decreased allowance below zero"));
        return true;
    }

    // == Governor
    function governor() external override view returns (address) {
        return _governor;
    }
    /**
    * @dev Adds a minting contract to minting allowance.
    *
    * Requirements
    *
    * - `msg.sender` must be the current governor
    */
    function setGovernor(address newGovernor) external override returns (bool) {
        require(_msgSender() == _governor || _msgSender() == owner(), "INCOME: caller is not the governor or owner");
        _governor = newGovernor;
        return true;
    }

    //== Minting ==
    /**
    * @dev Adds a minting contract to minting allowance.
    *
    * Requirements
    *
    * - `msg.sender` must be the contract owner
    * - `mintingContract` should be a contract
    * - `mintingContract` should not be a minting contract aldready
    */
    function addMintingContract(address mintingContract) external override onlyOwner returns (bool) {
        require(mintingContract.isContract(), "INCOME: `mintingContract` is not a contract");
        require(!_mintingContracts[mintingContract], "INCOME: `mintingContract` is already a minting contract");
        _mintingContracts[mintingContract] = true;
        return true;
    }
    /**
    * @dev Removes a minting contract from minting allowance.
    *
    * Requirements
    *
    * - `msg.sender` must be the contract owner
    * - `mintingContract` should be a minting contract
    */
    function removeMintingContract(address mintingContract) external override onlyOwner returns (bool) {
        require(_mintingContracts[mintingContract], "INCOME: `mintingContract` is not a minting contract");
        _mintingContracts[mintingContract] = false;
        return true;
    }
    /**
    * @dev Checks if the contact is a minting contract.
    */
    function isMintingContract(address mintingContract) external override view returns (bool) {
        return _mintingContracts[mintingContract];
    }
    /**
    * @dev Creates `amount` tokens and assigns them to `msg.sender`, increasing the total supply.
    *
    * Requirements
    *
    * - `msg.sender` must be a minting contract
    */
    function mint(uint256 amount) external override onlyMintingContract returns (bool) {
        _mint(_msgSender(), amount);
        return true;
    }
    /** @dev Creates `amount` tokens and assigns them to `account`, increasing the total supply.
    *
    * Emits a {Transfer} event with `from` set to the zero address.
    *
    * Requirements
    *
    * - `to` cannot be the zero address.
    */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "INCOME: mint to the zero address");
        _currentSupply = _currentSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    //== Burning ==
    /**
    * @dev The total amount of tokens burned.
    */
    function totalBurned() external override view returns (uint256) {
        return _burnedSupply;
    }
    /**
    * @dev The current burn rate.
    */
    function burnRate() external override view returns (uint256) {
        return _burnRate;
    }
    /**
    * @dev Changing the rate which is burned on every transfer.
    *
    * Requirements
    *
    * - `msg.sender` must be an governor.
    * - `newBurnRate` must be between 50 (0.5%) and 300 (3%).
    */
    function changeBurnRate(uint256 newBurnRate) external override onlyGovernor() returns (bool) {
        require(newBurnRate >= 50, "INCOME: Min token fee is 0.5%");
        require(newBurnRate <= 300, "INCOME: Max token fee is 3%");
        _burnRate = newBurnRate;
        return true;
    }
    /**
    * @dev Destroys `amount` tokens tokens from `msg.sender`, reducing the total supply.
    *
    * Requirements
    *
    * - `msg.sender` must have at least `amount` tokens.
    */
    function burn(uint256 amount) external override returns (bool) {
        _burn(_msgSender(), amount);
        return true;
    }
    /**
    * @dev Destroys `amount` tokens from `account`, reducing the total supply.
    *
    * Emits a {Transfer} event with `to` set to the zero address.
    *
    * Requirements
    *
    * - `account` cannot be the zero address.
    * - `account` must have at least `amount` tokens.
    */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "INCOME: burn from the zero address");
        _balances[account] = _balances[account].sub(amount, "INCOME: burn amount exceeds balance");
        _currentSupply = _currentSupply.sub(amount);
        _burnedSupply = _burnedSupply.add(amount);
        emit Transfer(account, address(0), amount);
    }

    //== Exclude address for burn rate ==
    /**
    * @dev Include or Exclude an address from paying the burn rate.
    *
    * Requirements
    *
    * - `msg.sender` must be the contract owner.
    */
    function setAddressExcludedFromBurnRate(address account, bool excluded) 
        external override onlyOwner() returns (bool) 
    {
        _addressesExcludedFromBurnRate[account] = excluded;
        return true;
    }
    /**
    * @dev Check if an address is excluded from paying the burn rate.
    */
    function isAddressExcludedFromBurnRate(address account) external override view returns (bool) {
        return _addressesExcludedFromBurnRate[account];
    }

    //== Transfer and Approval
    /**
    * @dev Moves tokens `amount` from `sender` to `recipient`.
    *
    * This is internal function is equivalent to {transfer}, and can be used to
    * e.g. implement automatic token fees, slashing mechanisms, etc.
    *
    * Emits a {Transfer} event.
    *
    * Requirements:
    *
    * - `sender` cannot be the zero address.
    * - `recipient` cannot be the zero address.
    * - `sender` must have a balance of at least `amount`.
    */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "INCOME: transfer from the zero address");
        require(recipient != address(0), "INCOME: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "INCOME: transfer amount exceeds balance");
        
        uint256 toBurn;
        if (!_addressesExcludedFromBurnRate[sender]) {
            toBurn = amount.mul(_burnRate).div(10000);
            if (toBurn > 0) {
                _burnedSupply = _burnedSupply.add(toBurn);
                _currentSupply = _currentSupply.sub(toBurn);
                amount = amount.sub(toBurn);
            }
        }

        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount.add(toBurn));
    }

    /**
    * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
    *
    * This is internal function is equivalent to `approve`, and can be used to
    * e.g. set automatic allowances for certain subsystems, etc.
    *
    * Emits an {Approval} event.
    *
    * Requirements:
    *
    * - `owner` cannot be the zero address.
    * - `spender` cannot be the zero address.
    */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "INCOME: approve from the zero address");
        require(spender != address(0), "INCOME: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}