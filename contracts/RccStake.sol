// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// 导入所需的 OpenZeppelin 合约
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

// 导入可升级合约相关的库
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";

contract RccStake is Initializable, UUPSUpgradeable, AccessControlUpgradeable, PausableUpgradeable {
    using SafeERC20 for IERC20;
    using Address for address;
    using Math for uint256;

    // 定义管理员角色
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant UPGRADE_ROLE = keccak256("UPGRADE_ROLE");
    
    IERC20 public RCC;
    // 以太坊质押池ID
    uint256 public constant ETH_PID = 0;

    /*
    在任何时刻，用户待分配的 RCC 数量计算方式为：

    待领取的 RCC = (用户质押数量 * 池子每个质押代币累计RCC) - 用户已完成分配的RCC

    当用户在池子中存入或提取质押代币时，会发生以下操作：
    1. 更新池子的 `accRCCPerST`（每个质押代币累计RCC）和 `lastRewardBlock`（最后更新区块）
    2. 将待领取的 RCC 发送到用户地址
    3. 更新用户的质押数量
    4. 更新用户已完成分配的 RCC 数量
    */

    // 质押池结构体
    struct Pool {
        address stTokenAddress; // 质押代币地址
        uint256 poolWeight; // 质押池权重
        uint256 lastRewardBlock; // 最后一次分配 RCC 的区块号
        uint256 accRccPerST; // 每个质押代币的 RCC 累积量
        uint256 stTokenAmount; // 质押代币总量
        uint256 minDepositAmount; // 最小质押量
        uint256 unstakeLockBlocks; // 解质押锁定区块
    }
 
    // 质押池列表
    Pool[] public pools;
    uint256 public totalPoolWeight; // 总权重

    struct UnstakeRequest {
        uint256 amount; // 解质押数量
        uint256 unlockBlocks; // 解质押解锁区块 可以提取的区块号
    }

    struct User {
        uint256 stakedAmount; // 质押数量
        uint256 finishedRCC; // / 已经分配给用户的 RCC 数量
        uint256 pendingRCC; // 待领取的 RCC 数量
        UnstakeRequest[] requests; // 解质押请求列表
    }

    // 用户列表
    mapping(address => User) public users;

    //  状态变量
    uint256 public startBlock; //挖矿开始的区块
    uint256 public endBlock; //挖矿结束的区块
    uint256 public rccPerBlock; // 每块奖励的RCC数量
    
    bool public withdrawPaused; // 提现是否暂停
    bool public stakePaused; // 质押是否暂停

    // 质押记录
    mapping(address => uint256) public stakedAmount; // 质押数量
    mapping(address => uint256) public lastClaimedBlock; // 最后领取奖励的区块
    

   function initialize(IERC20 _rcc, uint256 _startBlock, uint256 _endBlock, uint256 _rccPerBlock) public initializer {
    require(_startBlock < _endBlock, "Invalid start and end block");
    require(_rccPerBlock > 0, "RCC per block must be greater than 0");
     RCC = _rcc;
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(ADMIN_ROLE, msg.sender);
    setRCC(_rcc);
    startBlock = _startBlock;
    endBlock = _endBlock;
    rccPerBlock = _rccPerBlock;
   }

   event RCCUpdated(IERC20 indexed rcc);
   event EndBlockUpdated(uint256 indexed endBlock);
   event RccPerBlockUpdated(uint256 indexed rccPerBlock);
   event StartBlockUpdated(uint256 indexed startBlock);
   event PoolAdded(address indexed stTokenAddress, uint256 poolWeight, uint256 minDepositAmount, uint256 unstakeLockedBlocks);
   event PoolUpdated(uint256 indexed pid, uint256 minDepositAmount, uint256 unstakeLockedBlocks);
   event PoolRewardUpdated(uint256 indexed pid, uint256 lastRewardBlock, uint256 totalRCC);

   // 检查池子ID是否有效
    modifier checkPid(uint256 _pid) {
        require(_pid < pools.length, "invalid pid");
        _;
    }

  function setRCC(IERC20 _rcc) public onlyRole(ADMIN_ROLE) {
    RCC = _rcc;
    emit RCCUpdated(_rcc);
  }

  function setEndBlock(uint256 _endBlock) public onlyRole(ADMIN_ROLE) {
    require(_endBlock > startBlock, "End block must be greater than current block");
    endBlock = _endBlock;
    emit EndBlockUpdated(_endBlock);
  }

  function setRccPerBlock(uint256 _rccPerBlock) public onlyRole(ADMIN_ROLE) {
    require(_rccPerBlock > 0, "RCC per block must be greater than 0");
    rccPerBlock = _rccPerBlock;
    emit RccPerBlockUpdated(_rccPerBlock);
  }

  function setStartBlock(uint256 _startBlock) public onlyRole(ADMIN_ROLE) {
    require(_startBlock < endBlock, "Start block must be less than end block");
    startBlock = _startBlock;
    emit StartBlockUpdated(_startBlock);
  }
  /**
     * @notice 添加新的质押池
     * @dev 只能由管理员调用，第一个池子必须是ETH池（地址为0x0）
     * @param _stTokenAddress 质押代币地址
     * @param _poolWeight 池子权重
     * @param _minDepositAmount 最小质押数量
     * @param _unstakeLockedBlocks 解质押锁定区块数
     * @param _withUpdate 是否更新所有池子的奖励
     */
  function addPool(
    address _stTokenAddress, 
    uint256 _poolWeight, 
    uint256 _minDepositAmount, 
    uint256 _unstakeLockedBlocks, 
    bool _withUpdate
    ) public onlyRole(ADMIN_ROLE) {
    if(pools.length == 0){
        require(_stTokenAddress == address(0), "First pool must be ETH pool");
    }else{
        require(_stTokenAddress != address(0), "Invalid stToken address");
    }
    require(_unstakeLockedBlocks > 0, "Unstake lock block must be greater than 0");
    require(block.number < endBlock, "Current block must be less than end block");
    if(_withUpdate){
        updateAllPools();
    }
    uint256 lastRewardBlock = block.number>startBlock?block.number:startBlock;
    totalPoolWeight += _poolWeight;
    pools.push(Pool({
        stTokenAddress: _stTokenAddress,
        poolWeight: _poolWeight,
        lastRewardBlock: lastRewardBlock,
        accRccPerST: 0,
        stTokenAmount: 0,
        minDepositAmount: _minDepositAmount,
        unstakeLockBlocks: _unstakeLockedBlocks
    }));
    emit PoolAdded(_stTokenAddress, _poolWeight, _minDepositAmount, _unstakeLockedBlocks);
  }
  
  // 更新所有质押池
  function updateAllPools() public {
    uint256 lastRewardBlock = block.number>startBlock?block.number:startBlock;
    if(block.number <= lastRewardBlock){
        return;
    }
    uint256 length = pools.length;
    for(uint256 pid = 0; pid < length; pid++){
        updatePoolRewards(pid);
    }
  }
  /**
     * @notice 更新指定池子的参数
     * @dev 只能由管理员调用
     * @param _pid 池子ID
     * @param _minDepositAmount 新的最小质押数量
     * @param _unstakeLockedBlocks 新的解质押锁定区块数
     */
function updatePoolConfig (
    uint256 _pid, 
    uint256 _minDepositAmount,
    uint256 _unstakeLockedBlocks
    ) public checkPid(_pid) onlyRole(ADMIN_ROLE) {

   Pool storage pool = pools[_pid];
   pool.minDepositAmount = _minDepositAmount;
   pool.unstakeLockBlocks = _unstakeLockedBlocks;
   emit PoolUpdated(_pid, _minDepositAmount, _unstakeLockedBlocks);
}

function updatePoolRewards (
    uint256 _pid
) public checkPid(_pid) {
    Pool storage pool = pools[_pid];
    if(block.number <= pool.lastRewardBlock){
        //如果当前区块号小于等于上次更新区块号，说明已经更新过了，直接返回
        return;
    }
    // 计算池子应得的总RCC奖励
    (bool success1, uint256 _totalRCC) = getMultiplier(pool.lastRewardBlock, block.number).tryMul(pool.poolWeight);
    require(success1, "Multiplication overflow");
    (success1, _totalRCC) = _totalRCC.tryDiv(totalPoolWeight);
    require(success1, "Division overflow");
   
    // stTokenAmount 是质押代币总量
    uint256 stSupply = pool.stTokenAmount;
    if(stSupply > 0){
        // 将总奖励乘以1 ether（1e18）提高精度
        (bool success2,uint256 _rccReward) = _totalRCC.tryMul(1 ether);
        require(success2, "Multiplication overflow");

        // 除以总质押量，得到每个质押代币应得的奖励
        (success2, _rccReward) = _rccReward.tryDiv(stSupply);
        require(success2, "Division overflow");

        //累加到accRCCPerST（累计每个质押代币的RCC奖励）
        (bool success3,uint256 accRccPerST) = pool.accRccPerST.tryAdd(_rccReward);
        require(success3, "Addition overflow");
        // accRccPerST 每个质押代币的 RCC 累积量
        pool.accRccPerST = accRccPerST;
    }
    // 更新最后奖励区块号为当前区块
    pool.lastRewardBlock = block.number;
    emit PoolRewardUpdated(_pid, pool.lastRewardBlock,_totalRCC);

}

/**
     * @notice 计算指定区块范围内的奖励倍数
     * @param _from 起始区块号（包含）
     * @param _to 结束区块号（不包含）
     * @return multiplier 奖励倍数
     */
function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256 multiplier) {
   require(_from <= _to, "Invalid block range");
   if(_from < startBlock){
    _from = startBlock;
   }
   if(_to > endBlock){
    _to = endBlock;
   }
   (bool success, uint256 _multiplier) = (_to - _from).tryMul(rccPerBlock);
   require(success, "Multiplication overflow");
   multiplier = _multiplier;
}   




    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADE_ROLE)
    {
        
    }
}
