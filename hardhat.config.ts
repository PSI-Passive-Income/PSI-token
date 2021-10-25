import { HardhatUserConfig } from "hardhat/types";

// import "@nomiclabs/hardhat-ganache";
import "@nomiclabs/hardhat-waffle";
import "hardhat-typechain";
import 'hardhat-abi-exporter';
import "hardhat-tracer";
import "hardhat-dependency-compiler";
import 'hardhat-contract-sizer';
import '@openzeppelin/hardhat-upgrades';
import "@nomiclabs/hardhat-etherscan";

require("dotenv").config({path: `${__dirname}/.env`});

const config: HardhatUserConfig = {
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      // forking: {
      //   enabled: true,
      //   url: `${process.env.MAIN_ALCHEMY_URL}`,
      //   blockNumber: 11754056
      // }
    },
    kovan: {
      url: `${process.env.KOVAN_INFURA}`,
      accounts: [`0x${process.env.KOVAN_PRIVATE_KEY}`]
    },
    goerli: {
      url: `${process.env.GOERLI_INFURA}`,
      accounts: [`0x${process.env.GOERLI_PRIVATE_KEY}`]
    },
    mainnet: {
      url: `${process.env.MAIN_INFURA}`,
      accounts: [`0x${process.env.MAIN_PRIVATE_KEY}`],
      // gasPrice: 200000000000
    },
    bsctestnet: {
      url: "https://data-seed-prebsc-1-s2.binance.org:8545",
      chainId: 97,
      accounts: [`0x${process.env.BSC_TEST_PRIVATE_KEY}`],
    },
    bscmainnet: {
      url: "https://bsc-dataseed.binance.org/",
      chainId: 56,
      accounts: [`0x${process.env.BSC_PRIVATE_KEY}`],
    },
    ganache: {
      url: "HTTP://127.0.0.1:7545",
      chainId: 1337,
      accounts: [`0x767f7322259ccc3a24165da6767b2a76f7cd94b2e4b0f76beb65b8b07ec11990`]
    },
    arbitrum: {
      url: "https://arb1.arbitrum.io/rpc",
      chainId: 42161,
      accounts: [`0x${process.env.BSC_PRIVATE_KEY}`],
    }
    // rinkeby: {
    //   url: `${process.env.RINKEBY_INFURA}`,
    //   accounts: [`0x${process.env.RINKEBY_PRIVATE_KEY}`]
    // }
  },
  etherscan: {
    // Your API key for Etherscan
    // Obtain one at https://etherscan.io/
    apiKey: `${process.env.BSC_API_TOKEN}`
  },
  solidity: {
    compilers: [
      {
        version: "0.8.9",
        settings: {
          optimizer: {
            enabled: true,
            runs: 30000
          }
        }
      },
      {
        version: "0.7.4",
        settings: {
          optimizer: {
            enabled: true,
            runs: 30000
          }
        }
      }
    ],
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts"
  },
  // dependencyCompiler: {
  //   paths: [
  //     '@passive-income/dpex-swap-core/contracts/DPexFactory.sol',
  //     '@passive-income/dpex-peripheral/contracts/DPexRouterPairs.sol',
  //     '@passive-income/dpex-peripheral/contracts/DPexRouter.sol'
  //   ],
  // },
  contractSizer: {
    alphaSort: false,
    runOnCompile: false,
    disambiguatePaths: false,
  }  
};

export default config;