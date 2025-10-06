# **🧱 BlockETF 项目需求文档（BNB Chain + Solidity 版）**

## **一、产品概述**

### **1.1 产品定位**

**BlockETF** 是一个运行在 **BNB Chain** 上的去中心化指数基金平台，允许用户通过单一代币（USDT 或 BUSD）申购由 **Top 5 主流加密资产（BTC、ETH、XRP、SOL、BNB）** 组成的 ETF Token。

ETF 持仓比例示例：

| **代币** | **权重** |
| -------- | -------- |
| BTC      | 30%      |
| ETH      | 25%      |
| BNB      | 20%      |
| XRP      | 15%      |
| SOL      | 10%      |

ETF Token（**bETF-Top5**）反映这 5 种资产的组合价值，用户可通过智能合约一键申购或赎回，并实时查看净值（NAV）。

---

## **二、目标用户**

| **用户类型** | **需求**               | **目标**              |
| ------------ | ---------------------- | --------------------- |
| 普通投资者   | 想长期持有主流加密资产 | 一键分散风险投资      |
| DeFi 用户    | 熟悉钱包与 DEX 操作    | 低滑点投资组合        |
| DAO / 金库   | 管理组合资产           | 自动再平衡 + 透明账本 |
| 被动投资者   | 不想频繁交易           | 自动跟踪市场走势      |

---

## **三、MVP 核心功能**

### **3.1 单币申赎**

- 用户使用 **USDT/BUSD** 申购或赎回 ETF。
- 合约根据当前币价自动兑换目标比例资产。
- 自动发行 / 销毁对应数量的 ETF Token。

### **3.2 自动换币（Swap Aggregator）**

- **集成 ** **1inch 或 PancakeSwap Router** **。**
- 实现自动路径优化与滑点控制。
- 支持多币种兑换到目标资产篮子。

### **3.3 NAV 计算**

- **使用 \*\***Chainlink 预言机\*\* 获取各币种价格。
- 按照资产权重和 Vault 持仓计算 ETF 单位净值。
- 公开 **getNAV()** 接口供前端和分析服务调用。

### **3.4 自动再平衡**

-
-
- 每 24 小时检测一次资产比例偏离。
- **由 \*\***Keeper Bot（链下自动任务）\*\* 调用合约执行再平衡。
- 交易通过 PancakeSwap 自动完成。

---

## **四、技术架构设计**

### **4.1 系统架构图（逻辑结构）**

```mermaid

```

```
+---------------------------------------------+
|                用户前端 (React)             |
|   - ETF 列表 / 详情页 / 申购页 / 个人中心    |
|   - 钱包连接 (MetaMask / WalletConnect)     |
+----------------------|----------------------+
                       |
                       v
+---------------------------------------------+
|            后端服务 (Node.js / NestJS)      |
|   - NAV 缓存与历史记录                       |
|   - Keeper Bot (再平衡触发器)                |
|   - Price Feed Proxy                        |
+----------------------|----------------------+
                       |
                       v
+---------------------------------------------+
|            智能合约层 (Solidity)            |
|   ETFVault.sol         - 资产托管与再平衡    |
|   ETFToken.sol         - ETF ERC20 代币发行  |
|   ETFRouter.sol        - 申购赎回逻辑        |
|   PriceOracle.sol      - 预言机适配          |
|   Keeper.sol           - 自动再平衡入口      |
+---------------------------------------------+
                       |
                       v
+---------------------------------------------+
|               基础设施层                     |
|   - Chainlink Oracle (BNB)                  |
|   - PancakeSwap / 1inch Aggregator          |
|   - BNB Chain (BSC Mainnet / Testnet)       |
+---------------------------------------------+
```

---

### **4.2 智能合约目录结构**

```
contracts/
 ├── ETFVault.sol         # 管理资产池、比例与兑换
 ├── ETFRouter.sol        # 申购赎回逻辑入口
 ├── ETFToken.sol         # ERC20代币 (bETF-Top5)
 ├── PriceOracle.sol      # 调用 Chainlink 价格喂价
 ├── Keeper.sol           # 定期再平衡执行合约
 └── interfaces/
     ├── IPancakeRouter.sol
     ├── IChainlinkOracle.sol
     └── IERC20.sol
```

### **4.3 技术栈选择**

| **层级**         | **技术**                                       | **说明**      |
| ---------------- | ---------------------------------------------- | ------------- |
| **主链**         | **BNB Chain (EVM)**                            | 主部署网络    |
| **智能合约**     | **Solidity (v0.8.x)**                          | 主开发语言    |
| **开发框架**     | **Foundry / Hardhat**                          | 测试与部署    |
| **前端**         | **Next.js + wagmi + RainbowKit + TailwindCSS** | 钱包集成与 UI |
| **后端服务**     | **NestJS + PostgreSQL + Redis**                | NAV 缓存、API |
| **预言机**       | **Chainlink**                                  | 实时价格获取  |
| **DEX 集成**     | **PancakeSwap / 1inch Aggregator**             | 自动换币      |
| **任务自动化**   | **Node.js Keeper Bot + CronJob**               | 定期再平衡    |
| **部署与 CI/CD** | **Docker + GitHub Actions + AWS / Cloudflare** | 自动化部署    |

---

## **五、用户界面流程**

```
[首页]
  ↓
[ETF 列表页] → 查看ETF详情 → 点击“申购”
  ↓
[申购页]
  - 输入申购金额（USDT）
  - 显示目标资产分配比例
  - 用户确认签名
  ↓
[交易确认页]
  - 显示ETF Token余额、交易哈希
  ↓
[个人中心]
  - 查看ETF持仓
  - 查询实时NAV
  - 发起赎回操作
```

---

## **六、开发里程碑**

| **阶段**                          | **时间周期** | **目标**                          | **主要交付物** |
| --------------------------------- | ------------ | --------------------------------- | -------------- |
| **阶段 1：MVP 原型**              | 第 1–2 个月  | 实现单币申购、赎回、NAV 查询      | Testnet Demo   |
| **阶段 2：自动换币 + 前端上线**   | 第 3–4 个月  | 集成 PancakeSwap，构建 DApp UI    | Beta 版本      |
| **阶段 3：自动再平衡 + 主网部署** | 第 5–6 个月  | 完整 ETF 流程 + Keeper Bot 自动化 | 主网正式上线   |

---

## **七、成功指标（KPI）**

| **阶段**        | **指标**          | **目标值** |
| --------------- | ----------------- | ---------- |
| 短期（3 个月）  | 测试用户数        | ≥ 500      |
| 中期（6 个月）  | 主网锁仓量（TVL） | ≥ $1M      |
| 长期（12 个月） | 支持 ETF 产品数量 | ≥ 3 个     |
| 长期            | 年化留存率        | ≥ 60%      |
| 长期            | 日活交易量        | ≥ 300 笔   |

---

## **八、风险分析与应对策略**

| **风险类别**       | **描述**                   | **应对策略**                              |
| ------------------ | -------------------------- | ----------------------------------------- |
| **智能合约风险**   | 逻辑错误或漏洞导致资产损失 | 外部审计（CertiK / PeckShield）+ 多签控制 |
| **价格预言机风险** | Chainlink 数据异常         | 冗余备份（自建喂价或 API 备援）           |
| **DEX 流动性风险** | PancakeSwap 深度不足       | 使用 1inch 聚合器自动分流                 |
| **再平衡频率风险** | 高频执行导致 Gas 成本高    | 调整再平衡触发阈值、批量交易              |
| **市场风险**       | 资产波动导致 NAV 异常      | 透明披露 + 预警机制                       |
| **合规风险**       | ETF 名称触及证券监管       | 使用 “Index Basket Token” 命名避免争议    |

---

## **九、未来扩展方向**

- 多 ETF 产品线（如 bETF-BlueChip、bETF-Layer2）
- 增加收益分配功能（质押或借贷收益自动复投）
- 跨链 ETF 版本（使用 LayerZero / Wormhole）
- DAO 投票决定资产权重
- 增加「稳定币 ETF」、「DeFi 指数」等主题产品

<style>#mermaid-1759744188222{font-family:sans-serif;font-size:16px;fill:#333;}#mermaid-1759744188222 .error-icon{fill:#552222;}#mermaid-1759744188222 .error-text{fill:#552222;stroke:#552222;}#mermaid-1759744188222 .edge-thickness-normal{stroke-width:2px;}#mermaid-1759744188222 .edge-thickness-thick{stroke-width:3.5px;}#mermaid-1759744188222 .edge-pattern-solid{stroke-dasharray:0;}#mermaid-1759744188222 .edge-pattern-dashed{stroke-dasharray:3;}#mermaid-1759744188222 .edge-pattern-dotted{stroke-dasharray:2;}#mermaid-1759744188222 .marker{fill:#333333;}#mermaid-1759744188222 .marker.cross{stroke:#333333;}#mermaid-1759744188222 svg{font-family:sans-serif;font-size:16px;}#mermaid-1759744188222 .label{font-family:sans-serif;color:#333;}#mermaid-1759744188222 .label text{fill:#333;}#mermaid-1759744188222 .node rect,#mermaid-1759744188222 .node circle,#mermaid-1759744188222 .node ellipse,#mermaid-1759744188222 .node polygon,#mermaid-1759744188222 .node path{fill:#ECECFF;stroke:#9370DB;stroke-width:1px;}#mermaid-1759744188222 .node .label{text-align:center;}#mermaid-1759744188222 .node.clickable{cursor:pointer;}#mermaid-1759744188222 .arrowheadPath{fill:#333333;}#mermaid-1759744188222 .edgePath .path{stroke:#333333;stroke-width:1.5px;}#mermaid-1759744188222 .flowchart-link{stroke:#333333;fill:none;}#mermaid-1759744188222 .edgeLabel{background-color:#e8e8e8;text-align:center;}#mermaid-1759744188222 .edgeLabel rect{opacity:0.5;background-color:#e8e8e8;fill:#e8e8e8;}#mermaid-1759744188222 .cluster rect{fill:#ffffde;stroke:#aaaa33;stroke-width:1px;}#mermaid-1759744188222 .cluster text{fill:#333;}#mermaid-1759744188222 div.mermaidTooltip{position:absolute;text-align:center;max-width:200px;padding:2px;font-family:sans-serif;font-size:12px;background:hsl(80,100%,96.2745098039%);border:1px solid #aaaa33;border-radius:2px;pointer-events:none;z-index:100;}#mermaid-1759744188222:root{--mermaid-font-family:sans-serif;}#mermaid-1759744188222:root{--mermaid-alt-font-family:sans-serif;}#mermaid-1759744188222 flowchart{fill:apa;}</style>
