import { Wallet, Contract, providers } from 'ethers'
import { waffle } from 'hardhat'

import { DPexRouter, IWETH } from '@passive-income/dpex-peripheral/typechain'
import { DPexFactory, IDPexPair } from '@passive-income/dpex-swap-core/typechain'
import { PSI, PSIGovernance, FeeAggregator } from '../../typechain'

import DPexFactoryAbi from '@passive-income/dpex-swap-core/artifacts/contracts/DPexFactory.sol/DPexFactory.json'
import IDPexPairAbi from '@passive-income/dpex-swap-core/artifacts/contracts/interfaces/IDPexPair.sol/IDPexPair.json'
import DPexRouterAbi from '@passive-income/dpex-peripheral/artifacts/contracts/DPexRouter.sol/DPexRouter.json'
import WETH9Abi from '@passive-income/dpex-peripheral/artifacts/contracts/test/WETH9.sol/WETH9.json'

import PSIAbi from '../../artifacts/contracts/PSI.sol/PSI.json'
import PSIGovernanceAbi from '../../artifacts/contracts/PSIGovernance.sol/PSIGovernance.json'
import FeeAggregatorAbi from '../../artifacts/contracts/FeeAggregator.sol/FeeAggregator.json'

const overrides = {
  gasLimit: 9500000
}

interface V2Fixture {
  psi: PSI
  WETH: IWETH
  router: DPexRouter
  governance: PSIGovernance
  feeAggregator: FeeAggregator
  WETHPair: IDPexPair
}

export async function v2Fixture([wallet]: Wallet[], provider: providers.Web3Provider): Promise<V2Fixture> {
  // deploy tokens
  const psi = await waffle.deployContract(wallet, PSIAbi, [], overrides) as unknown as PSI
  const WETH = await waffle.deployContract(wallet, WETH9Abi, [], overrides) as unknown as IWETH

  // deploy factory
  const factory = await waffle.deployContract(wallet, DPexFactoryAbi, [], overrides) as unknown as DPexFactory
  await factory.initialize(wallet.address, overrides);

  // deploy governance contract
  const governance = await waffle.deployContract(wallet, PSIGovernanceAbi, [], overrides) as unknown as PSIGovernance
  await governance.initialize(overrides);

  // deploy fee aggregator
  const feeAggregator = await waffle.deployContract(wallet, FeeAggregatorAbi, [], overrides) as unknown as FeeAggregator
  await feeAggregator.initialize(governance.address, WETH.address, psi.address, overrides);
  await psi.excludeAccountForFeeRetrieval(feeAggregator.address);
  await psi.excludeAccountFromFeePayment(feeAggregator.address);

  // deploy router
  const router = await waffle.deployContract(wallet, DPexRouterAbi, [], overrides) as unknown as DPexRouter
  await router.initialize(factory.address, WETH.address, feeAggregator.address, governance.address, overrides)
  await governance.setRouter(router.address, overrides);
  await psi.excludeAccountForFeeRetrieval(router.address);
  await psi.excludeAccountFromFeePayment(router.address);

  await factory.createPair(WETH.address, psi.address, overrides)
  const WETHPairAddress = await factory.getPair(WETH.address, psi.address)
  const WETHPair = new Contract(WETHPairAddress, JSON.stringify(IDPexPairAbi.abi), provider).connect(wallet) as unknown as IDPexPair

  return {
    psi,
    WETH,
    router,
    governance,
    feeAggregator,
    WETHPair
  }
}
