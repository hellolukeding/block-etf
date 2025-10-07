// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IBlockETF {
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
    function getAssetBalances() external view returns (address[] memory assets, uint256[] memory balances);
    function getTargetWeights() external view returns (address[] memory assets, uint256[] memory weights);
    function totalSupply() external view returns (uint256);
    function calculateRequiredAssets(uint256 shares) external view returns (address[] memory assets, uint256[] memory amounts);
    function depositAssets(address[] calldata assets, uint256[] calldata amounts) external;
    function withdrawAssets(address[] calldata assets, uint256[] calldata amounts) external;
}
