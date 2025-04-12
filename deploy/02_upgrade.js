
module.exports = async ({ getNamedAccounts,deployments }) => {
  const { firstAccount } = await getNamedAccounts();
  const { save } = deployments;
  // 获取代理地址
  const MyContractV1 = await deployments.get('MyContractV1');
  const proxyAddress = MyContractV1.address; // 替换为实际代理地址
  console.log("Found V1 proxy at:", proxyAddress);
  // 升级到 V2
  const MyContractV2 = await ethers.getContractFactory("MyContractV2")
  const v2 = await upgrades.upgradeProxy(
    proxyAddress,
    MyContractV2,
    { firstAccount }
  );
  // 等待部署完成
  await v2.waitForDeployment();
  // 获取合约地址
  const v2Address = await v2.getAddress();

  // 调用迁移函数初始化新增的状态变量
  await v2.migrateToV2();
  
  console.log("Upgraded to V2 at:", v2Address);
  // 保存部署信息
  await save('MyContractV2', {
    abi: JSON.parse(JSON.stringify(MyContractV2.interface.fragments)),
    address: v2Address
  });
};

module.exports.tags = ["upgrade"];
