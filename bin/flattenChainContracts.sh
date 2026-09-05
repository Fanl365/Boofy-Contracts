#!/bin/bash

rm tmp/*.sol

echo "// SPDX-License-Identifier: MIT" > tmp/TimelockController.sol
truffle-flattener node_modules/@openzeppelin-4/contracts/governance/TimelockController.sol | sed '/SPDX-License-Identifier/d' >> tmp/TimelockController.sol

echo "// SPDX-License-Identifier: MIT" > tmp/BoofyTreasury.sol
hardhat flatten contracts/BIFI/infra/BoofyTreasury.sol | sed '/SPDX-License-Identifier/d' >> tmp/BoofyTreasury.sol

echo "// SPDX-License-Identifier: MIT" > tmp/Multicall.sol
hardhat flatten contracts/BIFI/utils/Multicall.sol | sed '/SPDX-License-Identifier/d' >> tmp/Multicall.sol

echo "// SPDX-License-Identifier: MIT" > tmp/BoofyRewardPool.sol
hardhat flatten contracts/BIFI/infra/BoofyRewardPool.sol | sed '/SPDX-License-Identifier/d' >> tmp/BoofyRewardPool.sol

echo "// SPDX-License-Identifier: MIT" > tmp/BoofyFeeBatchV2.sol
hardhat flatten contracts/BIFI/infra/BoofyFeeBatchV2.sol | sed '/SPDX-License-Identifier/d' >> tmp/BoofyFeeBatchV2.sol


