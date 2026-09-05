<p align="center"><img src="./assets/boofy-banner.jpg" width="100%" alt="Boofy — Build · Connect · Grow" /></p>

# Boofy Contracts

Boofy Contracts contains the smart contracts, vault implementations, strategy integrations, deployment helpers, and test infrastructure for the Boofy DeFi project.

> **Development status:** active migration and hardening. No historical upstream address, transaction hash, token symbol, treasury, multisig, or deployment identifier should be treated as a verified Boofy production value unless explicitly confirmed by the Boofy team.

## Project goals

- Maintain reusable vault and strategy architecture.
- Support secure multichain integrations.
- Improve automated testing and deployment reproducibility.
- Keep production deployment data clearly separated from upstream history.

## Development

Typical commands include:

```bash
yarn
yarn compile
yarn test
```

Foundry-based tests and deployment scripts are also included in the repository.

## Current work

The active engineering tracks are:

1. Boofy contract namespace and documentation cleanup.
2. Validation of imports, dependencies, and deployment scripts.
3. Test coverage for vaults, wrappers, oracles, and strategies.
4. Separation of verified Boofy deployment data from historical upstream data.
5. Release and audit readiness.

See [ROADMAP.md](ROADMAP.md) and repository Issues for current work.

## Security boundary

Rebranding source code does not create a new on-chain deployment. Before production use, independently verify contract addresses, ownership, fee recipients, treasury/governance roles, multisigs, RPC configuration, and deployment parameters.

## Repository history

Boofy Contracts preserves the upstream development history used as its technical foundation. Historical commits retain their original authorship and timestamps; current Boofy engineering work is recorded through new commits and issues.

## Team

- **Fan Long** — Co-Founder
- **David Woo** — Developer
- **Tyler Casselman** — Developer
- **Albert Jones** — Developer

See [BOOFY_TEAM.md](BOOFY_TEAM.md).

## Contributing

Contributions should include clear rationale, testing instructions, and deployment assumptions. Smart-contract changes should be reviewed carefully before any production use.

## Migration notice

See [BOOFY_MIGRATION_NOTICE.md](BOOFY_MIGRATION_NOTICE.md) before deploying or integrating any contract from this repository.

## License and attribution

Original upstream authorship and license attribution are preserved in source files and license materials.
