// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interfaces/boofy/IVault.sol";

contract BoofyStrategyMulticall {

    function getStrategy(address[] calldata vaults) external view returns (address[] memory) {
        address[] memory strategies = new address[](vaults.length);

        for (uint i = 0; i < vaults.length; i++) {
            strategies[i] = address(IVault(vaults[i]).strategy());
        }

        return strategies;
    }
}