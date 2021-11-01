// npx hardhat run scripts/deploy_psiV2.ts

require("dotenv").config({path: `${__dirname}/.env`});
import { ethers, upgrades } from "hardhat";
import { PSI, PSIv1, PSIGovernance, FeeAggregator } from "../typechain";
import FeeAggregatorAbi from "../abi/contracts/FeeAggregator.sol/FeeAggregator.json";
import PSIAbi from "../abi/contracts/PSI.sol/PSI.json";
import PSIV1Abi from "../abi/contracts/PSIV1.sol/PSIV1.json";

const main = async() => {
  // const signer = ethers.provider.getSigner("0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"); // hardhat
  // const signer = ethers.provider.getSigner("0xCCD0C72BAA17f4d3217e6133739de63ff6F0b462"); // ganache
  const signer = ethers.provider.getSigner("0x2C9C756A7CFd79FEBD2fa9b4C82c10a5dB9D8996"); // bsc test and main

  // const psiv1Address = "0x066Bd99080eC62FE0E28bA687A53aC00794c17b6"; // bsc test
  const psiv1Address = "0x9A5d9c681Db43D9863e9279c800A39449B7e1d6f"; // bsc main
  const psiv1 = new ethers.Contract(psiv1Address, PSIV1Abi, signer) as PSIv1;

  // const factory = "0x6725F303b657a9451d8BA641348b6761A6CC7a17"; // bsc test
  const factory = "0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73"; // bsc main
  // const router = "0xD99D1c33F9fC3444f8101754aBC46c52416550D1"; // bsc test
  const router = "0x10ED43C718714eb63d5aA57B78B54704E256024E"; // bsc main

  // Fee aggregator
  const feeAggregator = new ethers.Contract("0xE431399b0FD372DF941CF5e23DBa9FC9Ad605FeF", FeeAggregatorAbi, signer) as FeeAggregator;
  // const FeeAggregator = await ethers.getContractFactory("FeeAggregator");
  // // const feeAggregator: FeeAggregator = await upgrades.upgradeProxy("0xdA56896De5A1aF4E3f32c0e8A8b8A06Ca90CB50c", FeeAggregator) as FeeAggregator; // bsc test
  // const feeAggregator: FeeAggregator = await upgrades.upgradeProxy("0xE431399b0FD372DF941CF5e23DBa9FC9Ad605FeF", FeeAggregator) as FeeAggregator; // bsc main
  // await feeAggregator.deployed()
  console.log("FeeAggregator upgraded:", feeAggregator.address);

  // deploy PSI
  const psi = new ethers.Contract("0x6e70194F3A2D1D0a917C2575B7e33cF710718a17", PSIAbi, signer) as PSI;
  // const PSI = await ethers.getContractFactory("PSI");
  // const psi =  await upgrades.deployProxy(PSI, [psiv1.address, router, factory], {initializer: 'initialize'}) as PSI;
  // await psi.deployed()
  console.log("PSI deployed:", psi.address);

  await (await psi.setAccountExcludedFromFees(feeAggregator.address, true)).wait()
  await (await feeAggregator.setPSIAddress(psi.address)).wait()
  await (await feeAggregator.addFeeToken(psi.address)).wait()

  // PSIv1 functions
  // await psiv1.excludeAccountForFeeRetrieval(psi.address)
  // await psiv1.excludeAccountFromFeePayment(psi.address)
  // await psiv1.transferOwnership(psi.address)
  // await psi.callOld(psiv1.interface.encodeFunctionData("excludeAccountForFeeRetrieval", ["0x000000000000000000000000000000000000dEaD"]))
  // await psi.callOld(psiv1.interface.encodeFunctionData("excludeAccountFromFeePayment", ["0x000000000000000000000000000000000000dEaD"]))

  const balance = ethers.utils.formatUnits(await psi.balanceOf(signer._address), 9);
  console.log("signer balance: ", balance);
}

main()
//   .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
