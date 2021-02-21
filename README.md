# PSI token

This library is using [Hardhat](https://hardhat.org/getting-started/) and [Truffle](https://www.trufflesuite.com/docs/truffle/getting-started/running-migrations) for development, compiling, testing and deploying. The development tool used foor development is [Visual Studio Code](https://code.visualstudio.com/) which has [great plugins](https://hardhat.org/guides/vscode-tests.html) for solidity development and mocha testing.

## Contracts

* Mainnet
  * PSI : [0xD4Cb461eACe80708078450e465881599d2235f1A](https://etherscan.io/address/0xD4Cb461eACe80708078450e465881599d2235f1A)

* Kovan
  * PSI : [0x92FcE27e6b5F86237D2B1974266D27C2788fa237](https://kovan.etherscan.io/address/0x92FcE27e6b5F86237D2B1974266D27C2788fa237)

* Binance Chain
  * PSI : [0x9A5d9c681Db43D9863e9279c800A39449B7e1d6f](https://bscscan.com/address/0x9A5d9c681Db43D9863e9279c800A39449B7e1d6f)

* Binance Test Chain
  * PSI : [0x066Bd99080eC62FE0E28bA687A53aC00794c17b6](https://testnet.bscscan.com/address/0x066Bd99080eC62FE0E28bA687A53aC00794c17b6)

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

### Migrate to the correct networks

```node
truffle migrate --network development
truffle migrate --network test
truffle migrate --network rinkeby
truffle migrate --network goerli
truffle migrate --network main
```

Make sure you have set the right settings in your ['.env' file](https://www.npmjs.com/package/dotenv). You have to create this file with the following contents yourself:

```node
KOVAN_PRIVATE_KEY=keyhere
RINKEBY_PRIVATE_KEY=keyhere
GOERLI_PRIVATE_KEY=keyhere
MAIN_PRIVATE_KEY=keyhere
KOVAN_INFURA=https://kovan.infura.io/v3/<infurakey>
RINKEBY_INFURA=https://rinkeby.infura.io/v3/<infurakey>
GOERLI_INFURA=https://goerli.infura.io/v3/<infurakey>
MAIN_INFURA=https://mainnet.infura.io/v3/<infurakey>

ALCHEMY_KEY=keyhere
ETHERSCAN_API_TOKEN=keyhere;
```

### Flatten contracts

```node
npx hardhat flatten contracts/DPexRouter.sol > contracts-flattened/DPexRouter.sol
```
