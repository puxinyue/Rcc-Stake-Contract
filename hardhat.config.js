require("@nomicfoundation/hardhat-toolbox");
require("@nomicfoundation/hardhat-ethers");
require("hardhat-deploy");
require("hardhat-deploy-ethers");
require("@openzeppelin/hardhat-upgrades");
/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.28",
  networks: {
    hardhat: {},
    // sepolia: {
    //   url: process.env.SEPOLIA_URL,
    //   accounts: [process.env.PRIVATE_KEY],
    // },
    ganache: {
      url: "http://127.0.0.1:7545", // Ganache 默认 RPC URL
      accounts: ["0x6cfc8ac75e0c207ebd495b10f1b357fbf470dcd75a88f969f42b3480bb09dfe3"] // 填入本地链账户私钥
    }
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
