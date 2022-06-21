import { Wallet, providers, Contract } from 'ethers'
import { waffle, ethers, upgrades } from 'hardhat'

import { DPexRouter, DPexRouterPairs } from '@passive-income/dpex-peripheral/typechain'
import { DPexFactory, IDPexPair } from '@passive-income/dpex-swap-core/typechain'
import { PSI, PSIv1, Income, IncomeMinter, PSIGovernance, FeeAggregator, SimpleFeeAggregator, WBNB, PancakeFactory, PancakeRouter, IPancakePair, PancakePair } from '../../typechain'

import DPexFactoryAbi from '@passive-income/dpex-swap-core/artifacts/contracts/DPexFactory.sol/DPexFactory.json'
import IDPexPairAbi from '@passive-income/dpex-swap-core/artifacts/contracts/interfaces/IDPexPair.sol/IDPexPair.json'
import DPexRouterAbi from '@passive-income/dpex-peripheral/artifacts/contracts/DPexRouter.sol/DPexRouter.json'
import DPexRouterPairsAbi from '@passive-income/dpex-peripheral/artifacts/contracts/DPexRouterPairs.sol/DPexRouterPairs.json'

import PSIAbi from '../../artifacts/contracts/PSI.sol/PSI.json'
import PSIv1Abi from '../../artifacts/contracts/PSIv1.sol/PSIv1.json'
import IncomeAbi from '../../artifacts/contracts/Income.sol/Income.json'
import PSIGovernanceAbi from '../../artifacts/contracts/PSIGovernance.sol/PSIGovernance.json'
import FeeAggregatorAbi from '../../artifacts/contracts/SimpleFeeAggregator.sol/SimpleFeeAggregator.json'
import SimpleFeeAggregatorAbi from '../../artifacts/contracts/SimpleFeeAggregator.sol/SimpleFeeAggregator.json'

import WBNBAbi from '../../artifacts/contracts/test/WBNB.sol/WBNB.json'
import PancakeFactoryAbi from '../../artifacts/contracts/test/PancakeFactory.sol/PancakeFactory.json'
import PancakeRouterAbi from '../../artifacts/contracts/test/PancakeRouter.sol/PancakeRouter.json'
import PancakePairAbi from '../../artifacts/contracts/test/PancakeFactory.sol/PancakePair.json'

import IncomeMinterAbi from '../../artifacts/contracts/test/IncomeMinter.sol/IncomeMinter.json'
import { pairHash } from './utilities'
import { zeroAddress } from 'ethereumjs-util'

const overrides = {
  gasLimit: 9500000
}

interface V2Fixture {
  psi: PSI
  psiv1: PSIv1
  income: Income
  incomeMinter: IncomeMinter
  WBNB: WBNB
  factory: DPexFactory
  router: DPexRouter
  pcFactory: PancakeFactory
  pcRouter: PancakeRouter
  governance: PSIGovernance
  feeAggregator: FeeAggregator
  simpleFeeAggregator: SimpleFeeAggregator
  WBNBPair: IPancakePair
}

export async function v2Fixture([wallet]: Wallet[], provider: providers.Web3Provider): Promise<V2Fixture> {
  // deploy tokens
  const psiv1 = await waffle.deployContract(wallet, PSIv1Abi, [], overrides) as PSIv1
  const income = await waffle.deployContract(wallet, IncomeAbi, [], overrides) as Income
  const WBNB = await waffle.deployContract(wallet, WBNBAbi, [], overrides) as WBNB

  // deploy factory
  const factory = await waffle.deployContract(wallet, DPexFactoryAbi, [], overrides) as DPexFactory
  await factory.initialize(wallet.address)
  // deploy governance contract
  const PSIGovernance = await ethers.getContractFactory("PSIGovernance");
  const governance =  await upgrades.deployProxy(PSIGovernance, [], {initializer: 'initialize'}) as PSIGovernance;

  // deploy fee aggregator
  const FeeAggregator = await ethers.getContractFactory("FeeAggregator");
  const feeAggregator =  await upgrades.deployProxy(FeeAggregator, [zeroAddress(), WBNB.address, psiv1.address], {initializer: 'initialize'}) as FeeAggregator;
  const SimpleFeeAggregator = await ethers.getContractFactory("SimpleFeeAggregator");
  const simpleFeeAggregator =  await upgrades.deployProxy(SimpleFeeAggregator, [zeroAddress(), WBNB.address, wallet.address], {initializer: 'initialize'}) as SimpleFeeAggregator;

  // deploy router
  const routerPairs = await waffle.deployContract(wallet, DPexRouterPairsAbi, [], overrides) as DPexRouterPairs
  await routerPairs.initialize(feeAggregator.address, governance.address)
  await routerPairs.setFactory(factory.address, pairHash);
  const router = await waffle.deployContract(wallet, DPexRouterAbi, [], overrides) as DPexRouter
  await router.initialize(factory.address, routerPairs.address, WBNB.address, feeAggregator.address, governance.address)
  await governance.setRouter(router.address, overrides);
  await feeAggregator.updateRouter(router.address, overrides)
  await simpleFeeAggregator.updateRouter(router.address, overrides)

  // pancake router
  const pcFactory = await waffle.deployContract(wallet, PancakeFactoryAbi, [wallet.address], overrides) as PancakeFactory
  const pcRouter = await waffle.deployContract(wallet, PancakeRouterAbi, [pcFactory.address, WBNB.address], overrides) as PancakeRouter

  // deploy PSI
  const PSI = await ethers.getContractFactory("PSI");
  const psi =  await upgrades.deployProxy(PSI, [psiv1.address, pcRouter.address, pcFactory.address], {initializer: 'initialize'}) as PSI;
  await psi.setAccountExcludedFromFees(feeAggregator.address, true)
  await feeAggregator.setPSIAddress(psi.address)

  const WBNBPairAddress = await pcFactory.getPair(psi.address, WBNB.address)
  const WBNBPair = new Contract(WBNBPairAddress, PancakePairAbi.abi, provider) as IPancakePair;

  // income minter
  const incomeMinter = await waffle.deployContract(wallet, IncomeMinterAbi, [income.address], overrides) as IncomeMinter

  return {
    psi,
    psiv1,
    income,
    incomeMinter,
    WBNB,
    factory,
    router,
    pcFactory,
    pcRouter,
    governance,
    feeAggregator,
    simpleFeeAggregator,
    WBNBPair
  }
}
