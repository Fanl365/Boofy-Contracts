// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../infra/BoofyOracle/BoofyOracleHelper.sol";

interface ICurvePool {
    function price_oracle() external view returns (uint);
}

contract CurveOracle {
    ICurvePool public pool;
    address public token;
    address public baseToken;
    address public boofyOracle;

    constructor(address _pool, address _token, address _baseToken, address _boofyOracle) {
        pool = ICurvePool(_pool);
        token = _token;
        baseToken = _baseToken;
        boofyOracle = _boofyOracle;
    }

    function getPrice(bytes memory) public returns (uint256 price, bool success) {
        uint priceInBase = pool.price_oracle();
        price = BoofyOracleHelper.priceFromBaseToken(boofyOracle, token, baseToken, priceInBase);
        return (price, true);
    }

    function validateData(bytes calldata data) external view {}
}