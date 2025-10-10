// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title IERC20
 * @dev ERC20 标准接口，定义了以太坊上同质化代币的基本功能。
 * 包括查询余额、转移代币和管理授权额度的函数。
 */
interface IERC20 {
  /// @notice 返回代币的总供应量。
  /// @return 流通中的代币总数。
  function totalSupply() external view returns (uint256);

  /// @notice 返回给定账户的代币余额。
  /// @param account 要查询余额的地址。
  /// @return 账户拥有的代币数量。
  function balanceOf(address account) external view returns (uint256);

  /// @notice 将代币从调用者地址转移到指定地址。
  /// @param to 要转移代币到的地址。
  /// @param amount 要转移的代币数量。
  /// @return 如果转移成功则返回 true。
  function transfer(address to, uint256 amount) external returns (bool);

  /// @notice 返回支出者对所有者代币的剩余授权额度。
  /// @param owner 拥有代币的地址。
  /// @param spender 被允许花费代币的地址。
  /// @return 剩余的授权额度。
  function allowance(
    address owner,
    address spender
  ) external view returns (uint256);

  /// @notice 批准支出者代表调用者花费一定数量的代币。
  /// @param spender 将被允许花费代币的地址。
  /// @param amount 要批准的代币数量。
  /// @return 如果批准成功则返回 true。
  function approve(address spender, uint256 amount) external returns (bool);

  /// @notice 使用授权额度将代币从一个地址转移到另一个地址。
  /// @param from 要转移代币的地址。
  /// @param to 要转移代币到的地址。
  /// @param amount 要转移的代币数量。
  /// @return 如果转移成功则返回 true。
  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) external returns (bool);

  /// @dev 当代币从一个地址转移到另一个地址时触发。
  event Transfer(address indexed from, address indexed to, uint256 value);

  /// @dev 当为支出者设置批准额度时触发。
  event Approval(address indexed owner, address indexed spender, uint256 value);
}