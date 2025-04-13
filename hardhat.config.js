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
      accounts: ["0x8b3f8aab5691273868ec6162794d6e6b1d85084127c61190a27c75a9da5ff4cb"] // 填入本地链账户私钥
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
