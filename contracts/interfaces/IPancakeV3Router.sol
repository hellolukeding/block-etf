// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title IPancakeV3Router
 * @dev PancakeSwap V3 路由器接口，专注于使用集中流动性的单路径代币交换。
 * 此接口提供了精确输入和精确输出的单次交换函数。
 */
interface IPancakeV3Router {
  /// @dev 精确输入单次交换的参数结构体。
  struct ExactInputSingleParams {
    address tokenIn; // 输入代币的地址。
    address tokenOut; // 输出代币的地址。
    uint24 fee; // 交换池的费用等级。
    address recipient; // 接收输出代币的地址。
    uint256 deadline; // 交易的截止时间。
    uint256 amountIn; // 输入代币的数量。
    uint256 amountOutMinimum; // 输出代币的最小数量。
    uint160 sqrtPriceLimitX96; // 交换的价格限制。
  }

  /// @dev 精确输出单次交换的参数结构体。
  struct ExactOutputSingleParams {
    address tokenIn; // 输入代币的地址。
    address tokenOut; // 输出代币的地址。
    uint24 fee; // 交换池的费用等级。
    address recipient; // 接收输出代币的地址。
    uint256 deadline; // 交易的截止时间。
    uint256 amountOut; // 期望的输出代币数量。
    uint256 amountInMaximum; // 输入代币的最大数量。
    uint160 sqrtPriceLimitX96; // 交换的价格限制。
  }

  /// @notice 执行具有精确输入数量的单路径交换。
  /// @param params 包含交换参数的结构体。
  /// @return amountOut 接收到的输出代币数量。
  function exactInputSingle(
    ExactInputSingleParams calldata params
  ) external payable returns (uint256 amountOut);

  /// @notice 执行具有精确输出数量的单路径交换。
  /// @param params 包含交换参数的结构体。
  /// @return amountIn 使用的输入代币数量。
  function exactOutputSingle(
    ExactOutputSingleParams calldata params
  ) external payable returns (uint256 amountIn);
}