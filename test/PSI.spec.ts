import chai, { expect } from 'chai'
import { BigNumber, constants, utils } from 'ethers'
import { ethers, network, waffle } from 'hardhat'

import { expandTo18Decimals, expandTo9Decimals } from './shared/utilities'
import { v2Fixture } from './shared/fixtures'

import { DPexRouter, DPexRouterPairs, IWETH } from '@passive-income/dpex-peripheral/typechain'
import { DPexFactory, IDPexPair } from '@passive-income/dpex-swap-core/typechain'
import { PSI, PSIv1, Income, IncomeMinter, PSIGovernance, FeeAggregator, PancakeFactory, WBNB, PancakeRouter, IPancakePair } from '../typechain'
import mocha from 'mocha'

chai.use(waffle.solidity)

describe('PSI', () => {
  const { provider, createFixtureLoader } = waffle;
  const [ owner, user1, user2, user3 ] = provider.getWallets()
  const loadFixture = createFixtureLoader([owner], provider)

  let buyPath: string[] = []
  let sellPath: string[] = []

  let psi: PSI
  let psiv1: PSIv1
  let income: Income
  let incomeMinter: IncomeMinter
  let WBNB: WBNB
  let factory: PancakeFactory
  let router: PancakeRouter
  let governance: PSIGovernance
  let feeAggregator: FeeAggregator
  let pair: IPancakePair
  beforeEach(async function() {
    const fixture = await loadFixture(v2Fixture)
    WBNB = fixture.WBNB
    factory = fixture.pcFactory
    router = fixture.pcRouter
    psi = fixture.psi
    psiv1 = fixture.psiv1
    pair = fixture.WBNBPair

    buyPath = [ WBNB.address, psi.address ]
    sellPath = [ psi.address, WBNB.address ]

    await psiv1.excludeAccountForFeeRetrieval(psi.address)
    await psiv1.excludeAccountFromFeePayment(psi.address)
    await psiv1.transferOwnership(psi.address)
    await psi.callOld(psiv1.interface.encodeFunctionData("excludeAccountForFeeRetrieval", ["0x000000000000000000000000000000000000dEaD"]))
    await psi.callOld(psiv1.interface.encodeFunctionData("excludeAccountFromFeePayment", ["0x000000000000000000000000000000000000dEaD"]))
  })

  const userSupply = expandTo9Decimals(1000)
  const maxSupply = expandTo9Decimals(18183)
  const ethLiquidity = expandTo18Decimals(5)
  const tokenLiquidity = expandTo9Decimals(1000)
  let startLiquidityBalance: BigNumber
  const swapv1 = async() => {
    await psi.setSwapEnabled(true)
    await psiv1.approve(psi.address, maxSupply)
    await psi.swapOld()
    await psi.transfer(user1.address, userSupply)
  }
  const addTokenLiquidity = async() => {
    await swapv1()
    await psi.approve(router.address, constants.MaxUint256);
    await router.addLiquidityETH(psi.address, tokenLiquidity, tokenLiquidity, ethLiquidity, owner.address, constants.MaxUint256, { value: ethLiquidity });
    startLiquidityBalance = await pair.balanceOf(owner.address)
  }
  const liqBalanceAdded = async() => (await pair.balanceOf(owner.address)).sub(startLiquidityBalance)

  it('Deployed correctly', async () => {
    expect(await psi.defaultDexRouter()).to.eq(router.address)
    expect(await psi.dexPairs(await psi.defaultPair())).to.eq(true)
    expect(await psi.liquidityWallet()).to.eq(owner.address)
    expect(await psi.swapEnabled()).to.eq(false)
    expect(await psi.totalSupply()).to.eq(0)
  })

  describe('Swap', () => {
    it('Fails without tokens', async () => {
      await expect(psi.connect(user1).swapOld()).to.be.revertedWith("PSI: NOTHING_TO_SWAP")
    })
    it('Fails by user when swap disabled', async () => {
      await psiv1.transfer(user1.address, expandTo9Decimals(10))
      await expect(psi.connect(user1).swapOld()).to.be.revertedWith("PSI: SWAP_DISABLED")
    })
    it('Succeeds for owner when swap disabled', async () => {
      await psiv1.approve(psi.address, expandTo9Decimals(10))
      await psi.swapOldAmount(expandTo9Decimals(10))
      expect(await psi.totalSupply()).to.eq(expandTo9Decimals(10))
      expect(await psi.balanceOf(owner.address)).to.eq(expandTo9Decimals(10))
      expect(await psiv1.balanceOf("0x000000000000000000000000000000000000dEaD")).to.eq(expandTo9Decimals(10))
    })
    it('Succeeds for user when swap enabled', async () => {
      await psiv1.transfer(user1.address, expandTo9Decimals(10))
      await psiv1.connect(user1).approve(psi.address, expandTo9Decimals(10))
      await psiv1.transfer(user2.address, expandTo9Decimals(10))
      await psiv1.connect(user2).approve(psi.address, expandTo9Decimals(10))

      await psi.setSwapEnabled(true)
      await psi.connect(user1).swapOldAmount(expandTo9Decimals(10))
      await psi.connect(user2).swapOldAmount(expandTo9Decimals(10))
      expect(await psi.totalSupply()).to.eq(expandTo9Decimals(20))
      expect(await psi.balanceOf(user1.address)).to.eq(expandTo9Decimals(10))
      expect(await psi.balanceOf(user2.address)).to.eq(expandTo9Decimals(10))
      expect(await psiv1.balanceOf("0x000000000000000000000000000000000000dEaD")).to.eq(expandTo9Decimals(20))
    })
    it('Succeeds for all with transfers in between enabled', async () => {
      await psi.setSwapEnabled(true)
      await psiv1.transfer(user1.address, expandTo9Decimals(10))
      await psiv1.connect(user1).approve(psi.address, expandTo9Decimals(10))
      await psi.connect(user1).swapOldAmount(expandTo9Decimals(10))
      await psiv1.transfer(user2.address, expandTo9Decimals(10))
      await psiv1.connect(user2).approve(psi.address, expandTo9Decimals(10))
      await psi.connect(user2).swapOldAmount(expandTo9Decimals(10))
      await psiv1.transfer(user3.address, expandTo9Decimals(10))
      await psiv1.connect(user3).approve(psi.address, expandTo9Decimals(10))
      await psi.connect(user3).swapOldAmount(expandTo9Decimals(10))

      await psi.connect(user3).transfer(user2.address, expandTo9Decimals(10))
      await psiv1.approve(psi.address, constants.MaxUint256)
      await psi.swapOld()

      expect(await psi.totalSupply()).to.eq(maxSupply)
      expect(await psi.balanceOf(user1.address)).to.eq('10000054996')
      expect(await psi.balanceOf(user2.address)).to.eq('19900109443')
      expect(await psi.balanceOf(user3.address)).to.eq(0)
      expect(await psi.balanceOf(owner.address)).to.eq(maxSupply.sub(expandTo9Decimals(30)))
      expect(await psiv1.balanceOf("0x000000000000000000000000000000000000dEaD")).to.eq(expandTo9Decimals(18183))
    })
  })

  describe('Transfers', () => {
    it('Succeed when enabled with 1% fees applied', async () => {
      const amount = expandTo9Decimals(10)
      await swapv1()
      await psi.connect(user1).transfer(user2.address, amount)
      expect(await psi.balanceOf(user1.address)).to.eq('990099009900')
      expect(await psi.balanceOf(user2.address)).to.eq('9900990099')
    })

    // it('Succeed for adding liquidity by owner, fail for trades', async () => {
    //   await addTokenLiquidity()
    //   await expect(router.connect(user1).swapETHForExactTokens(expandTo18Decimals(1), buyPath, user1.address, constants.MaxUint256, { value: expandTo18Decimals(1) }))
    //     .to.be.revertedWith("Pancake: TRANSFER_FAILED")
    // })
  })

  describe('Liquidity Fees', () => {
    beforeEach(async() => {
      await addTokenLiquidity()
    })

    it('Not payed by excluded wallet', async () => {
      await psi.setAccountExcludedDexFromFeePayment(user2.address, true)
      
      await router.connect(user2).swapExactETHForTokensSupportingFeeOnTransferTokens(0, buyPath, user2.address, constants.MaxUint256, { value: expandTo18Decimals(2) })
      expect(await psi.balanceOf(user2.address)).to.eq('282979649070')
      
      await psi.connect(user2).approve(router.address, '282979649070')
      await router.connect(user2).swapExactTokensForETHSupportingFeeOnTransferTokens('282979649070', 0, sellPath, user2.address, constants.MaxUint256)
      expect(await psi.balanceOf(user2.address)).to.eq(0)
    })

    it('Correctly applied on buy', async () => {
      await router.connect(user2).swapExactETHForTokensSupportingFeeOnTransferTokens(0, buyPath, user2.address, constants.MaxUint256, { value: expandTo18Decimals(2) })

      expect(await psi.balanceOf(user2.address)).to.eq('280144980090')
      expect(await liqBalanceAdded()).to.eq(0) // fees are not transfered on buys, but on next transfer/sell (support buying)

      await psi.connect(user2).transfer(user3.address, '280144980090')
      expect(await liqBalanceAdded()).to.eq('4405305192087')
    })

    it('Correctly applied on sell', async () => {
      await router.connect(user2).swapExactETHForTokensSupportingFeeOnTransferTokens(0, buyPath, user2.address, constants.MaxUint256, { value: expandTo18Decimals(2) })
      
      await psi.connect(user2).transfer(user3.address, expandTo9Decimals(1)); // needed because someone needs to retrieve dividend
      await psi.connect(user2).approve(router.address, expandTo9Decimals(1));
      await router.connect(user2).swapExactTokensForETHSupportingFeeOnTransferTokens(expandTo9Decimals(1), 0, sellPath, user2.address, constants.MaxUint256)

      expect(await psi.balanceOf(user1.address)).to.eq('1002250857071')
      expect(await psi.balanceOf(user2.address)).to.eq('278149327624')
      expect(await psi.balanceOf(user3.address)).to.eq('990015446')
      expect(await liqBalanceAdded()).to.eq('4405305192087')
    })
  })
})
