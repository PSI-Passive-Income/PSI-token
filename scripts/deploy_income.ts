// npx hardhat run scripts/deploy_income.ts

require("dotenv").config({path: `${__dirname}/.env`});
import { ethers } from "hardhat";
import { Income } from "../typechain";
import IncomeAbi from "../abi/contracts/Income.sol/Income.json";

const main = async() => {
  // const signer = ethers.provider.getSigner("0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"); // hardhat
  // const signer = ethers.provider.getSigner("0xCCD0C72BAA17f4d3217e6133739de63ff6F0b462"); // ganache
  const signer = ethers.provider.getSigner("0x2C9C756A7CFd79FEBD2fa9b4C82c10a5dB9D8996"); // bsc test and main

  // const income = new ethers.Contract("0x066Bd99080eC62FE0E28bA687A53aC00794c17b6", IncomeAbi, signer) as Income;
  const Income = await ethers.getContractFactory("Income");
  const income: Income = await Income.connect(signer).deploy() as Income;
  await income.deployed();
  console.log("Income contract deployed to:", income.address);

  const balance = ethers.utils.formatUnits(await income.balanceOf(signer._address), 18);
  console.log("signer balance: ", balance);
}

main()
//   .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
