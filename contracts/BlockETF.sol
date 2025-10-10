// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./interfaces/IERC20.sol";
import "./interfaces/IBlockETF.sol";

/**
 * @title BlockETF
 * @dev 区块链ETF代币合约，代表持有一篮子基础资产的ETF份额
 * 实现了ERC20标准和IBlockETF接口，支持资产组合管理、份额铸造/销毁等功能
 */
contract BlockETF is IBlockETF, IERC20 {
    // ERC20代币基本信息
    string public name = "Block ETF Token";     // 代币名称
    string public symbol = "bETF";              // 代币符号
    uint8 public decimals = 18;                 // 代币精度
    
    // 代币供应量和账户余额映射
    uint256 private _totalSupply;                           // ETF总供应量
    mapping(address => uint256) private _balances;          // 账户余额映射
    mapping(address => mapping(address => uint256)) private _allowances; // 授权额度映射
    
    // 资产管理相关变量
    address[] public supportedAssets;                           // 支持的资产列表
    mapping(address => bool) public isAssetSupported;           // 资产是否被支持的映射
    mapping(address => uint256) public assetBalances;           // 各资产的当前余额
    mapping(address => uint256) public targetWeights; // 目标权重，以1e18为基数，即100% = 1e18
    
    // 权限控制相关变量
    mapping(address => bool) public managers;   // 管理员映射
    address public owner;                       // 合约所有者地址
    
    // 仅所有者可调用的修饰符
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    
    // 仅管理员可调用的修饰符
    modifier onlyManager() {
        require(managers[msg.sender], "Not authorized manager");
        _;
    }
    
    /**
     * @dev 合约构造函数，初始化所有者、管理员和支持的资产
     * 在BSC测试网上初始化一组预定义的加密资产及其权重
     */
    constructor() {
        owner = msg.sender;
        managers[msg.sender] = true;
        
        // 初始化支持的资产 (BSC测试网地址)
        // 这里使用模拟地址，实际部署时需要替换为真实地址
        address[] memory assets = new address[](5);
        assets[0] = 0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c; // BTCB
        assets[1] = 0x2170Ed0880ac9A755fd29B2688956BD959F933F8; // ETH
        assets[2] = 0x1D2F0da169ceB9fC7B3144628dB156f3F6c60dBE; // XRP
        assets[3] = 0x570A5D26f7765Ecb712C0924E4De545B89fD43dF; // SOL
        assets[4] = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; // WBNB
        
        uint256[] memory weights = new uint256[](5);
        weights[0] = 300000000000000000; // 30% BTCB
        weights[1] = 250000000000000000; // 25% ETH
        weights[2] = 200000000000000000; // 20% WBNB
        weights[3] = 150000000000000000; // 15% XRP
        weights[4] = 100000000000000000; // 10% SOL
        
        // 设置支持的资产和目标权重
        for (uint i = 0; i < assets.length; i++) {
            supportedAssets.push(assets[i]);
            isAssetSupported[assets[i]] = true;
            targetWeights[assets[i]] = weights[i];
        }
    }
    
    // ERC20 标准实现
    /**
     * @dev 返回代币的总供应量
     * @return uint256 总供应量
     */
    function totalSupply() public view override(IBlockETF, IERC20) returns (uint256) {
        return _totalSupply;
    }
    
    /**
     * @dev 返回指定账户的代币余额
     * @param account 账户地址
     * @return uint256 账户余额
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    
    /**
     * @dev 将代币从调用者账户转移到指定账户
     * @param to 目标账户地址
     * @param amount 转移数量
     * @return bool 转移是否成功
     */
    function transfer(address to, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }
    
    /**
     * @dev 返回指定所有者对指定支出者的授权额度
     * @param _owner 所有者地址
     * @param spender 支出者地址
     * @return uint256 授权额度
     */
    function allowance(address _owner, address spender) public view override returns (uint256) {
        return _allowances[_owner][spender];
    }
    
    /**
     * @dev 授权指定支出者可以代表调用者花费一定数量的代币
     * @param spender 支出者地址
     * @param amount 授权数量
     * @return bool 授权是否成功
     */
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    
    /**
     * @dev 通过授权额度将代币从一个账户转移到另一个账户
     * @param from 源账户地址
     * @param to 目标账户地址
     * @param amount 转移数量
     * @return bool 转移是否成功
     */
    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        uint256 currentAllowance = _allowances[from][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        
        _transfer(from, to, amount);
        _approve(from, msg.sender, currentAllowance - amount);
        
        return true;
    }
    
    /**
     * @dev 内部函数，执行代币转移操作
     * @param from 源账户地址
     * @param to 目标账户地址
     * @param amount 转移数量
     */
    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        
        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        
        _balances[from] = fromBalance - amount;
        _balances[to] += amount;
        
        emit Transfer(from, to, amount);
    }
    
    /**
     * @dev 内部函数，设置授权额度
     * @param _owner 所有者地址
     * @param spender 支出者地址
     * @param amount 授权数量
     */
    function _approve(address _owner, address spender, uint256 amount) internal {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        
        _allowances[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }
    
    // ETF 核心功能实现
    /**
     * @dev 铸造ETF份额，仅管理员可调用
     * @param to 接收份额的地址
     * @param amount 铸造份额的数量
     */
    function mint(address to, uint256 amount) external override onlyManager {
        require(to != address(0), "ERC20: mint to the zero address");
        
        _totalSupply += amount;
        _balances[to] += amount;
        
        emit Transfer(address(0), to, amount);
    }
    
    /**
     * @dev 销毁ETF份额，仅管理员可调用
     * @param from 被销毁份额的地址
     * @param amount 销毁份额的数量
     */
    function burn(address from, uint256 amount) external override onlyManager {
        require(from != address(0), "ERC20: burn from the zero address");
        
        uint256 accountBalance = _balances[from];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        
        _balances[from] = accountBalance - amount;
        _totalSupply -= amount;
        
        emit Transfer(from, address(0), amount);
    }
    
    /**
     * @dev 获取ETF持有的基础资产当前余额
     * @return assets 资产地址数组
     * @return balances 相应资产余额数组
     */
    function getAssetBalances() external view override returns (address[] memory assets, uint256[] memory balances) {
        assets = supportedAssets;
        balances = new uint256[](assets.length);
        
        for (uint i = 0; i < assets.length; i++) {
            balances[i] = assetBalances[assets[i]];
        }
    }
    
    /**
     * @dev 获取ETF中基础资产的目标权重
     * @return assets 资产地址数组
     * @return weights 相应的目标权重数组（以基点或类似单位表示）
     */
    function getTargetWeights() external view override returns (address[] memory assets, uint256[] memory weights) {
        assets = supportedAssets;
        weights = new uint256[](assets.length);
        
        for (uint i = 0; i < assets.length; i++) {
            weights[i] = targetWeights[assets[i]];
        }
    }
    
    /**
     * @dev 计算铸造给定数量份额所需的底层资产数量
     * @param shares 要铸造的份额数量
     * @return assets 资产地址数组
     * @return amounts 所需资产数量数组
     */
    function calculateRequiredAssets(uint256 shares) external view override returns (address[] memory assets, uint256[] memory amounts) {
        require(_totalSupply > 0, "No shares minted yet");
        
        assets = supportedAssets;
        amounts = new uint256[](assets.length);
        
        for (uint i = 0; i < assets.length; i++) {
            amounts[i] = (assetBalances[assets[i]] * shares) / _totalSupply;
        }
    }
    
    /**
     * @dev 将基础资产存入ETF以铸造份额，仅管理员可调用
     * @param assets 要存入的资产地址数组
     * @param amounts 每种资产要存入的数量数组
     */
    function depositAssets(address[] calldata assets, uint256[] calldata amounts) external override onlyManager {
        require(assets.length == amounts.length, "Arrays length mismatch");
        
        for (uint i = 0; i < assets.length; i++) {
            require(isAssetSupported[assets[i]], "Asset not supported");
            
            IERC20(assets[i]).transferFrom(msg.sender, address(this), amounts[i]);
            assetBalances[assets[i]] += amounts[i];
        }
    }
    
    /**
     * @dev 通过销毁份额从ETF中提取基础资产，仅管理员可调用
     * @param assets 要提取的资产地址数组
     * @param amounts 每种资产要提取的数量数组
     */
    function withdrawAssets(address[] calldata assets, uint256[] calldata amounts) external override onlyManager {
        require(assets.length == amounts.length, "Arrays length mismatch");
        
        for (uint i = 0; i < assets.length; i++) {
            require(isAssetSupported[assets[i]], "Asset not supported");
            require(assetBalances[assets[i]] >= amounts[i], "Insufficient asset balance");
            
            assetBalances[assets[i]] -= amounts[i];
            IERC20(assets[i]).transfer(msg.sender, amounts[i]);
        }
    }
    
    // 管理功能
    /**
     * @dev 设置管理员权限，仅所有者可调用
     * @param manager 管理员地址
     * @param active 是否激活管理员权限
     */
    function setManager(address manager, bool active) external onlyOwner {
        managers[manager] = active;
    }
    
    /**
     * @dev 更新资产目标权重，仅所有者可调用
     * @param assets 资产地址数组
     * @param weights 相应的目标权重数组
     */
    function updateTargetWeights(address[] calldata assets, uint256[] calldata weights) external onlyOwner {
        require(assets.length == weights.length, "Arrays length mismatch");
        
        uint256 totalWeight = 0;
        for (uint i = 0; i < weights.length; i++) {
            totalWeight += weights[i];
        }
        require(totalWeight == 1e18, "Total weight must be 100%");
        
        for (uint i = 0; i < assets.length; i++) {
            require(isAssetSupported[assets[i]], "Asset not supported");
            targetWeights[assets[i]] = weights[i];
        }
    }
    
    /**
     * @dev 添加新的支持资产，仅所有者可调用
     * @param asset 资产地址
     * @param weight 资产权重
     */
    function addSupportedAsset(address asset, uint256 weight) external onlyOwner {
        require(!isAssetSupported[asset], "Asset already supported");
        
        supportedAssets.push(asset);
        isAssetSupported[asset] = true;
        targetWeights[asset] = weight;
    }
}