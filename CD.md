# **智能合约架构设计文档（EVM + Solidity）——BlockETF（bETF-Top5）**

下面是面向 **BNB Chain / 任何 EVM 兼容链** 的完整智能合约架构设计，包含合约分层、状态与存储布局、接口签名、再平衡机制、Oracles/DEX 集成、治理与升级策略、安全与测试要点等。目标是把需求（单币申赎、自动换币、NAV 计算、再平衡）以可实现、可审计、可升级的合约集合交付。

---

# **一、总体架构与合约清单**

```
contracts/
 ├─ ETFToken.sol           // ERC20 代表 ETF 份额（bETF-Top5）
 ├─ ETFVault.sol           // 资产池、持仓记录、申赎与再平衡核心逻辑
 ├─ ETFRouter.sol          // 用户交互入口：申购/赎回（支付单币 -> 调用 Vault）
 ├─ PriceOracle.sol        // 价格聚合器（Chainlink adapter + fallback）
 ├─ SwapAdapter.sol        // DEX 聚合器适配（1inch / Pancake）封装 swap 调用
 ├─ KeeperManager.sol      // 再平衡触发的受权入口（由 Keeper/Chainlink Keepers / Gelato 调用）
 ├─ FeeManager.sol         // 手续费计算/分配（可选）
 ├─ Governance.sol         // 可选：参数管理（多签 / DAO）
 └─ libs/
     └─ SafeERC20.sol
```

说明：

* **ETFRouter** 为轻量路由合约，降低用户的 gas 与权限边界。
* **ETFVault** 为业务核心，包含持仓账户（Vault token accounts 即合约内代币余额）、净值计算、再平衡步序。
* **SwapAdapter** 把外部 DEX 聚合器接口封装，便于替换与审计。
* 使用 OpenZeppelin 标准库（ERC20、Ownable、Pausable、ReentrancyGuard）配合自定义 Role 控制。

---

# **二、核心数据结构与存储布局（ETFVault）**

> 以节省 gas 与便于审计的线性存储为主，避免复杂嵌套映射。

```
struct Asset {
    address token;        // 代币地址 (BEP-20)
    uint256 targetWeight; // 权重，单位：parts-per-million (ppm) 或 basis points
    uint256 balance;      // 在 Vault 中的 on-chain token balance (cached)
    uint8 decimals;       // 便于计算
}

contract ETFVault {
    address public admin;            // 管理员 / timelock 或治理合约
    address public etfToken;         // bETF ERC20 mint address
    address public priceOracle;      // PriceOracle 合约地址
    address public swapAdapter;      // SwapAdapter 地址
    address public feeManager;       // FeeManager（可选）
    Asset[] public assets;           // 固定顺序的资产数组 (BTC, ETH, XRP, SOL, BNB)
    mapping(address => uint256) public userShares; // not necessary if ERC20 handles
    uint256 public totalShares;      // ETF 总份额（etfToken.totalSupply）
    uint256 public lastRebalance;    // timestamp
    bool public paused;
    uint256 public rebalanceThreshold; // e.g. 5% in ppm
}
```

注意：**assets** 以数组而非 mapping 保存以确保顺序一致（权重列表与索引匹配，便于前端显示与再平衡计算）。

---

# **三、关键合约函数与外部接口（函数签名示例）**

## **ETFToken.sol （ERC20）**

标准 ERC20，带 **mint(address,uint256)** / **burn(address,uint256)**，只有 Vault（或 Router）有 MINTER 权限。

```
function mint(address to, uint256 amount) external;
function burn(address from, uint256 amount) external;
```

## **ETFRouter.sol**

用户入口，简化申购/赎回流程（单币 -> Vault 内换币 -> mint shares）。

```
// 用户用 singleToken (USDT/BUSD) 申购：router 执行 token transferFrom -> approve swapAdapter -> call vault.deposit()
function subscribeSingle(
    address singleToken,
    uint256 amountIn,
    uint256 minSharesOut,
    uint256 maxSlippageBps
) external returns (uint256 sharesMinted);

// 赎回：用户 burn ETF token -> Vault 根据 NAV 卖出构成 -> 用户收到 singleToken
function redeemSingle(
    address singleToken,
    uint256 shares,
    uint256 minAmountOut,
    uint256 maxSlippageBps
) external returns (uint256 amountOut);
```

## **ETFVault.sol**

核心计算与兑换、再平衡逻辑

```
// 仅由 Router 或 keeper 调用
function depositAndAllocate(address from, address singleToken, uint256 amount) external returns (uint256 sharesMinted);

// 赎回并兑换成 singleToken
function redeemAndSwap(address to, address singleToken, uint256 shares) external returns (uint256 amountOut);

// 查询 NAV（按 1 share）
function getNAV() external view returns (uint256 navInSingleToken);

// 触发再平衡（只有 keeper / authorized）
function rebalance() external;

// 管理员函数：调整权重、添加/移除资产（需要治理）
function setWeights(uint256[] calldata newWeights) external;
```

## **PriceOracle.sol（聚合）**

提供标准价格（以基础计价币，比如 USDT）：

```
function getPrice(address token) external view returns (uint256 price, uint8 decimals);
```

实现建议：Chainlink on BNB + 本地 fallback（多源冗余），返回统一精度（e.g. 1e8）。

## **SwapAdapter.sol**

封装交换操作，隐藏复杂度并限制 slippage：

```
function swap(
    address fromToken,
    address toToken,
    uint256 amountIn,
    uint256 minAmountOut,
    bytes calldata routeData
) external returns (uint256 amountOut);
```

**routeData** 可携带 1inch / PancakeSwap 路由参数（便于未来扩展）。

---

# **四、NAV（净值）计算方法**

**定义：**NAV_per_share = (Σ reserve_i * price_i_in_quote) / totalShares

实现细节：

1. 选择计价货币（quote）为 **BUSD** 或 **USDT**（稳定币）。所有 price oracle 返回 **price(token)/quote**。
2. **reserve_i** 取 Vault 中 **token** 的 on-chain balance （由 contract 的 token balance 或内部缓存读取）。
3. 使用 **uint256** 与固定小数（1e18）做幂次缩放，注意不同 token decimals。
4. 若 **totalShares == 0**，新供给时使用初始兑换比率（1:1 规则或由系统定义）。

示例（伪代码）：

```
uint256 totalValue = 0;
for each asset in assets:
    balance = IERC20(asset.token).balanceOf(address(this));
    (price, pdec) = Oracle.getPrice(asset.token);
    value = balance * price / (10 ** asset.decimals) // normalize
    totalValue += value;
nav = totalValue * 1e18 / totalShares; // nav with 1e18 scaling
```

---

# **五、申购 / 赎回流程（交互序列）**

### **申购（用户 -> Router）**

1. 用户 **approve** Router 转移 **USDT**（singleToken）。
2. **调用 **Router.subscribeSingle(singleToken, amountIn, minSharesOut, maxSlippageBps)**。**
3. **Router 转入 Vault：**transferFrom** -> **Vault.depositAndAllocate()**。**
4. Vault 调用 **SwapAdapter** 将 USDT 换成各 target token（按 targetWeight），或直接在一个 swap 请求中使用 aggregator 进行多次 swap。
5. **Vault 更新 **assets[i].balance**，计算 **sharesMinted = amountValueInQuote * shareRate**，并 **ETFToken.mint(user, sharesMinted)**。**
6. **事件 **Subscribed(user, amountIn, sharesMinted)**。**

### **赎回（用户 -> Router）**

1. 用户 **approve** Router 使用 ETFToken -> Router 转给 Vault 或直接在 Vault 执行 burn。
2. Vault 按当前持仓卖出对应资产，换成 singleToken（使用 SwapAdapter with slippage controls）。
3. 将单币转回用户，销毁 shares。
4. **事件 **Redeemed(user, sharesBurned, amountOut)**。**

注意：为降低滑点与 gas，申购可支持两种模式：**即时模式（on-chain 实时 swap）** 与 **排队换币（延迟结算）**。MVP 推荐即时模式。

---

# **六、再平衡机制设计**

## **触发条件**

* 每日定期扫描（keeper Cron）。
* 或某一资产偏离目标权重超过 **rebalanceThreshold**（例如 5%）时触发。

## **算法（high-level）**

1. 读取当前 reserves 与 prices → 计算当前实际权重 **w_i = value_i / totalValue**。
2. **计算偏差 **delta_i = w_i - targetWeight_i**。**
3. **对于 **delta_i > threshold**（超配），将超配部分标记为卖出量；对于 **delta_i < -threshold**（欠配），标记为买入量。**
4. 形成卖出清单与买入清单。优先把卖出的资产兑换成 quote（USDT），再从 quote 兑换成买入资产，或直接进行资产间 swap（根据路由策略选择）。
5. 执行 swaps（优先使用聚合器以减少滑点），并在完成后更新 **assets[i].balance** 与 **lastRebalance**。
6. 记录 **RebalanceExecuted** 事件（包含 pre/post 比例、交易哈希与费用）。

## **Keeper 权限与补偿**

* Keeper 调用 **vault.rebalance()** 需受 access control 限制（onlyKeeper 或 onlyAuthorized）。
* Keeper 执行可获得 **rebalanceReward**（由 FeeManager 支付，或以 gas 补贴方式）以激励离线 bot（Gelato/Chainlink Keepers）。

---

# **七、Oracles 与 DEX 集成（实现细节）**

## **Oracle（Chainlink）**

* 每个资产使用 Chainlink Price Feed（BNB Chain 上的地址）。
* PriceAdapter 封装：若 Chainlink 返回失败或 stale → 使用 off-chain aggregator 或二级 oracle（或 fallback to centralized API via backend + signed price）。
* 价格精度统一为 1e8 或 1e18（文档中定义）并在代码中明确注释。

## **Swap（PancakeSwap / 1inch）**

* **使用 **SwapAdapter** 抽象：**swap(from, to, amount, minOut, routeData)**。**
* 初始实现可使用 PancakeSwap Router（路径数组）；后期支持 1inch aggregator（更省滑点）。
* 所有 swap 都必须设置 **minAmountOut**（由前端/后端预估并传入），并在合约内部对 slippage 做二次检查。

---

# **八、费用、激励与会计**

## **费用模型（示例）**

* 申购费：**subscribeFeeBps**（如 10 bps）——用于覆盖 swap 成本与平台收益。
* 赎回费：**redeemFeeBps**（如 10 bps）。
* **管理费（可选）：年化 **managementFeeBps**，按日计提并分配到 **feePool**。**
* Keeper 奖励：再平衡或调用者奖励 **rebalanceReward**（可为固定 USDT 或 bps）。

## **会计**

* 所有费用先转入 **FeeManager** 合约（或 Vault 的 fee pool），并可由治理或管理员提取到 treasury。
* 费用分配透明并在事件中记录。

---

# **九、权限模型与治理**

## **最小权限原则**

* ETFTokem.minter** → only **ETFVault** 或 **ETFRouter**。**
* 管理员（**admin**）用于参数调整，但关键操作应受 timelock 或多签保护（例如 Gnosis Safe）。
* **setWeights**、**addAsset**、**removeAsset** 等敏感操作应经治理（DAO 提案）或延迟（timelock）。

## **建议治理流程**

* 初始阶段：**admin** 为 multisig（3/5） + timelock (48h)。
* 后期：把 admin 权限迁移给 **Governance.sol**（DAO）合约。

---

# **十、安全性、升级与审计**

## **安全模块**

* **使用 OpenZeppelin 的 **ReentrancyGuard**、**Pausable**、**Ownable** / **AccessControl**。**
* **交易/交换前务必对 **minAmountOut**、**slippage**、**deadline** 做检查。**
* 关键异常需触发 **pause()**（管理员或 guardian）并记录 **EmergencyPause**。

## **升级策略**

* 使用透明代理（OpenZeppelin Upgradeable Proxy）或 Beacon Proxy（方便多合约统一升级）。
* 升级需经过多签 + timelock + 审计。
* 尽量把状态结构放在不可变的 **Vault**，把逻辑放在实现合约，升级时保持存储布局向后兼容（遵守 upgrade safe patterns）。

## **审计与测试**

* 必须经过至少两家第三方审计（内部 + 外部，如 CertiK、Trail of Bits）。
* 自动化测试覆盖：单元测试、集成测试（Mainnet fork 测试）、安全 fuzz tests、回放历史波动场景测试。
* 使用 MythX / Slither / Securify 静态分析工具。

---

# **十一、开发、测试与 CI/CD 建议**

## **本地开发工具**

* Foundry 或 Hardhat（推荐 Foundry 用于高效单元测试）。
* 使用 mainnet-fork（BNB mainnet fork）做 Swap 集成测试（验证路由与滑点处理）。
* Mock Oracles + Mock DEX 用于单元测试。

## **CI/CD**

* GitHub Actions：run lint、solhint、forge tests、static analysis、gas report、contract verify（Etherscan/BscScan）。
* 部署脚本（Hardhat/Foundry）应区分 **testnet**/**mainnet**、配置 multisig addresses 与 timelock。

---

# **十二、Gas 与性能优化建议**

* 避免循环对外部合约的重复调用（例如大数组 swap 时合并交易或批量 swap）。
* 缓存 token decimals、prices 采用短期缓存以减少 oracle 调用次数（但要保证数据新鲜性）。
* 使用 **uint256** 统一计算基准并尽量在合约内部完成数学运算后一次性写存储（减少 SSTORE）。
* 尽量把复杂/昂贵的计算放到 off-chain（后端）做预计算，合约只做验证与最终执行（例如计算 swap amounts，用户提交预估 minOut 并签名或由后端提供）。

---

# **十三、事件设计（便于审计与前端跟踪）**

关键事件示例：

```
event Subscribed(address indexed user, address indexed singleToken, uint256 amountIn, uint256 sharesMinted);
event Redeemed(address indexed user, address indexed singleToken, uint256 sharesBurned, uint256 amountOut);
event RebalanceExecuted(address indexed keeper, uint256 timestamp, uint256[] preWeights, uint256[] postWeights, uint256 totalFees);
event FeesCollected(address indexed to, uint256 amount);
event EmergencyPaused(address indexed who);
event WeightUpdated(uint256[] newWeights);
```

---

# **十四、示例合约片段（接口风格）**

```
interface IETFVault {
    function depositAndAllocate(address user, address singleToken, uint256 amount, uint256 minSharesOut) external returns (uint256);

    function redeemAndSwap(address user, address singleToken, uint256 shares, uint256 minAmountOut) external returns (uint256);

    function getNAV() external view returns (uint256); // returns nav scaled 1e18

    function rebalance() external;
}
```

---

# **十五、运维与监控（生产就绪要点）**

* 实时监控：合约事件、链上 TVL、swap 失败率、oracle 数据 staleness 警报。
* 自动化报警（Slack/Discord/PagerDuty）：当 NAV 波动超常或 swap 失败率上升时发警。
* 交易追踪 dashboard：展示每次再平衡的交易明细（txHash、gas、滑点、费用）。

---

# **十六、下一步交付建议（你可以选其一让我继续生成）**

1. **合约接口文档（完整 ABI 风格的函数与事件签名）** **；**
2. **Foundry / Hardhat 项目模板**（含 ETFTokens.sol**, **ETFVault.sol**骨架、测试样例、部署脚本）；**
3. **再平衡算法 pseudo-code + off-chain keeper 实现（Node.js 示例）** **；**
4. **安全审计清单与测试用例矩阵** **（便于提交审计机构）。**
