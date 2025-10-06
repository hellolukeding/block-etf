# BlockETF - 去中心化指数基金平台

BlockETF 是一个运行在 BNB Chain 上的去中心化指数基金平台，允许用户通过单一代币申购由 Top 5 主流加密资产组成的 ETF Token。

## 项目结构

```
block-etf/
├── README.md              # 项目说明文档
├── PRD.md                 # 产品需求文档
├── CD.md                  # 代码设计文档
├── package.json           # Node.js 项目配置
├── hardhat.config.ts      # Hardhat 框架配置
├── tsconfig.json          # TypeScript 配置
│
├── contracts/             # 智能合约源码
│   ├── Counter.sol        # 示例计数器合约
│   └── Counter.t.sol.foundry # Foundry 测试文件
│
├── scripts/               # 部署和脚本文件
│   ├── deploy.ts          # 合约部署脚本
│   └── send-op-tx.ts      # OP 交易脚本
│
├── test/                  # 测试文件
│   └── Counter.ts         # 合约测试用例
│
├── ignition/              # Hardhat Ignition 部署模块
│   └── modules/
│       └── Counter.ts     # 部署模块配置
│
├── artifacts/             # 编译产物（自动生成）
│   ├── artifacts.d.ts     # 类型定义
│   ├── build-info/        # 编译信息
│   └── contracts/         # 编译后的合约文件
│
└── cache/                 # 编译缓存（自动生成）
    └── compile-cache.json
```

## 目录详解

### 📂 contracts/
存放智能合约的源代码文件（.sol 格式）
- **Counter.sol**: 示例计数器合约，用于演示基本的智能合约功能
- **Counter.t.sol.foundry**: Foundry 框架的测试文件

### 📂 scripts/
包含部署脚本和其他自动化脚本
- **deploy.ts**: 智能合约部署脚本，用于将合约部署到区块链网络
- **send-op-tx.ts**: Optimism 相关的交易发送脚本

### 📂 test/
存放测试文件，用于验证智能合约的功能
- **Counter.ts**: 使用 Hardhat 框架编写的测试用例

### 📂 ignition/modules/
Hardhat Ignition 插件的部署模块配置
- **Counter.ts**: 定义了合约的部署流程和参数配置

### 📂 artifacts/
编译生成的产物目录（请勿手动修改）
- 包含编译后的合约 ABI、字节码等信息
- 自动生成的类型定义文件

### 📂 cache/
Hardhat 的编译缓存（请勿手动修改）
- 用于加速重复编译过程

## 配置文件说明

- **hardhat.config.ts**: Hardhat 开发框架的主配置文件，定义网络、插件、编译器等设置
- **package.json**: Node.js 项目配置，包含依赖包和脚本命令
- **tsconfig.json**: TypeScript 编译器配置

## 文档说明

- **PRD.md**: 产品需求文档，详细描述了 BlockETF 平台的功能需求和业务逻辑
- **CD.md**: 代码设计文档，包含系统架构和技术实现细节

## 快速开始

1. 安装依赖：
   ```bash
   yarn install
   ```

2. 编译合约：
   ```bash
   yarn compile
   ```

3. 运行测试：
   ```bash
   yarn test
   ```

4. 部署合约：
   ```bash
   yarn deploy
   ```

## 技术栈

- **Solidity**: 智能合约开发语言
- **Hardhat**: 以太坊开发环境和测试框架
- **TypeScript**: 类型安全的 JavaScript 超集
- **Viem**: 现代化的以太坊库
- **BNB Chain**: 目标部署区块链网络
