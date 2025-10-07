import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const BlockETFModule = buildModule("BlockETFModule", (m) => {
    // BSC测试网地址配置
    const BSC_CONFIG = {
        USDT: "0x55d398326f99059fF775485246999027B3197955", // BSC Mainnet USDT
        PANCAKE_V2_ROUTER: "0x10ED43C718714eb63d5aA57B78B54704E256024E", // PancakeSwap V2 Router
        PANCAKE_V3_ROUTER: "0x13f4EA83D0bd40E75C8222255bc855a974568Dd4", // PancakeSwap V3 Router
    };

    // 部署BlockETF核心合约
    const blockETF = m.contract("BlockETF");

    // 部署ETFRouter合约
    const etfRouter = m.contract("ETFRouter", [
        blockETF,
        BSC_CONFIG.USDT,
        BSC_CONFIG.PANCAKE_V2_ROUTER,
        BSC_CONFIG.PANCAKE_V3_ROUTER,
    ]);

    // 设置Router为BlockETF的管理员
    m.call(blockETF, "setManager", [etfRouter, true]);

    return { blockETF, etfRouter };
});

export default BlockETFModule;
