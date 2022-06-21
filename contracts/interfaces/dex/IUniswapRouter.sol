// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import './IUniswapV3SwapCallback.sol';
import './ISwapRouter.sol';

interface IUniswapRouter is IUniswapV3SwapCallback, ISwapRouter {
    function refundETH() external payable;
}