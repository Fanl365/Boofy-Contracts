// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./BoofyVaultV7.sol";
import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";

// Boofy Finance Vault V7 Proxy Factory
// Minimal proxy pattern for creating new Boofy vaults
contract BoofyVaultV7Factory {
  using ClonesUpgradeable for address;

  // Contract template for deploying proxied Boofy vaults
  BoofyVaultV7 public instance;

  event ProxyCreated(address proxy);

  // Initializes the Factory with an instance of the Boofy Vault V7
  constructor(address _instance) {
    if (_instance == address(0)) {
      instance = new BoofyVaultV7();
    } else {
      instance = BoofyVaultV7(_instance);
    }
  }

  // Creates a new Boofy Vault V7 as a proxy of the template instance
  // A reference to the new proxied Boofy Vault V7
  function cloneVault() external returns (BoofyVaultV7) {
    return BoofyVaultV7(cloneContract(address(instance)));
  }

  // Deploys and returns the address of a clone that mimics the behaviour of `implementation`
  function cloneContract(address implementation) public returns (address) {
    address proxy = implementation.clone();
    emit ProxyCreated(proxy);
    return proxy;
  }
}