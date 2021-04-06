import chai, { expect } from 'chai'
import { BigNumber, constants, utils } from 'ethers'
import { ethers, waffle } from 'hardhat'
import { ecsign } from 'ethereumjs-util'

import { expandTo18Decimals, getApprovalDigest, mineBlock, MINIMUM_LIQUIDITY } from './shared/utilities'
import { v2Fixture } from './shared/fixtures'

import { DPexRouter, IWETH } from '@passive-income/dpex-peripheral/typechain'
import { IDPexPair } from '@passive-income/dpex-swap-core/typechain'
import { PSI, PSIGovernance, FeeAggregator } from '../typechain'

chai.use(waffle.solidity)

const overrides = {
  gasLimit: 9500000
}

describe('FeeAggregator', () => {
  const { provider, createFixtureLoader } = waffle;
  const [wallet] = provider.getWallets()
  const loadFixture = createFixtureLoader([wallet], provider)

  let psi: PSI
  let WETH: IWETH
  let router: DPexRouter
  let governance: PSIGovernance
  let feeAggregator: FeeAggregator
  let WETHPair: IDPexPair
  beforeEach(async function() {
    const fixture = await loadFixture(v2Fixture)
    psi = fixture.psi
    WETH = fixture.WETH
    router = fixture.router
    governance = fixture.governance
    feeAggregator = fixture.feeAggregator
    WETHPair = fixture.WETHPair
  })

  it('psi, WETH', async () => {
    expect(await feeAggregator.psi(overrides)).to.eq(psi.address)
    expect(await feeAggregator.baseToken(overrides)).to.eq(WETH.address)
  })

  it('addFeeTokens', async () => {
    expect((await feeAggregator.feeTokens(overrides)).length).to.eq(0);

    expect(await feeAggregator.isFeeToken(WETH.address, overrides)).to.eq(false)
    await feeAggregator.addFeeToken(WETH.address, overrides);
    expect(await feeAggregator.isFeeToken(WETH.address, overrides)).to.eq(true)
    await expect(feeAggregator.addFeeToken(WETH.address, overrides)).to.be.revertedWith("FeeAggregator: ALREADY_FEE_TOKEN")

    expect(await feeAggregator.isFeeToken(psi.address, overrides)).to.eq(false)
    await feeAggregator.addFeeToken(psi.address, overrides);
    expect(await feeAggregator.isFeeToken(psi.address, overrides)).to.eq(true)
    await expect(feeAggregator.addFeeToken(psi.address, overrides)).to.be.revertedWith("FeeAggregator: ALREADY_FEE_TOKEN")
  })

  it('removeFeeTokens', async () => {
    await expect(feeAggregator.removeFeeToken(WETH.address, overrides)).to.be.revertedWith("FeeAggregator: NO_FEE_TOKEN")
    await expect(feeAggregator.removeFeeToken(psi.address, overrides)).to.be.revertedWith("FeeAggregator: NO_FEE_TOKEN")

    await feeAggregator.addFeeToken(WETH.address, overrides);
    await feeAggregator.addFeeToken(psi.address, overrides);
    expect((await feeAggregator.feeTokens(overrides)).length).to.eq(2);

    await feeAggregator.removeFeeToken(WETH.address, overrides);
    await feeAggregator.removeFeeToken(psi.address, overrides);
    expect((await feeAggregator.feeTokens(overrides)).length).to.eq(0);
  })

  it('setDPexFee', async () => {
    expect(await feeAggregator.dpexFee(overrides)).to.eq(1);
    await feeAggregator.setDPexFee(200, overrides);
    expect(await feeAggregator.dpexFee(overrides)).to.eq(200);

    await expect(feeAggregator.setDPexFee(201, overrides)).to.be.revertedWith("FeeAggregator: FEE_MIN_0_MAX_20")
  })

  it('calculateFee', async () => {
    const psiAmount = BigNumber.from('1000');
    const expextedPSIAmount = BigNumber.from('999');
    const result = await feeAggregator.calculateFee(psi.address, psiAmount, overrides);
    console.log(result);
    // expect().to.eq(expextedPSIAmount);
  })

  it('addTokenFee', async () => {
    const psiFeeAmount = BigNumber.from('1000');
    await psi.approve(feeAggregator.address, utils.parseUnits('1000', 9))
    await feeAggregator.addTokenFee(psi.token, psiFeeAmount, overrides)

    expect(await feeAggregator.tokensGathered(psi.token, overrides)).to.eq(psiFeeAmount);
  })
})
