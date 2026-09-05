// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin-4/contracts/token/ERC20/utils/SafeERC20.sol";

import "../../interfaces/curve/IConic.sol";
import "../../zaps/zapInterfaces/IBoofyVault.sol";
import "../../zaps/zapInterfaces/IWETH.sol";

interface IBoofyStrategy {
    function withdrawFee() external view returns (uint256);
    function WITHDRAWAL_MAX() external view returns (uint256);
}

contract ConicZap {
    using SafeERC20 for IERC20;
    using SafeERC20 for IBoofyVault;

    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant CNC = 0x9aE380F0272E2162340a5bB646c354271c0F5cFC;
    uint256 public constant minimumAmount = 1000;

    receive() external payable {
        assert(msg.sender == WETH);
    }

    function estimateSwap(IBoofyVault boofyVault, address tokenIn, uint256 fullInvestmentIn) public view returns (uint256 swapAmountIn, uint256 swapAmountOut, address swapTokenOut) {
        (address lpToken, IConicPool conicPool) = _getVaultPool(boofyVault);

        require(conicPool.underlying() == tokenIn, 'Boofy: Input token not present in pool');

        swapTokenOut = lpToken;
        swapAmountIn = fullInvestmentIn;
        swapAmountOut = fullInvestmentIn * 1e18 / conicPool.exchangeRate();
    }

    function beefInETH(IBoofyVault boofyVault, uint256 tokenAmountOutMin) external payable {
        require(msg.value >= minimumAmount, 'Boofy: Insignificant input amount');

        IWETH(WETH).deposit{value: msg.value}();

        _depositAndStake(boofyVault, tokenAmountOutMin, WETH);
    }

    function beefIn (IBoofyVault boofyVault, uint256 tokenAmountOutMin, address tokenIn, uint256 tokenInAmount) external {
        require(tokenInAmount >= minimumAmount, 'Boofy: Insignificant input amount');
        require(IERC20(tokenIn).allowance(msg.sender, address(this)) >= tokenInAmount, 'Boofy: Input token is not approved');

        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), tokenInAmount);

        _depositAndStake(boofyVault, tokenAmountOutMin, tokenIn);
    }

    function _depositAndStake(IBoofyVault boofyVault, uint256 tokenAmountOutMin, address tokenIn) private {
        (address lpToken, IConicPool conicPool) = _getVaultPool(boofyVault);

        require(conicPool.underlying() == tokenIn, 'Boofy: Input token not present in pool');

        uint256 fullInvestment = _balanceOfThis(tokenIn);
        _approveTokenIfNeeded(tokenIn, address(conicPool));
        conicPool.deposit(fullInvestment, tokenAmountOutMin, false);

        _approveTokenIfNeeded(lpToken, address(boofyVault));
        boofyVault.deposit(_balanceOfThis(lpToken));

        boofyVault.safeTransfer(msg.sender, _balanceOfThis(address(boofyVault)));
        _returnAssets(tokenIn);
    }

    function estimateSwapOut(IBoofyVault boofyVault, address desiredToken, uint256 withdrawAmount) public view returns (uint256 swapAmountIn, uint256 swapAmountOut, address swapTokenIn) {
        (address lpToken, IConicPool conicPool) = _getVaultPool(boofyVault);

        require(conicPool.underlying() == desiredToken, 'Boofy: desired token not present in pool');

        IBoofyStrategy strategy = IBoofyStrategy(boofyVault.strategy());
        uint withdrawWantAmount = withdrawAmount * boofyVault.balance() / boofyVault.totalSupply();
        uint withdrawalFeeAmount = withdrawWantAmount * strategy.withdrawFee() / strategy.WITHDRAWAL_MAX();
        withdrawWantAmount = withdrawWantAmount - withdrawalFeeAmount;

        swapAmountIn = withdrawWantAmount;
        swapTokenIn = lpToken;
        swapAmountOut = swapAmountIn * conicPool.exchangeRate() / 1e18;
    }

    function beefOutAndSwap(IBoofyVault boofyVault, uint256 withdrawAmount, address desiredToken, uint256 desiredTokenOutMin) external {
        (address lpToken, IConicPool conicPool) = _getVaultPool(boofyVault);

        require(conicPool.underlying() == desiredToken, 'Boofy: desired token not present in pool');

        boofyVault.safeTransferFrom(msg.sender, address(this), withdrawAmount);
        boofyVault.withdraw(withdrawAmount);
        conicPool.withdraw(_balanceOfThis(lpToken), desiredTokenOutMin);

        _returnAssets(desiredToken);
    }

    function _getVaultPool(IBoofyVault boofyVault) private view returns (address lpToken, IConicPool conicPool) {
        lpToken = boofyVault.want();
        conicPool = IConicPool(ILpToken(lpToken).minter());
    }

    function _returnAssets(address underlying) private {
        uint256 balance = _balanceOfThis(underlying);
        if (balance > 0) {
            if (underlying == WETH) {
                IWETH(WETH).withdraw(balance);
                (bool success,) = msg.sender.call{value: balance}(new bytes(0));
                require(success, 'Boofy: ETH transfer failed');
            } else {
                IERC20(underlying).safeTransfer(msg.sender, balance);
            }
        }

        // CNC rebalancing reward
        balance = _balanceOfThis(CNC);
        if (balance > 0) {
            IERC20(CNC).safeTransfer(msg.sender, balance);
        }
    }

    function _approveTokenIfNeeded(address token, address spender) private {
        if (IERC20(token).allowance(address(this), spender) == 0) {
            IERC20(token).safeApprove(spender, type(uint256).max);
        }
    }

    function _balanceOfThis(address _token) private view returns (uint) {
        return IERC20(_token).balanceOf(address(this));
    }

}