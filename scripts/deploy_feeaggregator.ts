// npx hardhat run scripts/deploy_feeaggregator.ts

require("dotenv").config({path: `${__dirname}/.env`});
import { run, ethers, upgrades } from "hardhat";
import { SimpleFeeAggregator } from "../typechain";
import SimpleFeeAggregatorAbi from "../abi/contracts/SimpleFeeAggregator.sol/SimpleFeeAggregator.json";

const main = async() => {
  // const signer = ethers.provider.getSigner();
  const signer = ethers.provider.getSigner("0x2C9C756A7CFd79FEBD2fa9b4C82c10a5dB9D8996");
  console.log("deploying")
  
  const router = "0xE592427A0AEce92De3Edee1F18E0157C05861564" // uniswap router on all deployed nets
  const wrappedToken = "0x9c3c9283d3e44854697cd22d3faa240cfb032889" // mumbai polygon
  // const wrappedToken = "0x0d500b1d8e8ef31e21c99d1db9a6444d3adf1270" // main polygon

  // staking
  let simpleFeeAggregator = new ethers.Contract("0x12d181455C792C6a26a78823dB55c1aDDD3AC910", SimpleFeeAggregatorAbi, signer) as SimpleFeeAggregator; // mumbai
  // let staking = new ethers.Contract("0x52c5b4d0c6296d3c7ab81662c54140509d8694b6", MetaBotsStakingAbi.abi, signer) as MetaBotsStaking; // bsc main
  // const SimpleFeeAggregator = await ethers.getContractFactory("SimpleFeeAggregator");
  // const simpleFeeAggregator =  await upgrades.deployProxy(SimpleFeeAggregator, [router, wrappedToken, signer._address], {initializer: 'initialize'}) as SimpleFeeAggregator;
  console.log("SimpleFeeAggregator deployed:", simpleFeeAggregator.address);

  const stakingImplAddress = await upgrades.erc1967.getImplementationAddress(simpleFeeAggregator.address)
  console.log("SimpleFeeAggregator implementation address:", stakingImplAddress);
  await run("verify:verify", { address: stakingImplAddress, constructorArguments: [] });
  console.log("SimpleFeeAggregator implementation verified");
}

main()
//   .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
