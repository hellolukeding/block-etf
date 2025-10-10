// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title IBlockETF
 * @dev BlockETF 合约接口，代表一个区块链 ETF 代币，持有一篮子基础资产。
 * 此接口定义了 ETF 份额的铸造/销毁、资产管理与权重、以及基础资产存入/提取的函数。
 */
interface IBlockETF {
  /// @notice 为指定地址铸造 ETF 份额。
  /// @param to 接收铸造份额的地址。
  /// @param amount 要铸造的份额数量。
  function mint(address to, uint256 amount) external;

  /// @notice 从指定地址销毁 ETF 份额。
  /// @param from 被销毁份额的地址。
  /// @param amount 要销毁的份额数量。
  function burn(address from, uint256 amount) external;

  /// @notice 获取 ETF 持有的基础资产当前余额。
  /// @return assets 资产地址数组。
  /// @return balances 相应资产余额数组。
  function getAssetBalances()
    external
    view
    returns (address[] memory assets, uint256[] memory balances);

  /// @notice 获取 ETF 中基础资产的目标权重。
  /// @return assets 资产地址数组。
  /// @return weights 相应的目标权重数组（以基点或类似单位表示）。
  function getTargetWeights()
    external
    view
    returns (address[] memory assets, uint256[] memory weights);

  /// @notice 返回 ETF 份额的总供应量。
  /// @return 流通中的 ETF 份额总数。
  function totalSupply() external view returns (uint256);

  /// @notice 计算铸造给定数量份额所需的底层资产数量。
  /// @param shares 要铸造的份额数量。
  /// @return assets 资产地址数组。
  /// @return amounts 所需资产数量数组。
  function calculateRequiredAssets(
    uint256 shares
  ) external view returns (address[] memory assets, uint256[] memory amounts);

  /// @notice 将基础资产存入 ETF 以铸造份额。
  /// @param assets 要存入的资产地址数组。
  /// @param amounts 每种资产要存入的数量数组。
  function depositAssets(
    address[] calldata assets,
    uint256[] calldata amounts
  ) external;

  /// @notice 通过销毁份额从 ETF 中提取基础资产。
  /// @param assets 要提取的资产地址数组。
  /// @param amounts 每种资产要提取的数量数组。
  function withdrawAssets(
    address[] calldata assets,
    uint256[] calldata amounts
  ) external;
}