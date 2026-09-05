const hardhat = require("hardhat");

const ethers = hardhat.ethers;

async function main() {
  await hardhat.run("compile");

  const BoofyVaultV7ProxyFactory = await ethers.getContractFactory("BoofyVaultV7ProxyFactory");

  console.log("Deploying: BoofyVaultV7ProxyFactory");

  const boofyVaultV7ProxyFactory = await BoofyVaultV7ProxyFactory.deploy();
  await boofyVaultV7ProxyFactory.deployed();

  console.log("BoofyVaultV7ProxyFactory", boofyVaultV7ProxyFactory.address);

  await hardhat.run("verify:verify", {
    address: boofyVaultV7ProxyFactory.address,
    constructorArguments: [],
  })
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });