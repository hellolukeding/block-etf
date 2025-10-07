// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./interfaces/IERC20.sol";
import "./interfaces/IBlockETF.sol";
import "./interfaces/IPancakeRouter02.sol";
import "./interfaces/IPancakeV3Router.sol";

contract ETFRouter {
    // 核心合约
    IBlockETF public immutable blockETF;
    
    // DEX路由器
    IPancakeRouter02 public immutable pancakeV2Router;
    IPancakeV3Router public immutable pancakeV3Router;
    
    // 主要稳定币 (USDT)
    IERC20 public immutable usdt;
    
    // 资产配置
    struct AssetConfig {
        bool useV3;          // 是否使用V3
        uint24 v3Fee;        // V3手续费档位
        address customPool;   // 自定义池地址 (如果有)
    }
    
    mapping(address => AssetConfig) public assetConfigs;
    
    // 控制参数
    address public owner;
    uint256 public maxSlippage = 300; // 3% 最大滑点
    bool public paused = false;
    
    // 事件
    event Minted(address indexed user, uint256 usdtAmount, uint256 shares);
    event Burned(address indexed user, uint256 shares, uint256 usdtAmount);
    event AssetConfigUpdated(address indexed asset, bool useV3, uint24 v3Fee);
    event SlippageUpdated(uint256 newSlippage);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    
    modifier notPaused() {
        require(!paused, "Contract is paused");
        _;
    }
    
    constructor(
        address _blockETF,
        address _usdt,
        address _pancakeV2Router,
        address _pancakeV3Router
    ) {
        blockETF = IBlockETF(_blockETF);
        usdt = IERC20(_usdt);
        pancakeV2Router = IPancakeRouter02(_pancakeV2Router);
        pancakeV3Router = IPancakeV3Router(_pancakeV3Router);
        owner = msg.sender;
        
        // 初始化资产配置
        _initializeAssetConfigs();
    }
    
    function _initializeAssetConfigs() internal {
        // WBNB: 使用V2 (流动性更好)
        assetConfigs[0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c] = AssetConfig({
            useV3: false,
            v3Fee: 0,
            customPool: address(0)
        });
        
        // BTCB: 使用V3
        assetConfigs[0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c] = AssetConfig({
            useV3: true,
            v3Fee: 2500, // 0.25%
            customPool: address(0)
        });
        
        // ETH: 使用V3
        assetConfigs[0x2170Ed0880ac9A755fd29B2688956BD959F933F8] = AssetConfig({
            useV3: true,
            v3Fee: 2500, // 0.25%
            customPool: address(0)
        });
        
        // XRP: 使用V3
        assetConfigs[0x1D2F0da169ceB9fC7B3144628dB156f3F6c60dBE] = AssetConfig({
            useV3: true,
            v3Fee: 2500, // 0.25%
            customPool: address(0)
        });
        
        // SOL: 使用V3
        assetConfigs[0x570A5D26f7765Ecb712C0924E4De545B89fD43dF] = AssetConfig({
            useV3: true,
            v3Fee: 2500, // 0.25%
            customPool: address(0)
        });
    }
    
    /**
     * @dev 使用USDT申购ETF份额
     * @param usdtAmount 投入的USDT数量
     * @param minShares 期望获得的最少份额 (滑点保护)
     * @return shares 实际铸造的份额数量
     */
    function mintWithUSDT(
        uint256 usdtAmount,
        uint256 minShares
    ) external notPaused returns (uint256 shares) {
        require(usdtAmount > 0, "Invalid USDT amount");
        
        // 1. 转入用户USDT
        usdt.transferFrom(msg.sender, address(this), usdtAmount);
        
        // 2. 获取目标资产和权重
        (address[] memory assets, uint256[] memory weights) = blockETF.getTargetWeights();
        
        // 3. 计算应该购买的每种资产数量
        uint256[] memory targetAmounts = new uint256[](assets.length);
        uint256 totalUsedUsdt = 0;
        
        for (uint i = 0; i < assets.length; i++) {
            uint256 assetUsdtAllocation = (usdtAmount * weights[i]) / 1e18;
            if (assetUsdtAllocation > 0) {
                targetAmounts[i] = _swapUSDTToAsset(assets[i], assetUsdtAllocation);
                totalUsedUsdt += assetUsdtAllocation;
            }
        }
        
        // 4. 计算应该铸造的份额数量
        shares = _calculateSharesToMint(assets, targetAmounts);
        require(shares >= minShares, "Slippage protection: shares too low");
        
        // 5. 将资产存入BlockETF并铸造份额
        _depositAssetsAndMint(assets, targetAmounts, shares);
        
        // 6. 返还多余的USDT
        uint256 remainingUsdt = usdt.balanceOf(address(this));
        if (remainingUsdt > 0) {
            usdt.transfer(msg.sender, remainingUsdt);
        }
        
        emit Minted(msg.sender, usdtAmount, shares);
    }
    
    /**
     * @dev 赎回ETF份额换回USDT
     * @param shares 要赎回的份额数量
     * @param minUsdtAmount 期望获得的最少USDT数量 (滑点保护)
     * @return usdtAmount 实际获得的USDT数量
     */
    function burnToUSDT(
        uint256 shares,
        uint256 minUsdtAmount
    ) external notPaused returns (uint256 usdtAmount) {
        require(shares > 0, "Invalid shares amount");
        
        // 1. 从用户账户销毁份额并获取底层资产
        (address[] memory assets, uint256[] memory amounts) = blockETF.calculateRequiredAssets(shares);
        
        // 2. 销毁份额并提取资产
        blockETF.burn(msg.sender, shares);
        blockETF.withdrawAssets(assets, amounts);
        
        // 3. 将所有资产换回USDT
        for (uint i = 0; i < assets.length; i++) {
            if (amounts[i] > 0) {
                usdtAmount += _swapAssetToUSDT(assets[i], amounts[i]);
            }
        }
        
        require(usdtAmount >= minUsdtAmount, "Slippage protection: USDT amount too low");
        
        // 4. 转账给用户
        usdt.transfer(msg.sender, usdtAmount);
        
        emit Burned(msg.sender, shares, usdtAmount);
    }
    
    /**
     * @dev 将USDT换成指定资产
     */
    function _swapUSDTToAsset(address asset, uint256 usdtAmount) internal returns (uint256 assetAmount) {
        if (usdtAmount == 0) return 0;
        
        AssetConfig memory config = assetConfigs[asset];
        
        if (config.useV3) {
            // 使用V3路由
            assetAmount = _swapUSDTToAssetV3(asset, usdtAmount, config.v3Fee);
        } else {
            // 使用V2路由
            assetAmount = _swapUSDTToAssetV2(asset, usdtAmount);
        }
    }
    
    /**
     * @dev 将资产换成USDT
     */
    function _swapAssetToUSDT(address asset, uint256 assetAmount) internal returns (uint256 usdtAmount) {
        if (assetAmount == 0) return 0;
        
        AssetConfig memory config = assetConfigs[asset];
        
        if (config.useV3) {
            // 使用V3路由
            usdtAmount = _swapAssetToUSDTV3(asset, assetAmount, config.v3Fee);
        } else {
            // 使用V2路由
            usdtAmount = _swapAssetToUSDTV2(asset, assetAmount);
        }
    }
    
    /**
     * @dev V2路由: USDT -> Asset
     */
    function _swapUSDTToAssetV2(address asset, uint256 usdtAmount) internal returns (uint256 assetAmount) {
        address[] memory path = new address[](2);
        path[0] = address(usdt);
        path[1] = asset;
        
        // 计算最小输出 (考虑滑点)
        uint256[] memory amountsOut = pancakeV2Router.getAmountsOut(usdtAmount, path);
        uint256 minAmountOut = (amountsOut[1] * (10000 - maxSlippage)) / 10000;
        
        // 执行交换
        usdt.approve(address(pancakeV2Router), usdtAmount);
        uint256[] memory amounts = pancakeV2Router.swapExactTokensForTokens(
            usdtAmount,
            minAmountOut,
            path,
            address(this),
            block.timestamp + 300
        );
        
        return amounts[1];
    }
    
    /**
     * @dev V2路由: Asset -> USDT
     */
    function _swapAssetToUSDTV2(address asset, uint256 assetAmount) internal returns (uint256 usdtAmount) {
        address[] memory path = new address[](2);
        path[0] = asset;
        path[1] = address(usdt);
        
        // 计算最小输出 (考虑滑点)
        uint256[] memory amountsOut = pancakeV2Router.getAmountsOut(assetAmount, path);
        uint256 minAmountOut = (amountsOut[1] * (10000 - maxSlippage)) / 10000;
        
        // 执行交换
        IERC20(asset).approve(address(pancakeV2Router), assetAmount);
        uint256[] memory amounts = pancakeV2Router.swapExactTokensForTokens(
            assetAmount,
            minAmountOut,
            path,
            address(this),
            block.timestamp + 300
        );
        
        return amounts[1];
    }
    
    /**
     * @dev V3路由: USDT -> Asset
     */
    function _swapUSDTToAssetV3(address asset, uint256 usdtAmount, uint24 fee) internal returns (uint256 assetAmount) {
        // 简化处理，实际应该先查询预期输出
        uint256 minAmountOut = 0; // 在实际实现中应该通过quoter计算
        
        IPancakeV3Router.ExactInputSingleParams memory params = IPancakeV3Router.ExactInputSingleParams({
            tokenIn: address(usdt),
            tokenOut: asset,
            fee: fee,
            recipient: address(this),
            deadline: block.timestamp + 300,
            amountIn: usdtAmount,
            amountOutMinimum: minAmountOut,
            sqrtPriceLimitX96: 0
        });
        
        usdt.approve(address(pancakeV3Router), usdtAmount);
        return pancakeV3Router.exactInputSingle(params);
    }
    
    /**
     * @dev V3路由: Asset -> USDT
     */
    function _swapAssetToUSDTV3(address asset, uint256 assetAmount, uint24 fee) internal returns (uint256 usdtAmount) {
        // 简化处理，实际应该先查询预期输出
        uint256 minAmountOut = 0; // 在实际实现中应该通过quoter计算
        
        IPancakeV3Router.ExactInputSingleParams memory params = IPancakeV3Router.ExactInputSingleParams({
            tokenIn: asset,
            tokenOut: address(usdt),
            fee: fee,
            recipient: address(this),
            deadline: block.timestamp + 300,
            amountIn: assetAmount,
            amountOutMinimum: minAmountOut,
            sqrtPriceLimitX96: 0
        });
        
        IERC20(asset).approve(address(pancakeV3Router), assetAmount);
        return pancakeV3Router.exactInputSingle(params);
    }
    
    /**
     * @dev 计算应该铸造的份额数量
     */
    function _calculateSharesToMint(
        address[] memory assets,
        uint256[] memory amounts
    ) internal view returns (uint256 shares) {
        uint256 totalSupply = blockETF.totalSupply();
        
        if (totalSupply == 0) {
            // 初始份额：基于总价值计算 (简化处理)
            return 1e18; // 铸造1个ETF作为初始份额
        }
        
        // 基于资产比例计算份额
        (address[] memory existingAssets, uint256[] memory existingBalances) = blockETF.getAssetBalances();
        
        uint256 minSharesRatio = type(uint256).max;
        
        for (uint i = 0; i < assets.length; i++) {
            if (amounts[i] > 0) {
                for (uint j = 0; j < existingAssets.length; j++) {
                    if (existingAssets[j] == assets[i] && existingBalances[j] > 0) {
                        uint256 ratio = (amounts[i] * totalSupply) / existingBalances[j];
                        if (ratio < minSharesRatio) {
                            minSharesRatio = ratio;
                        }
                        break;
                    }
                }
            }
        }
        
        return minSharesRatio == type(uint256).max ? 1e18 : minSharesRatio;
    }
    
    /**
     * @dev 存入资产并铸造份额
     */
    function _depositAssetsAndMint(
        address[] memory assets,
        uint256[] memory amounts,
        uint256 shares
    ) internal {
        // 存入资产到BlockETF
        for (uint i = 0; i < assets.length; i++) {
            if (amounts[i] > 0) {
                IERC20(assets[i]).approve(address(blockETF), amounts[i]);
            }
        }
        
        blockETF.depositAssets(assets, amounts);
        
        // 铸造份额给用户
        blockETF.mint(msg.sender, shares);
    }
    
    // 管理功能
    function setAssetConfig(
        address asset,
        bool useV3,
        uint24 v3Fee
    ) external onlyOwner {
        assetConfigs[asset] = AssetConfig({
            useV3: useV3,
            v3Fee: v3Fee,
            customPool: address(0)
        });
        
        emit AssetConfigUpdated(asset, useV3, v3Fee);
    }
    
    function setMaxSlippage(uint256 _maxSlippage) external onlyOwner {
        require(_maxSlippage <= 1000, "Slippage too high"); // 最大10%
        maxSlippage = _maxSlippage;
        emit SlippageUpdated(_maxSlippage);
    }
    
    function setPaused(bool _paused) external onlyOwner {
        paused = _paused;
    }
    
    function emergencyWithdraw(address token, uint256 amount) external onlyOwner {
        IERC20(token).transfer(owner, amount);
    }
    
    /**
     * @dev 获取申购预览 (不执行交易)
     */
    function previewMint(uint256 usdtAmount) external view returns (
        uint256 expectedShares,
        address[] memory assets,
        uint256[] memory assetAmounts
    ) {
        (assets, ) = blockETF.getTargetWeights();
        assetAmounts = new uint256[](assets.length);
        
        // 简化预览计算，实际应该调用DEX的quoter
        for (uint i = 0; i < assets.length; i++) {
            (, uint256[] memory weights) = blockETF.getTargetWeights();
            uint256 assetUsdtAllocation = (usdtAmount * weights[i]) / 1e18;
            
            if (assetUsdtAllocation > 0) {
                // 这里应该调用相应DEX的quoter获取准确价格
                // 简化处理，假设1:1比例
                assetAmounts[i] = assetUsdtAllocation;
            }
        }
        
        expectedShares = _calculateSharesToMint(assets, assetAmounts);
    }
    
    /**
     * @dev 获取赎回预览 (不执行交易)
     */
    function previewBurn(uint256 shares) external view returns (
        uint256 expectedUsdtAmount,
        address[] memory assets,
        uint256[] memory assetAmounts
    ) {
        (assets, assetAmounts) = blockETF.calculateRequiredAssets(shares);
        
        // 简化处理，实际应该调用DEX的quoter计算准确的USDT输出
        expectedUsdtAmount = 0;
        for (uint i = 0; i < assets.length; i++) {
            if (assetAmounts[i] > 0) {
                // 这里应该调用相应DEX的quoter获取准确价格
                // 简化处理，假设1:1比例
                expectedUsdtAmount += assetAmounts[i];
            }
        }
    }
}
