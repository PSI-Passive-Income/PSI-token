# PSI token

This library is using [Hardhat](https://hardhat.org/getting-started/) for development, compiling, testing and deploying. The development tool used for development is [Visual Studio Code](https://code.visualstudio.com/) which has [great plugins](https://hardhat.org/guides/vscode-tests.html) for solidity development and mocha testing.

## Contracts

* Binance Chain
  * PSI : [0x9A5d9c681Db43D9863e9279c800A39449B7e1d6f](https://bscscan.com/address/0x9A5d9c681Db43D9863e9279c800A39449B7e1d6f)
  * PSI Governance : [0xa1B540B2BE89b55d5949754E326Fb80063F9781f](https://bscscan.com/address/0xa1B540B2BE89b55d5949754E326Fb80063F9781f)
  * Fee Aggregator : [0xE431399b0FD372DF941CF5e23DBa9FC9Ad605FeF](https://bscscan.com/address/0xE431399b0FD372DF941CF5e23DBa9FC9Ad605FeF)

* Binance Test Chain
  * PSI : [0x066Bd99080eC62FE0E28bA687A53aC00794c17b6](https://testnet.bscscan.com/address/0x066Bd99080eC62FE0E28bA687A53aC00794c17b6)
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
