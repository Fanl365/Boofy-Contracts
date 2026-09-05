// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { BoofyOracleHelper, BoofyOracleErrors } from "./BoofyOracleHelper.sol";

/// @title Boofy Oracle Override
/// @author Beefy
/// @notice On-chain oracle override for use with hard to get on chain price feeds
library BoofyOracleOverride {

    /// @notice Return 0
    /// @return price Retrieved price from the Chainlink feed
    /// @return success Successful price fetch or not
    function getPrice(bytes calldata) external pure returns (uint256 price, bool success) {
        return (BoofyOracleHelper.scaleAmount(uint256(1e4), uint8(8)), true);
    }

    /// @notice Data validation 
    function validateData(bytes calldata) external view {}
}
