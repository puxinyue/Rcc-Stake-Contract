const { upgradeProxy } = require("@openzeppelin/hardhat-upgrades");

module.exports = async ({ getNamedAccounts }) => {
  const { firstAccount } = await getNamedAccounts();
  const proxyAddress = "0x..."; // 替换为实际代理地址

  // 升级到 V2
  const v2 = await upgradeProxy(
    proxyAddress,
    await ethers.getContractFactory("MyContractV2"),
    { firstAccount }
  );
  
  console.log("Upgraded to V2 at:", v2.address);
};

module.exports.tags = ["upgrade"];
