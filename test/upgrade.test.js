const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");

describe("MyContract Upgrade", function () {
  let myContractV1;
  let myContractV2;
  let owner;
  let otherAccount;

  beforeEach(async function () {
    [owner, otherAccount] = await ethers.getSigners();
    
    // 部署 V1
    const MyContractV1 = await ethers.getContractFactory("MyContractV1");
    myContractV1 = await upgrades.deployProxy(MyContractV1, [100], { initializer: "initialize" });
    await myContractV1.waitForDeployment();
  });

  it("should upgrade to V2 and migrate correctly", async function () {
    // 升级到 V2
    const MyContractV2 = await ethers.getContractFactory("MyContractV2");
    myContractV2 = await upgrades.upgradeProxy(myContractV1.target, MyContractV2);
    
    // 调用迁移函数
    await myContractV2.migrateToV2();
    
    // 验证 owner 设置正确
    expect(await myContractV2.owner()).to.equal(owner.address);
    
    // 验证只有 owner 可以调用 setValue
    await expect(myContractV2.connect(otherAccount).setValue(200))
      .to.be.revertedWith("Only owner");
      
    // 验证 owner 可以调用 setValue
    await myContractV2.setValue(200);
    expect(await myContractV2.value()).to.equal(200);
  });

  it("should not allow migrateToV2 to be called twice", async function () {
    const MyContractV2 = await ethers.getContractFactory("MyContractV2");
    myContractV2 = await upgrades.upgradeProxy(myContractV1.target, MyContractV2);
    
    // 第一次迁移应该成功
    await myContractV2.migrateToV2();
    
    // 第二次迁移应该失败
    await expect(myContractV2.migrateToV2())
      .to.be.revertedWith("Already migrated");
  });
}); 