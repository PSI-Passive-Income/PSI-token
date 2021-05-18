// npx hardhat run scripts/upgrade.ts

require("dotenv").config({path: `${__dirname}/.env`});
import { ethers, upgrades } from "hardhat";
import { PSIGovernance, FeeAggregator } from "../typechain";
import PSIGovernanceAbi from "../abi/contracts/PSIGovernance.sol/PSIGovernance.json";
import FeeAggregatorAbi from "../abi/contracts/FeeAggregator.sol/FeeAggregator.json";

const main = async() => {
//   const PSIGovernance = await ethers.getContractFactory("PSIGovernance");
//   const governance: PSIGovernance = await upgrades.upgradeProxy("0xa1B540B2BE89b55d5949754E326Fb80063F9781f", PSIGovernance) as PSIGovernance;
//   console.log("PSIGovernance upgraded:", governance.address);

  const FeeAggregator = await ethers.getContractFactory("FeeAggregator");
  const aggregator: FeeAggregator = await upgrades.upgradeProxy("0xE431399b0FD372DF941CF5e23DBa9FC9Ad605FeF", FeeAggregator) as FeeAggregator;
  console.log("FeeAggregator upgraded:", aggregator.address);
}

main()
//   .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
