// npx hardhat run scripts/deploy_psi.ts

require("dotenv").config({path: `${__dirname}/.env`});
import { ethers } from "hardhat";
import { PSI } from "../typechain";
import PSIAbi from "../abi/contracts/PSI.sol/PSI.json";

const main = async() => {
  const signer = ethers.provider.getSigner();
  // const signer = ethers.provider.getSigner("0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266");
  console.log(signer._address);

  // const psi = new ethers.Contract("0x066Bd99080eC62FE0E28bA687A53aC00794c17b6", PSIAbi, signer) as PSI;
  const PSI = await ethers.getContractFactory("PSI");
  const psi: PSI = await PSI.connect(signer).deploy() as PSI;
  await psi.deployed();
  console.log("PSI contract deployed to:", psi.address);

  const balance = ethers.utils.formatUnits(await psi.balanceOf(signer._address), 9);
  console.log("signer balance: ", balance);
}

main()
//   .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
