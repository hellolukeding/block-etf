// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./interfaces/IERC20.sol";
import "./interfaces/IBlockETF.sol";

contract BlockETF is IBlockETF, IERC20 {
    string public name = "Block ETF Token";
    string public symbol = "bETF";
    uint8 public decimals = 18;
    
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    
    // 资产管理
    address[] public supportedAssets;
    mapping(address => bool) public isAssetSupported;
    mapping(address => uint256) public assetBalances;
    mapping(address => uint256) public targetWeights; // 以1e18为基数，即100% = 1e18
    
    // 权限控制
    mapping(address => bool) public managers;
    address public owner;
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    
    modifier onlyManager() {
        require(managers[msg.sender], "Not authorized manager");
        _;
    }
    
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
        
        for (uint i = 0; i < assets.length; i++) {
            supportedAssets.push(assets[i]);
            isAssetSupported[assets[i]] = true;
            targetWeights[assets[i]] = weights[i];
        }
    }
    
    // ERC20 实现
    function totalSupply() public view override(IBlockETF, IERC20) returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    
    function transfer(address to, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }
    
    function allowance(address _owner, address spender) public view override returns (uint256) {
        return _allowances[_owner][spender];
    }
    
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        uint256 currentAllowance = _allowances[from][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        
        _transfer(from, to, amount);
        _approve(from, msg.sender, currentAllowance - amount);
        
        return true;
    }
    
    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        
        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        
        _balances[from] = fromBalance - amount;
        _balances[to] += amount;
        
        emit Transfer(from, to, amount);
    }
    
    function _approve(address _owner, address spender, uint256 amount) internal {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        
        _allowances[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }
    
    // ETF 核心功能
    function mint(address to, uint256 amount) external override onlyManager {
        require(to != address(0), "ERC20: mint to the zero address");
        
        _totalSupply += amount;
        _balances[to] += amount;
        
        emit Transfer(address(0), to, amount);
    }
    
    function burn(address from, uint256 amount) external override onlyManager {
        require(from != address(0), "ERC20: burn from the zero address");
        
        uint256 accountBalance = _balances[from];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        
        _balances[from] = accountBalance - amount;
        _totalSupply -= amount;
        
        emit Transfer(from, address(0), amount);
    }
    
    function getAssetBalances() external view override returns (address[] memory assets, uint256[] memory balances) {
        assets = supportedAssets;
        balances = new uint256[](assets.length);
        
        for (uint i = 0; i < assets.length; i++) {
            balances[i] = assetBalances[assets[i]];
        }
    }
    
    function getTargetWeights() external view override returns (address[] memory assets, uint256[] memory weights) {
        assets = supportedAssets;
        weights = new uint256[](assets.length);
        
        for (uint i = 0; i < assets.length; i++) {
            weights[i] = targetWeights[assets[i]];
        }
    }
    
    function calculateRequiredAssets(uint256 shares) external view override returns (address[] memory assets, uint256[] memory amounts) {
        require(_totalSupply > 0, "No shares minted yet");
        
        assets = supportedAssets;
        amounts = new uint256[](assets.length);
        
        for (uint i = 0; i < assets.length; i++) {
            amounts[i] = (assetBalances[assets[i]] * shares) / _totalSupply;
        }
    }
    
    function depositAssets(address[] calldata assets, uint256[] calldata amounts) external override onlyManager {
        require(assets.length == amounts.length, "Arrays length mismatch");
        
        for (uint i = 0; i < assets.length; i++) {
            require(isAssetSupported[assets[i]], "Asset not supported");
            
            IERC20(assets[i]).transferFrom(msg.sender, address(this), amounts[i]);
            assetBalances[assets[i]] += amounts[i];
        }
    }
    
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
    function setManager(address manager, bool active) external onlyOwner {
        managers[manager] = active;
    }
    
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
    
    function addSupportedAsset(address asset, uint256 weight) external onlyOwner {
        require(!isAssetSupported[asset], "Asset already supported");
        
        supportedAssets.push(asset);
        isAssetSupported[asset] = true;
        targetWeights[asset] = weight;
    }
}
