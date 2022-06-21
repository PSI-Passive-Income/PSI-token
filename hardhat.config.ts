import { HardhatUserConfig } from "hardhat/types";

// import "@nomiclabs/hardhat-ganache";
import "@nomiclabs/hardhat-waffle";
import "hardhat-typechain";
import 'hardhat-abi-exporter';
import "hardhat-tracer";
import "hardhat-dependency-compiler";
import 'hardhat-contract-sizer';
import '@openzeppelin/hardhat-upgrades';
import '@openzeppelin/hardhat-defender';
import "@nomiclabs/hardhat-etherscan";

require("dotenv").config({path: `${__dirname}/.env`});

const config: HardhatUserConfig = {
  defaultNetwork: "hardhat",
  defender: {
    apiKey: process.env.DEFENDER_TEAM_API_KEY,
    apiSecret: process.env.DEFENDER_TEAM_API_SECRET_KEY,
  },
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
      accounts: [`0x${process.env.PRIVATE_KEY}`]
    },
    rinkeby: {
      url: `${process.env.RINKEBY_INFURA}`,
      accounts: [`0x${process.env.PRIVATE_KEY}`]
    },
    mainnet: {
      url: `${process.env.MAIN_INFURA}`,
      accounts: [`0x${process.env.PRIVATE_KEY}`],
    },
    bsctestnet: {
      url: "https://data-seed-prebsc-1-s1.binance.org:8545",
      chainId: 97,
      accounts: [`0x${process.env.PRIVATE_KEY}`]
    },
    bscmainnet: {
      url: "https://bsc-dataseed.binance.org/",
      chainId: 56,
      accounts: [`0x${process.env.PRIVATE_KEY}`],
    },
    polygon: {
      url: "https://matic-mainnet.chainstacklabs.com",
      chainId: 137,
      accounts: [`0x${process.env.PRIVATE_KEY}`],
    },
    polygonmumbai: {
      url: "https://speedy-nodes-nyc.moralis.io/74952dfd773888c65e279d29/polygon/mumbai",
      chainId: 80001,
      accounts: [`0x${process.env.PRIVATE_KEY}`],
    },
    ganache: {
      url: "HTTP://127.0.0.1:7545",
      chainId: 1337,
      accounts: [`0x767f7322259ccc3a24165da6767b2a76f7cd94b2e4b0f76beb65b8b07ec11990`]
    }
  },
  etherscan: {
    // apiKey: `${process.env.ETHERSCAN_API_TOKEN}`
    // apiKey: `${process.env.BSC_API_TOKEN}`
    apiKey: `${process.env.POLYGON_API_TOKEN}`
  },
  solidity: {
    compilers: [
      {
        version: "0.8.14",
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
      },
      { 
        version: "0.6.12",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          }
        } 
      },
      { 
        version: "0.5.16",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          }
        } 
      },
      { 
        version: "0.4.18",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
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
    runOnCompile: true,
    disambiguatePaths: false,
  }  
};

export default config;