
module.exports = async ({ getNamedAccounts, deployments }) => {
  const { save } = deployments;
  const { firstAccount } = await getNamedAccounts();

  console.log("Deploying with account:", firstAccount);

  try {
    const MyContractV1 = await ethers.getContractFactory("MyContractV1");
    console.log("Deploying proxy...");
    
    const proxy = await upgrades.deployProxy(MyContractV1, [100], {
      initializer: 'initialize',
      kind: 'transparent'
    });

    await proxy.waitForDeployment();
    const proxyAddress = await proxy.getAddress();

    console.log("Proxy deployed to:", proxyAddress);

    // 保存部署信息
    await save('MyContractV1', {
      abi: JSON.parse(JSON.stringify(MyContractV1.interface.fragments)),
      address: proxyAddress
    });

  } catch (error) {
    console.error("Deployment failed:", error);
    throw error;
  }
};

module.exports.tags = ["MyContractV1"];