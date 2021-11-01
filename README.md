# PSI tokens and fee aggregator contracts

This project is using [Hardhat](https://hardhat.org/getting-started/) for development, compiling, testing and deploying. The development tool used for development is [Visual Studio Code](https://code.visualstudio.com/) which has [great plugins](https://hardhat.org/guides/vscode-tests.html) for solidity development and mocha testing.

## Contracts

* Binance Chain
  * PSI : [0x6e70194F3A2D1D0a917C2575B7e33cF710718a17](https://testnet.bscscan.com/address/0x6e70194F3A2D1D0a917C2575B7e33cF710718a17)
  * PSIV1 : [0x9A5d9c681Db43D9863e9279c800A39449B7e1d6f](https://bscscan.com/address/0x9A5d9c681Db43D9863e9279c800A39449B7e1d6f)
  * Income : [0xDc3890618bd71d3eF3eC18BB14a510c0dA528947](https://bscscan.com/address/0xDc3890618bd71d3eF3eC18BB14a510c0dA528947)
  * PSI Governance : [0xa1B540B2BE89b55d5949754E326Fb80063F9781f](https://bscscan.com/address/0xa1B540B2BE89b55d5949754E326Fb80063F9781f)
  * Fee Aggregator : [0xE431399b0FD372DF941CF5e23DBa9FC9Ad605FeF](https://bscscan.com/address/0xE431399b0FD372DF941CF5e23DBa9FC9Ad605FeF)

* Binance Test Chain
  * PSI : [0x6C31B672AB6B4D455608b33A11311cd1C9BdBA1C](https://testnet.bscscan.com/address/0x6C31B672AB6B4D455608b33A11311cd1C9BdBA1C)
  * PSIV1 : [0x066Bd99080eC62FE0E28bA687A53aC00794c17b6](https://testnet.bscscan.com/address/0x066Bd99080eC62FE0E28bA687A53aC00794c17b6)
  * Income : [0x75d8b48342149ff7F7f1786e6f8B839Ca669e4cf](https://testnet.bscscan.com/address/0x75d8b48342149ff7F7f1786e6f8B839Ca669e4cf)
  * PSI Governance : [0x04A31EEF89095Eb131Cb1b48bb3ab87655e5e681](https://testnet.bscscan.com/address/0x04A31EEF89095Eb131Cb1b48bb3ab87655e5e681)
  * Fee Aggregator : [0xdA56896De5A1aF4E3f32c0e8A8b8A06Ca90CB50c](https://testnet.bscscan.com/address/0xdA56896De5A1aF4E3f32c0e8A8b8A06Ca90CB50c)

* Mainnet
  * PSI : [0xD4Cb461eACe80708078450e465881599d2235f1A](https://etherscan.io/address/0xD4Cb461eACe80708078450e465881599d2235f1A)

* Kovan
  * PSI : [0x92FcE27e6b5F86237D2B1974266D27C2788fa237](https://kovan.etherscan.io/address/0x92FcE27e6b5F86237D2B1974266D27C2788fa237)

## Compiling

Introduction to compiling these contracts

### Install needed packages

```npm
npm install or yarn install
```

### Compile code

```npm
npx hardhat compile
```

### Test code

```node
npx hardhat test
```

### Run a local development node

This is needed before a truffle migrate to the development network. You can also use this for local development with for example metamask. [Hardhat node guide](https://hardhat.org/hardhat-network/)

```node
npx hardhat node
```

### Scripts

Use the scripts in the "scripts" folder. Each script has the command to start it on top.

Make sure you have set the right settings in your ['.env' file](https://www.npmjs.com/package/dotenv). You have to create this file with the following contents yourself:

```node
BSC_PRIVATE_KEY=<private_key>
BSC_TEST_PRIVATE_KEY=<private_key>
KOVAN_PRIVATE_KEY=<private_key>
RINKEBY_PRIVATE_KEY=<private_key>
GOERLI_PRIVATE_KEY=<private_key>
MAIN_PRIVATE_KEY=<private_key>

KOVAN_INFURA=https://kovan.infura.io/v3/<infura_key>
RINKEBY_INFURA=https://rinkeby.infura.io/v3/<infura_key>
GOERLI_INFURA=https://goerli.infura.io/v3/<infura_key>
MAIN_INFURA=https://mainnet.infura.io/v3/<infura_key>

MAIN_ALCHEMY_URL=https://eth-mainnet.alchemyapi.io/v2/<alchemy_key>
KOVAN_ALCHEMY_URL=https://eth-kovan.alchemyapi.io/v2/<alchemy_key>

ETHERSCAN_API_TOKEN=<etherscan_api_token>
BSC_API_TOKEN=<bscscan_api_token>
```

### Flatten contracts

```node
npx hardhat flatten contracts/DPexRouter.sol > contracts-flattened/DPexRouter.sol
```
