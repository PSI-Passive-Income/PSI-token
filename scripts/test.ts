

// npx hardhat run scripts/test.ts --network arbitrum

require("dotenv").config({path: `${__dirname}/.env`});
import { ethers } from "hardhat";
import { IBEP20 } from "../typechain";
import IBEP20Abi from "../abi/contracts/interfaces/IBEP20.sol/IBEP20.json";
import { formatEther } from "@ethersproject/units";

const main = async() => {
  const signer = ethers.provider.getSigner("0xF38b740359D0a7eE22580C91E10083BB1A4988C7");
  console.log(signer._address);

  const token = new ethers.Contract("0x39Fb5888789D6953D45bA801dfa32789E8eb8f43", IBEP20Abi, signer) as IBEP20;
  // await token.approve("0xeed5cd84e688eeddd57d444db0cdced744fa95e2", ethers.constants.MaxUint256);
  console.log("balanceOf", ethers.utils.formatEther(await token.balanceOf("0xF38b740359D0a7eE22580C91E10083BB1A4988C7")));
}

main()
//   .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
