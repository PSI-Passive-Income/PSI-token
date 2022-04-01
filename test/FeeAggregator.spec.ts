import chai, { expect } from 'chai'
import { BigNumber, constants, utils } from 'ethers'
import { ethers, waffle } from 'hardhat'
import { ecsign, MAX_INTEGER } from 'ethereumjs-util'

import { expandTo18Decimals, getApprovalDigest, mineBlock, MINIMUM_LIQUIDITY } from './shared/utilities'
import { v2Fixture } from './shared/fixtures'

import { DPexRouter } from '@passive-income/dpex-peripheral/typechain'
import { IDPexPair } from '@passive-income/dpex-swap-core/typechain'
import { PSI, PSIGovernance, FeeAggregator, WBNB } from '../typechain'

chai.use(waffle.solidity)

const overrides = {
  gasLimit: 9500000
}

describe('FeeAggregator', () => {
  const { provider, createFixtureLoader } = waffle;
  const [owner,user] = provider.getWallets()
  const loadFixture = createFixtureLoader([owner], provider)

  let psi: PSI
  let WBNB: WBNB
  let governance: PSIGovernance
  let feeAggregator: FeeAggregator
  beforeEach(async function() {
    const fixture = await loadFixture(v2Fixture)
    psi = fixture.psi
    WBNB = fixture.WBNB
    governance = fixture.governance
    feeAggregator = fixture.feeAggregator

    await psi.setSwapEnabled(true)
    await fixture.psiv1.approve(psi.address, constants.MaxInt256)
    await psi.swapOld()
  })

  it('psi, WETH', async () => {
    expect(await feeAggregator.psi(overrides)).to.eq(psi.address)
    expect(await feeAggregator.baseToken(overrides)).to.eq(WBNB.address)
  })

  it('addFeeTokens', async () => {
    expect((await feeAggregator.feeTokens(overrides)).length).to.eq(0);

    expect(await feeAggregator.isFeeToken(WBNB.address, overrides)).to.eq(false)
    await feeAggregator.addFeeToken(WBNB.address, overrides);
    expect(await feeAggregator.isFeeToken(WBNB.address, overrides)).to.eq(true)
    await expect(feeAggregator.addFeeToken(WBNB.address, overrides)).to.be.revertedWith("FeeAggregator: ALREADY_FEE_TOKEN")

    expect(await feeAggregator.isFeeToken(psi.address, overrides)).to.eq(false)
    await feeAggregator.addFeeToken(psi.address, overrides);
    expect(await feeAggregator.isFeeToken(psi.address, overrides)).to.eq(true)
    await expect(feeAggregator.addFeeToken(psi.address, overrides)).to.be.revertedWith("FeeAggregator: ALREADY_FEE_TOKEN")
  })

  it('removeFeeTokens', async () => {
    await expect(feeAggregator.removeFeeToken(WBNB.address, overrides)).to.be.revertedWith("FeeAggregator: NO_FEE_TOKEN")
    await expect(feeAggregator.removeFeeToken(psi.address, overrides)).to.be.revertedWith("FeeAggregator: NO_FEE_TOKEN")

    await feeAggregator.addFeeToken(WBNB.address, overrides);
    await feeAggregator.addFeeToken(psi.address, overrides);
    expect((await feeAggregator.feeTokens(overrides)).length).to.eq(2);

    await feeAggregator.removeFeeToken(WBNB.address, overrides);
    await feeAggregator.removeFeeToken(psi.address, overrides);
    expect((await feeAggregator.feeTokens(overrides)).length).to.eq(0);
  })

  it('setDPexFee', async () => {
    expect(await feeAggregator.dpexFee(overrides)).to.eq(1);
    await feeAggregator.setDPexFee(200, overrides);
    expect(await feeAggregator.dpexFee(overrides)).to.eq(200);

    await expect(feeAggregator.setDPexFee(201, overrides)).to.be.revertedWith("FeeAggregator: FEE_MIN_0_MAX_20")
  })

  it('addEthereumFee', async () => {
    await feeAggregator.addFeeToken(WBNB.address, overrides);

    const amount = ethers.utils.parseEther('0.1')
    await (await user.sendTransaction({ to: feeAggregator.address, value: amount })).wait()
    expect(await feeAggregator.tokensGathered(WBNB.address, overrides)).to.eq(amount);
  })

  it('calculateFee', async () => {
    const psiAmount = utils.parseUnits('1000', 9);
    const expextedPSIAmount = utils.parseUnits('999', 9);
    await feeAggregator.addFeeToken(psi.address, overrides);
    const result = await feeAggregator['calculateFee(address,uint256)'](psi.address, psiAmount, overrides);
    expect(result.fee).to.eq(utils.parseUnits('1', 9));
    expect(result.amountLeft).to.eq(expextedPSIAmount);
  })

  it('addTokenFee', async () => {
    const psiFeeAmount = utils.parseUnits('10', 9);
    await feeAggregator.addFeeToken(psi.address, overrides);
    await psi.transfer(feeAggregator.address, utils.parseUnits('10', 9))
    await feeAggregator.addTokenFee(psi.address, psiFeeAmount, overrides)
    expect(await feeAggregator.tokensGathered(psi.address, overrides)).to.eq(psiFeeAmount);
  })
})
