import chai, { expect } from 'chai'
import { BigNumber, constants, utils } from 'ethers'
import { ethers, waffle } from 'hardhat'
import { ecsign } from 'ethereumjs-util'

import { expandTo18Decimals, getApprovalDigest, mineBlock, MINIMUM_LIQUIDITY } from './shared/utilities'
import { v2Fixture } from './shared/fixtures'

import { Income, IncomeMinter } from '../typechain'

chai.use(waffle.solidity)

const overrides = {
  gasLimit: 9500000
}
const startSupply = expandTo18Decimals(3120000)

describe('Income', () => {
  const { provider, createFixtureLoader } = waffle;
  const [wallet,account] = provider.getWallets()
  const loadFixture = createFixtureLoader([wallet], provider)

  let income: Income
  let incomeMinter: IncomeMinter
  beforeEach(async function() {
    const fixture = await loadFixture(v2Fixture)
    income = fixture.income
    incomeMinter = fixture.incomeMinter
  })

  it('Details', async () => {
    expect(await income.name()).to.eq("Income")
    expect(await income.symbol()).to.eq("INC")
    expect(await income.decimals()).to.eq(18)
    expect(await income.totalSupply()).to.eq(startSupply)
    expect(await income.balanceOf(wallet.address)).to.eq(startSupply)
  })

  describe('Governor', () => {
    it('Current governor is contract creator', async () => {
      expect(await income.governor()).to.eq(wallet.address)
    })
    it('Not available from a non owner or governor', async () => {
      await expect(income.connect(account).setGovernor(account.address, overrides)).to.be.revertedWith("INCOME: caller is not the governor or owner")
    })
    it('Set and reset from owner or governor', async () => {
      await income.setGovernor(account.address, overrides)

      expect(await income.governor()).to.eq(account.address)
      await income.connect(account).setGovernor(wallet.address, overrides)
      expect(await income.governor()).to.eq(wallet.address)

      await expect(income.connect(account).setGovernor(account.address, overrides)).to.be.revertedWith("INCOME: caller is not the governor or owner")
    })
  })

  describe('Minting', () => {
    const toMint = expandTo18Decimals(300000)

    it('Not available from wallet', async () => {
      await expect(income.mint(toMint, overrides)).to.be.revertedWith("INCOME: caller is not a minting contract")
    })
    it('Owner is not a minting contract', async () => {
      expect(await income.isMintingContract(wallet.address, overrides)).to.eq(false)
    })
    it('IncomeMinter is not yet a minting contract', async () => {
      expect(await income.isMintingContract(incomeMinter.address, overrides)).to.eq(false)
    })
    it('Add minting contract only possible for owner', async () => {
      await expect(income.connect(account).addMintingContract(incomeMinter.address, overrides)).to.be.revertedWith("Ownable: caller is not the owner")
      await income.addMintingContract(incomeMinter.address, overrides)
    })
    it('Removing minting contract only possible for owner', async () => {
      await income.addMintingContract(incomeMinter.address, overrides);
      await expect(income.connect(account).removeMintingContract(incomeMinter.address, overrides)).to.be.revertedWith("Ownable: caller is not the owner")
      await income.removeMintingContract(incomeMinter.address, overrides)
    })
    it('Only contracts can be added as minting contract', async () => {
      await expect(income.addMintingContract(account.address, overrides)).to.be.revertedWith("INCOME: `mintingContract` is not a contract")
    })
    it('Contract can only be added once', async () => {
      await income.addMintingContract(incomeMinter.address, overrides)
      await expect(income.addMintingContract(incomeMinter.address, overrides)).to.be.revertedWith("INCOME: `mintingContract` is already a minting contract")
    })
    it('Contract can only be removed once added', async () => {
      await expect(income.removeMintingContract(incomeMinter.address, overrides)).to.be.revertedWith("INCOME: `mintingContract` is not a minting contract")
    })
    it('Minting tokens is possible from the minting contract', async () => {
      await income.addMintingContract(incomeMinter.address, overrides);
      await expect(incomeMinter.mintIncome(toMint))
        .to.emit(income, 'Transfer')
        .withArgs(constants.Zero, incomeMinter.address, toMint)
      
      expect(await income.totalSupply()).to.eq(startSupply.add(toMint))
      expect(await income.balanceOf(incomeMinter.address)).to.eq(toMint)
    })
  })

  describe('Burning and burn rate', () => {
    const toBurn = expandTo18Decimals(300000)

    it('Total burned should be 0 from the start', async () => {
      expect(await income.totalBurned(overrides)).to.eq(0)
    })
    it('Burn rate should be 1% from the start', async () => {
      expect(await income.burnRate(overrides)).to.eq(100)
    })
    it('Burn rate can only get changed by an governor', async () => {
      await expect(income.connect(account).changeBurnRate(50, overrides)).to.be.revertedWith("INCOME: caller is not a governor")
      await income.setGovernor(account.address, overrides)
      await income.connect(account).changeBurnRate(50, overrides)
    })
    it('Burn rate can only get set between 50 (0.5%) and 300 (3%)', async () => {
      await expect(income.changeBurnRate(49, overrides)).to.be.revertedWith("INCOME: Min token fee is 0.5%")
      await income.changeBurnRate(50, overrides)
      await expect(income.changeBurnRate(301, overrides)).to.be.revertedWith("INCOME: Max token fee is 3%")
      await income.changeBurnRate(300, overrides)
    })
    it('Cannot burn more than a wallet`s holdings', async () => {
      await expect(income.connect(account).burn(1, overrides)).to.be.revertedWith("INCOME: burn amount exceeds balance")
    })
    it('Burning should update total burned', async () => {
      await expect(income.burn(toBurn, overrides))
        .to.emit(income, 'Transfer')
        .withArgs(wallet.address, constants.Zero, toBurn)
      expect(await income.totalBurned(overrides)).to.eq(toBurn)
    })
  })

  describe('Transfer', () => {
    const toTransfer = expandTo18Decimals(1000)
    const burned = expandTo18Decimals(10)

    it('Contract creator should not have a burn rate (for distribution)', async () => {
      await expect(income.transfer(account.address, toTransfer, overrides))
        .to.emit(income, 'Transfer')
        .withArgs(wallet.address, account.address, toTransfer)
      expect(await income.totalBurned(overrides)).to.eq(0)
      expect(await income.balanceOf(account.address)).to.eq(toTransfer)
    })
    it('Normal wallet should have a burn rate', async () => {
      await expect(income.transfer(account.address, toTransfer, overrides))
        .to.emit(income, 'Transfer')
        .withArgs(wallet.address, account.address, toTransfer)
      expect(await income.balanceOf(account.address)).to.eq(toTransfer)

      await expect(income.connect(account).transfer(wallet.address, toTransfer, overrides))
        .to.emit(income, 'Transfer')
        .withArgs(account.address, wallet.address, toTransfer)
      expect(await income.totalBurned(overrides)).to.eq(burned)
      expect(await income.totalSupply(overrides)).to.eq(startSupply.sub(burned))
      expect(await income.balanceOf(wallet.address)).to.eq(startSupply.sub(burned))
    })
  })

  describe('In- or exclude address for burn rates', () => {
    const toTransfer = expandTo18Decimals(1000)

    it('Contract creator is already excluded', async () => {
      expect(await income.isAddressExcludedFromBurnRate(wallet.address, overrides)).to.eq(true)
    })
    it('Normal address is not excluded', async () => {
      expect(await income.isAddressExcludedFromBurnRate(account.address, overrides)).to.eq(false)
    })
    it('Normal address is not able to in- or exclude wallet', async () => {
      await expect(income.connect(account).setAddressExcludedFromBurnRate(account.address, true, overrides)).to.be.revertedWith("Ownable: caller is not the owner")
      await expect(income.connect(account).setAddressExcludedFromBurnRate(wallet.address, false, overrides)).to.be.revertedWith("Ownable: caller is not the owner")
    })
    it('Owner is able to exclude wallet', async () => {
      await income.setAddressExcludedFromBurnRate(account.address, true, overrides);
      await income.transfer(account.address, toTransfer, overrides)
      await expect(income.connect(account).transfer(wallet.address, toTransfer, overrides))
        .to.emit(income, 'Transfer')
        .withArgs(account.address, wallet.address, toTransfer)
      expect(await income.totalBurned(overrides)).to.eq(0)
      expect(await income.balanceOf(wallet.address)).to.eq(startSupply)
    })
  })
})
