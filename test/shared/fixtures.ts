import { Wallet, providers, ContractFactory } from 'ethers'
import { waffle, ethers, upgrades } from 'hardhat'

import { DPexRouter, DPexRouterPairs, IWETH } from '@passive-income/dpex-peripheral/typechain'
import { DPexFactory, IDPexPair } from '@passive-income/dpex-swap-core/typechain'
import { PSI, Income, IncomeMinter, PSIGovernance, FeeAggregator } from '../../typechain'

import DPexFactoryAbi from '@passive-income/dpex-swap-core/artifacts/contracts/DPexFactory.sol/DPexFactory.json'
import IDPexPairAbi from '@passive-income/dpex-swap-core/artifacts/contracts/interfaces/IDPexPair.sol/IDPexPair.json'
import DPexRouterAbi from '@passive-income/dpex-peripheral/artifacts/contracts/DPexRouter.sol/DPexRouter.json'
import DPexRouterPairsAbi from '@passive-income/dpex-peripheral/artifacts/contracts/DPexRouterPairs.sol/DPexRouterPairs.json'
import WBNBAbi from '@passive-income/dpex-peripheral/artifacts/contracts/test/WBNB.sol/WBNB.json'

import PSIAbi from '../../artifacts/contracts/PSI.sol/PSI.json'
import IncomeAbi from '../../artifacts/contracts/Income.sol/Income.json'
import PSIGovernanceAbi from '../../artifacts/contracts/PSIGovernance.sol/PSIGovernance.json'
import FeeAggregatorAbi from '../../artifacts/contracts/FeeAggregator.sol/FeeAggregator.json'

import IncomeMinterAbi from '../../artifacts/contracts/test/IncomeMinter.sol/IncomeMinter.json'

const overrides = {
  gasLimit: 9500000
}

interface V2Fixture {
  psi: PSI
  income: Income
  incomeMinter: IncomeMinter
  WETH: IWETH
  router: DPexRouter
  governance: PSIGovernance
  feeAggregator: FeeAggregator
  WETHPair: IDPexPair
}

export async function v2Fixture([wallet]: Wallet[], provider: providers.Web3Provider): Promise<V2Fixture> {
  // deploy tokens
  const psi = await waffle.deployContract(wallet, PSIAbi, [], overrides) as PSI
  const income = await waffle.deployContract(wallet, IncomeAbi, [], overrides) as Income
  const WETH = await waffle.deployContract(wallet, WBNBAbi, [], overrides) as IWETH

  // deploy factory
  const factory = await waffle.deployContract(wallet, DPexFactoryAbi, [], overrides) as DPexFactory
  await factory.initialize(wallet.address)
  // deploy governance contract
  const PSIGovernance = await ethers.getContractFactory("PSIGovernance");
  const governance =  await upgrades.deployProxy(PSIGovernance, [], {initializer: 'initialize'}) as PSIGovernance;

  // deploy fee aggregator
  const FeeAggregator = await ethers.getContractFactory("FeeAggregator");
  const feeAggregator =  await upgrades.deployProxy(FeeAggregator, [governance.address, WETH.address, psi.address], {initializer: 'initialize'}) as FeeAggregator;
  await psi.setAccountExcludedFromFees(feeAggregator.address, true);

  // deploy router
  const routerPairs = await waffle.deployContract(wallet, DPexRouterPairsAbi, [], overrides) as DPexRouterPairs
  await routerPairs.initialize(feeAggregator.address, governance.address)
  await routerPairs.setFactory(factory.address, "0x8ce3d8395a2762e69b9d143e8364b606484fca5a5826adb06d61642abebe6a0f");
  const router = await waffle.deployContract(wallet, DPexRouterAbi, [], overrides) as DPexRouter
  await router.initialize(factory.address, routerPairs.address, WETH.address, feeAggregator.address, governance.address)
  await governance.setRouter(router.address, overrides);
  await psi.setAccountExcludedFromFees(router.address, true);

  await factory.createPair(WETH.address, psi.address, overrides)
  const WETHPairAddress = await factory.getPair(WETH.address, psi.address)
  const WETHPair = ethers.getContractAt(IDPexPairAbi.abi, WETHPairAddress) as unknown as IDPexPair

  // income minter
  const incomeMinter = await waffle.deployContract(wallet, IncomeMinterAbi, [income.address], overrides) as unknown as IncomeMinter

  return {
    psi,
    income,
    incomeMinter,
    WETH,
    router,
    governance,
    feeAggregator,
    WETHPair
  }
}
