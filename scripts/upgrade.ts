// npx hardhat run scripts/upgrade.ts --network bsctestnet

require("dotenv").config({path: `${__dirname}/.env`});
import { run, ethers, upgrades, defender } from "hardhat"
import { PSIGovernance, FeeAggregator } from "../typechain";
import PSIGovernanceAbi from "../abi/contracts/PSIGovernance.sol/PSIGovernance.json";
import FeeAggregatorAbi from "../abi/contracts/FeeAggregator.sol/FeeAggregator.json";

const main = async() => {
  const signer = ethers.provider.getSigner("0x2C9C756A7CFd79FEBD2fa9b4C82c10a5dB9D8996");

  // const PSIGovernance = await ethers.getContractFactory("PSIGovernance");
  // const governance: PSIGovernance = await upgrades.upgradeProxy("0xa1B540B2BE89b55d5949754E326Fb80063F9781f", PSIGovernance) as PSIGovernance;
  // console.log("PSIGovernance upgraded:", governance.address);

  const FeeAggregator = await ethers.getContractFactory("FeeAggregator");
  // let aggregator = new ethers.Contract("0xdA56896De5A1aF4E3f32c0e8A8b8A06Ca90CB50c", FeeAggregatorAbi, signer) as FeeAggregator // test
  // aggregator = await upgrades.upgradeProxy(aggregator.address, FeeAggregator) as FeeAggregator;
  // console.log("FeeAggregator upgraded:", aggregator.address);
  let aggregator = new ethers.Contract("0xE431399b0FD372DF941CF5e23DBa9FC9Ad605FeF", FeeAggregatorAbi, signer) as FeeAggregator // main
  // console.log("Preparing FeeAggregator proposal...");
  // const proposal = await defender.proposeUpgrade(aggregator.address, FeeAggregator);
  // console.log("FeeAggregator Upgrade proposal created at:", proposal.url);

  const implAddress = await upgrades.erc1967.getImplementationAddress(aggregator.address)
  console.log("FeeAggregator implementation address:", implAddress)
  await run("verify:verify", { address: implAddress, constructorArguments: [] })
  console.log("FeeAggregator implementation verified")
}

main()
//   .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
