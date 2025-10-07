# BlockETF Router 合约实现

根据 PRD.md 中的设计要求，我已经完成了 BlockETF 系统的 router 合约实现。

## 📋 合约架构

### 核心合约

1. **BlockETF.sol** - 核心 ETF 合约

   - ERC20 代币实现
   - 资产管理和权重配置
   - 份额铸造和销毁
   - 权限控制

2. **ETFRouter.sol** - 路由合约
   - 单币申购/赎回入口
   - DEX 集成(PancakeSwap V2/V3)
   - 滑点保护
   - 资产配置管理

### 接口定义

- `IERC20.sol` - 标准 ERC20 接口
- `IBlockETF.sol` - BlockETF 核心接口
- `IPancakeRouter02.sol` - PancakeSwap V2 路由接口
- `IPancakeV3Router.sol` - PancakeSwap V3 路由接口

## 🚀 核心功能

### 1. 单币申购 (mintWithUSDT)

用户使用 USDT 申购 ETF 份额：

```solidity
function mintWithUSDT(
    uint256 usdtAmount,
    uint256 minShares
) external returns (uint256 shares)
```

**流程：**

1. 接收用户 USDT
2. 根据目标权重分配资金
3. 通过 DEX 将 USDT 换成各种底层资产
4. 存入资产到核心合约并铸造份额
5. 返还多余 USDT

### 2. 单币赎回 (burnToUSDT)

用户赎回 ETF 份额换回 USDT：

```solidity
function burnToUSDT(
    uint256 shares,
    uint256 minUsdtAmount
) external returns (uint256 usdtAmount)
```

**流程：**

1. 销毁用户份额
2. 从核心合约提取对应的底层资产
3. 通过 DEX 将所有资产换回 USDT
4. 转账给用户

### 3. 混合 DEX 路由

根据 PRD 设计，不同资产使用不同的 DEX 版本：

- **WBNB**: 使用 PancakeSwap V2 (流动性更好)
- **BTCB/ETH/XRP/SOL**: 使用 PancakeSwap V3 (资本效率更高)

```solidity
struct AssetConfig {
    bool useV3;          // 是否使用V3
    uint24 v3Fee;        // V3手续费档位
    address customPool;   // 自定义池地址
}
```

## 🛠 技术特性

### 安全设计

1. **权限分离**:

   - BlockETF 作为底层资产容器，完全独立
   - Router 作为业务逻辑层，可升级替换

2. **滑点保护**:

   - 用户设置最小期望输出
   - 自动计算和验证滑点范围

3. **紧急控制**:
   - 合约暂停功能
   - 紧急提取功能
   - 所有权转移

### 配置管理

1. **资产配置**: 灵活配置每个资产的交易路径
2. **滑点设置**: 可调整最大滑点保护
3. **费率管理**: 支持不同 DEX 费率档位

## 📦 部署说明

### 1. 使用 Hardhat Ignition 部署

```bash
# 编译合约
npm run compile

# 部署到本地网络
npx hardhat ignition deploy ignition/modules/BlockETF.ts --network localhost

# 部署到BSC测试网
npx hardhat ignition deploy ignition/modules/BlockETF.ts --network bsc-testnet
```

### 2. 初始资产配置

部署后的默认配置：

| 资产 | 权重 | DEX 版本 | 费率  |
| ---- | ---- | -------- | ----- |
| BTCB | 30%  | V3       | 0.25% |
| ETH  | 25%  | V3       | 0.25% |
| WBNB | 20%  | V2       | -     |
| XRP  | 15%  | V3       | 0.25% |
| SOL  | 10%  | V3       | 0.25% |

### 3. 网络配置

**BSC 主网地址：**

- USDT: `0x55d398326f99059fF775485246999027B3197955`
- PancakeSwap V2 Router: `0x10ED43C718714eb63d5aA57B78B54704E256024E`
- PancakeSwap V3 Router: `0x13f4EA83D0bd40E75C8222255bc855a974568Dd4`

## 🔧 使用示例

### 申购 ETF

```javascript
// 用户授权USDT给Router
await usdtContract.approve(routerAddress, usdtAmount);

// 申购ETF
const tx = await etfRouter.mintWithUSDT(
  ethers.parseEther("1000"), // 1000 USDT
  ethers.parseEther("0.9") // 最少获得0.9个ETF份额
);
```

### 赎回 ETF

```javascript
// 用户授权ETF给Router (通过BlockETF合约)
await blockETF.approve(routerAddress, shares);

// 赎回ETF
const tx = await etfRouter.burnToUSDT(
  ethers.parseEther("1.0"), // 赎回1个ETF份额
  ethers.parseEther("950") // 最少获得950 USDT
);
```

### 预览功能

```javascript
// 预览申购结果
const [expectedShares, assets, amounts] = await etfRouter.previewMint(
  ethers.parseEther("1000")
);

// 预览赎回结果
const [expectedUsdt, assets, amounts] = await etfRouter.previewBurn(
  ethers.parseEther("1.0")
);
```

## ⚙️ 管理功能

### 更新资产配置

```javascript
// 设置资产使用V3路由，费率0.3%
await etfRouter.setAssetConfig(
  assetAddress,
  true, // useV3
  3000 // 0.3% fee
);
```

### 调整滑点保护

```javascript
// 设置最大滑点为5%
await etfRouter.setMaxSlippage(500);
```

### 暂停/恢复合约

```javascript
// 暂停合约
await etfRouter.setPaused(true);

// 恢复合约
await etfRouter.setPaused(false);
```

## 🧪 测试

运行测试套件：

```bash
npm run test
```

测试覆盖：

- ✅ BlockETF 核心功能
- ✅ Router 权限管理
- ✅ 资产配置管理
- ✅ 滑点保护
- ✅ 紧急控制

## 📈 后续扩展

1. **多币种支持**: 支持 BUSD 等其他稳定币申购
2. **跨链集成**: 使用 LayerZero 实现跨链 ETF
3. **自动再平衡**: 集成 Chainlink Automation
4. **治理功能**: 添加 DAO 投票机制
5. **收益分配**: 实现质押收益自动复投

## 🔒 安全考虑

1. **合约审计**: 建议进行专业安全审计
2. **多签控制**: 使用多重签名控制关键权限
3. **渐进式部署**: 先在测试网充分测试
4. **监控机制**: 建立实时监控和告警
5. **升级策略**: 保持核心合约不可变，业务合约可升级

---

**注意**: 当前实现为 MVP 版本，实际生产部署前需要：

- 完善价格预言机集成
- 添加更完整的错误处理
- 实现精确的滑点计算
- 添加更多的安全检查
- 进行全面的安全审计
