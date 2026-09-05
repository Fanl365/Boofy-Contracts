const hardhat = require("hardhat");
const { upgrades } = require("hardhat");
import { addressBook } from "@beefyfinance/blockchain-addressbook";

const { getVerifyCommand } = require("../utils");

/**
 * Script used to deploy the basic infrastructure needed to run Boofy.
 */

const ethers = hardhat.ethers;

const chainName = "unichain";
const {
  platforms: {
    boofyfinance: { keeper, voter, boofyFeeRecipient },
  },
} = addressBook.arbitrum;

const TIMELOCK_ADMIN_ROLE = "0x5f58e3a2316349923ce3780f8d587db2d72378aed66a8261c916544fa6846ca5";
const STRAT_OWNER_DELAY = 21600;
const VAULT_OWNER_DELAY = 0;
const KEEPER = keeper;

const config = {
  devMultisig: "0xc2cCdd61187b81cC56EcA985bbaf9da418e3d87f",
  treasuryMultisig: "0x2E52C94502f728A634a7b8eFf5941FB066d3eE76",
  totalLimit: "95000000000000000",
  callFee: "500000000000000",
  strategist: "5000000000000000",
};

const proposer = config.devMultisig || TRUSTED_EOA;
const timelockProposers = [proposer];
const timelockExecutors = [proposer, KEEPER];

async function main() {
  await hardhat.run("compile");

  const deployer = await ethers.getSigner();

  const TimelockController = await ethers.getContractFactory("TimelockController");

  console.log("Deploying vault owner.");
  let deployParams = [VAULT_OWNER_DELAY, timelockProposers, timelockExecutors];
  const vaultOwner = await TimelockController.deploy(...deployParams);
  await vaultOwner.deployed();
  await vaultOwner.renounceRole(TIMELOCK_ADMIN_ROLE, deployer.address);
  console.log(`Vault owner deployed to ${vaultOwner.address}`);
  console.log(getVerifyCommand(chainName, "TimelockController", vaultOwner.address, deployParams));

  console.log("Deploying strategy owner.");
  const stratOwner = await TimelockController.deploy(STRAT_OWNER_DELAY, timelockProposers, timelockExecutors);
  await stratOwner.deployed();
  await stratOwner.renounceRole(TIMELOCK_ADMIN_ROLE, deployer.address);
  console.log(`Strategy owner deployed to ${stratOwner.address}`);
  console.log(getVerifyCommand(chainName, "TimelockController", stratOwner.address, deployParams));

  console.log("Deploying multicall");
  const Multicall = await ethers.getContractFactory("Multicall");
  const multicall = await Multicall.deploy();
  await multicall.deployed();
  console.log(`Multicall deployed to ${multicall.address}`);
  console.log(getVerifyCommand(chainName, "Multicall", multicall.address));

  const BoofyFeeConfiguratorFactory = await ethers.getContractFactory("BoofyFeeConfigurator");
  console.log("Deploying BoofyFeeConfigurator");

  const constructorArguments = [keeper, config.totalLimit];
  const transparentUpgradableProxy = await upgrades.deployProxy(BoofyFeeConfiguratorFactory, constructorArguments);
  await transparentUpgradableProxy.deployed();
  console.log(`BoofyFeeConfigurator deployed to ${transparentUpgradableProxy.address}`);
  console.log(
    getVerifyCommand(chainName, "BoofyFeeConfigurator", transparentUpgradableProxy.address, constructorArguments)
  );

  await transparentUpgradableProxy.setFeeCategory(
    0,
    BigInt(config.totalLimit),
    BigInt(config.callFee),
    BigInt(config.strategist),
    "default",
    true,
    true
  );
  await transparentUpgradableProxy.transferOwnership(config.devMultisig);

  const implementationAddress = await upgrades.erc1967.getImplementationAddress(transparentUpgradableProxy.address);

  console.log();
  console.log("BoofyFeeConfig:", transparentUpgradableProxy.address);
  console.log(`Implementation address:`, implementationAddress);

  console.log("Deploying Vault Factory");
  const VaultFactory = await ethers.getContractFactory("BoofyVaultV7Factory");
  const VaultV7 = await ethers.getContractFactory("BoofyVaultV7");
  const vault7 = await VaultV7.deploy();
  await vault7.deployed();
  console.log(`Vault V7 deployed to ${vault7.address}`);
  console.log(getVerifyCommand(chainName, "BoofyVaultV7", vault7.address));

  const vaultFactory = await VaultFactory.deploy(vault7.address);
  await vaultFactory.deployed();
  console.log(`Vault Factory deployed to ${vaultFactory.address}`);
  console.log(getVerifyCommand(chainName, "BoofyVaultV7Factory", vaultFactory.address));

  console.log("Deploying Boofy Swapper");
  const BoofySwapper = await ethers.getContractFactory("BoofySwapper");
  const boofySwapper = await BoofySwapper.deploy();
  await boofySwapper.deployed();
  console.log(`Boofy Swapper deployed to ${boofySwapper.address}`);
  console.log(getVerifyCommand(chainName, "BoofySwapper", boofySwapper.address));
  console.log("Deploying Boofy Oracle");
  const BoofyOracle = await ethers.getContractFactory("BoofyOracle");
  const boofyOracle = await BoofyOracle.deploy();
  await boofyOracle.deployed();

  boofySwapper.initialize(boofyOracle.address, config.totalLimit);
  boofySwapper.transferOwnership(keeper);

  boofyOracle.initialize();
  boofyOracle.transferOwnership(keeper);
  console.log(`Boofy Oracle deployed to ${boofyOracle.address}`);
  console.log(getVerifyCommand(chainName, "BoofyOracle", boofyOracle.address));

  console.log(`
    const devMultisig = '${config.devMultisig}';
    const treasuryMultisig = '${config.treasuryMultisig}';
  
    export const boofyfinance = {
      devMultisig,
      treasuryMultisig,
      strategyOwner: '${stratOwner.address}',
      vaultOwner: '${vaultOwner.address}',
      keeper: '0x4fED5491693007f0CD49f4614FFC38Ab6A04B619',
      treasurer: treasuryMultisig,
      launchpoolOwner: devMultisig,
      rewardPool: '${ethers.constants.AddressZero}',
      treasury: '${ethers.constants.AddressZero}',
      boofyFeeRecipient: '0x02Ae4716B9D5d48Db1445814b0eDE39f5c28264B',
      multicall: '${multicall.address}',
      bifiMaxiStrategy: '${ethers.constants.AddressZero}',
      voter: '0x5e1caC103F943Cd84A1E92dAde4145664ebf692A',
      boofyFeeConfig: '${transparentUpgradableProxy.address}',
      vaultFactory: '${vaultFactory.address}',
      wrapperFactory: '${ethers.constants.AddressZero}',
      zap: '${ethers.constants.AddressZero}',
      zapTokenManager: '${ethers.constants.AddressZero}',
      treasurySwapper: '${ethers.constants.AddressZero}',
    
      /// CLM Contracts
      clmFactory: '${ethers.constants.AddressZero}',
      clmStrategyFactory: '${ethers.constants.AddressZero}',
      clmRewardPoolFactory: '${ethers.constants.AddressZero}',
      positionMulticall: '${ethers.constants.AddressZero}',
    
      /// Boofy Swapper Contracts
      boofySwapper: '${boofySwapper.address}',
      boofyOracle: '${boofyOracle.address}',
      boofyOracleChainlink: '${ethers.constants.AddressZero}',
      boofyOracleUniswapV2: '${ethers.constants.AddressZero}',
      boofyOracleUniswapV3: '${ethers.constants.AddressZero}',
    } as const;
  `);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
