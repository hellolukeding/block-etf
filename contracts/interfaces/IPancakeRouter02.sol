// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title IPancakeRouter02
 * @dev PancakeSwap V2 路由器接口，用于在 PancakeSwap DEX 上进行代币交换和流动性管理。
 * 此接口包括添加/移除流动性和执行各种代币交换的函数。
 */
interface IPancakeRouter02 {
  /// @notice 返回 PancakeSwap 工厂合约的地址。
  /// @return 工厂合约地址。
  function factory() external pure returns (address);

  /// @notice 返回 WETH (Wrapped Ethereum) 合约的地址。
  /// @return WETH 合约地址。
  function WETH() external pure returns (address);

  /// @notice 为代币对添加流动性。
  /// @param tokenA 第一个代币的地址。
  /// @param tokenB 第二个代币的地址。
  /// @param amountADesired 要添加的 tokenA 的期望数量。
  /// @param amountBDesired 要添加的 tokenB 的期望数量。
  /// @param amountAMin 要添加的 tokenA 的最小数量。
  /// @param amountBMin 要添加的 tokenB 的最小数量。
  /// @param to 接收流动性代币的地址。
  /// @param deadline 交易的截止时间。
  /// @return amountA 实际添加的 tokenA 数量。
  /// @return amountB 实际添加的 tokenB 数量。
  /// @return liquidity 铸造的流动性代币数量。
  function addLiquidity(
    address tokenA,
    address tokenB,
    uint amountADesired,
    uint amountBDesired,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
  ) external returns (uint amountA, uint amountB, uint liquidity);

  /// @notice 使用 ETH 添加流动性。
  /// @param token 与 ETH 配对的代币地址。
  /// @param amountTokenDesired 要添加的代币的期望数量。
  /// @param amountTokenMin 要添加的代币的最小数量。
  /// @param amountETHMin 要添加的 ETH 的最小数量。
  /// @param to 接收流动性代币的地址。
  /// @param deadline 交易的截止时间。
  /// @return amountToken 实际添加的代币数量。
  /// @return amountETH 实际添加的 ETH 数量。
  /// @return liquidity 铸造的流动性代币数量。
  function addLiquidityETH(
    address token,
    uint amountTokenDesired,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline
  ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

  /// @notice 从代币对中移除流动性。
  /// @param tokenA 第一个代币的地址。
  /// @param tokenB 第二个代币的地址。
  /// @param liquidity 要销毁的流动性代币数量。
  /// @param amountAMin 要接收的 tokenA 的最小数量。
  /// @param amountBMin 要接收的 tokenB 的最小数量。
  /// @param to 接收代币的地址。
  /// @param deadline 交易的截止时间。
  /// @return amountA 接收到的 tokenA 数量。
  /// @return amountB 接收到的 tokenB 数量。
  function removeLiquidity(
    address tokenA,
    address tokenB,
    uint liquidity,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
  ) external returns (uint amountA, uint amountB);

  /// @notice 移除流动性并接收 ETH。
  /// @param token 与 ETH 配对的代币地址。
  /// @param liquidity 要销毁的流动性代币数量。
  /// @param amountTokenMin 要接收的代币的最小数量。
  /// @param amountETHMin 要接收的 ETH 的最小数量。
  /// @param to 接收代币和 ETH 的地址。
  /// @param deadline 交易的截止时间。
  /// @return amountToken 接收到的代币数量。
  /// @return amountETH 接收到的 ETH 数量。
  function removeLiquidityETH(
    address token,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline
  ) external returns (uint amountToken, uint amountETH);

  /// @notice 沿路径将确切数量的代币交换为代币。
  /// @param amountIn 输入代币的数量。
  /// @param amountOutMin 输出代币的最小数量。
  /// @param path 交换路径的代币地址数组。
  /// @param to 接收输出代币的地址。
  /// @param deadline 交易的截止时间。
  /// @return amounts 路径中每一步的金额数组。
  function swapExactTokensForTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);

  /// @notice 沿路径将代币交换为确切数量的代币。
  /// @param amountOut 期望的输出代币数量。
  /// @param amountInMax 输入代币的最大数量。
  /// @param path 交换路径的代币地址数组。
  /// @param to 接收输出代币的地址。
  /// @param deadline 交易的截止时间。
  /// @return amounts 路径中每一步的金额数组。
  function swapTokensForExactTokens(
    uint amountOut,
    uint amountInMax,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);

  /// @notice 沿路径将确切数量的 ETH 交换为代币。
  /// @param amountOutMin 输出代币的最小数量。
  /// @param path 交换路径的代币地址数组。
  /// @param to 接收输出代币的地址。
  /// @param deadline 交易的截止时间。
  /// @return amounts 路径中每一步的金额数组。
  function swapExactETHForTokens(
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external payable returns (uint[] memory amounts);

  /// @notice 沿路径将代币交换为确切数量的 ETH。
  /// @param amountOut 期望的 ETH 数量。
  /// @param amountInMax 输入代币的最大数量。
  /// @param path 交换路径的代币地址数组。
  /// @param to 接收 ETH 的地址。
  /// @param deadline 交易的截止时间。
  /// @return amounts 路径中每一步的金额数组。
  function swapTokensForExactETH(
    uint amountOut,
    uint amountInMax,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);

  /// @notice 沿路径将确切数量的代币交换为 ETH。
  /// @param amountIn 输入代币的数量。
  /// @param amountOutMin ETH 的最小数量。
  /// @param path 交换路径的代币地址数组。
  /// @param to 接收 ETH 的地址。
  /// @param deadline 交易的截止时间。
  /// @return amounts 路径中每一步的金额数组。
  function swapExactTokensForETH(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);

  /// @notice 沿路径将 ETH 交换为确切数量的代币。
  /// @param amountOut 期望的输出代币数量。
  /// @param path 交换路径的代币地址数组。
  /// @param to 接收输出代币的地址。
  /// @param deadline 交易的截止时间。
  /// @return amounts 路径中每一步的金额数组。
  function swapETHForExactTokens(
    uint amountOut,
    address[] calldata path,
    address to,
    uint deadline
  ) external payable returns (uint[] memory amounts);

  /// @notice 根据储备量报价给定数量的 tokenA 对应的 tokenB 数量。
  /// @param amountA tokenA 的数量。
  /// @param reserveA tokenA 的储备量。
  /// @param reserveB tokenB 的储备量。
  /// @return amountB 报价的 tokenB 数量。
  function quote(
    uint amountA,
    uint reserveA,
    uint reserveB
  ) external pure returns (uint amountB);

  /// @notice 根据储备量计算给定输入数量的输出数量。
  /// @param amountIn 输入数量。
  /// @param reserveIn 输入代币的储备量。
  /// @param reserveOut 输出代币的储备量。
  /// @return amountOut 输出数量。
  function getAmountOut(
    uint amountIn,
    uint reserveIn,
    uint reserveOut
  ) external pure returns (uint amountOut);

  /// @notice 根据储备量计算给定输出数量所需的输入数量。
  /// @param amountOut 输出数量。
  /// @param reserveIn 输入代币的储备量。
  /// @param reserveOut 输出代币的储备量。
  /// @return amountIn 所需的输入数量。
  function getAmountIn(
    uint amountOut,
    uint reserveIn,
    uint reserveOut
  ) external pure returns (uint amountIn);

  /// @notice 计算沿路径交换的输出数量。
  /// @param amountIn 输入数量。
  /// @param path 交换路径的代币地址数组。
  /// @return amounts 每一步的输出数量数组。
  function getAmountsOut(
    uint amountIn,
    address[] calldata path
  ) external view returns (uint[] memory amounts);

  /// @notice 计算沿路径交换所需的输入数量。
  /// @param amountOut 输出数量。
  /// @param path 交换路径的代币地址数组。
  /// @return amounts 每一步的输入数量数组。
  function getAmountsIn(
    uint amountOut,
    address[] calldata path
  ) external view returns (uint[] memory amounts);
}