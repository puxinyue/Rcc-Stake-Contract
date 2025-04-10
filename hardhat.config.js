require("@nomicfoundation/hardhat-toolbox");
require("@nomicfoundation/hardhat-ethers");
require("hardhat-deploy");
require("hardhat-deploy-ethers");
/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.28",
  networks: {
    hardhat: {},
    // sepolia: {
    //   url: process.env.SEPOLIA_URL,
    //   accounts: [process.env.PRIVATE_KEY],
    // },
  },
  // etherscan: {
  //   apiKey: {
  //     sepolia: "1234567890",
  //   },
  // },
  namedAccounts: {
    firstAccount: {
      default: 0,
    },
  },
};
