# Update Checklist

This checklist is seen as a guide to update the existing deployment.

## Pre-Update

- [ ] Make sure you are using Node v16
- [ ] Verify that all changes of this update are reflected in [contracts/CHANGELOG.md](packages/contracts/CHANGELOG.md) by comparing the diff with the previous release commit.
- [ ] Check that storage corruption tests using OZ's `hardhat-upgrades` package (e.g., by using the methods in [uups-upgradeable.ts](packages/contracts/test/test-utils/uups-upgradeable.ts)) exist for every upgradeable contract and test the upgrade from all prior versions to the current version.
- [ ] Check that all contracts that undergo an upgrade and
  - [ ] do require reinitialzation are reinitialized correctly by an `upgradeToAndCall` call to a respective initialization method with an incremented `reinitializer(X)` number
  - [ ] do NOT require reinitialzation are upgraded via `upgradeTo` and keep the same `reinitializer(X)` number in the respective initialization methods
  - [ ] have new storage added to them
    - [ ] decrement the storage gap correctly
    - [ ] do not corrupt pre-existing storage
    - [ ] initialize the storage correctly
- [ ] Make sure that the `deploy` property in `packages/contracts/networks.json` points to the correct update
- [ ] Run `yarn` in the repository root to install the dependencies
- [ ] Run `yarn run build:contracts-versions` in `packages/contracts` to make sure the contracts compile
- [ ] Run `yarn build` in `packages/contracts` to make sure the contracts compile
- [ ] Run `yarn test` in `packages/contracts` to make sure the contract tests succeed
- [ ] Set `ETH_KEY` in `.env` to the deployers private key. It doesn't have to be the previous deployer
- [ ] Set the right API key for the chains blockchain explorer in `.env` (e.g. for mainnet it is `ETHERSCAN_KEY`)
- [ ] Copy the managing DAO multisig env variables from `packages/contracts/.env-example` into `packages/contracts/.env`
- [ ] Follow the version specific tasks in the section `Version tasks`
- [ ] If new plugin builds are released
  - [ ] Double-check that the build-metadata was updated correctly for the UI to work correctly
  - [ ] If the plugin is used by the managing DAO and the new build includes security relevant changes it must be applied immediately

## Update

To update run `yarn deploy --network NETWORK` in `packages/contracts` and replace `NETWORK` with the correct network name (e.g. for mainnet it is `yarn deploy --network mainnet`).

## After-Update

- [ ] Follow the version specific tasks in the section `Version tasks`

### Configuration updates

- [ ] Take the addresses from this file `packages/contracts/deployed_contracts.json`
- [ ] Update `active_contracts.json` with the new deployed addresses
- [ ] Update `packages/contracts/Releases.md` with the new deployed addresses
- [ ] Add a Github Release with the version number as tag and the defined content (check previous releases for reference)

### ManagingDAO

If the deployer **is not** allowed to create a new proposal in the managing DAOs' multisig the script creates a new file `packages/contracts/managingDAOTX.json`

- [ ] Verify the transaction to include the necessary actions
- [ ] Take this file and send it to a party that can create a proposal and let them create it

If the deployer **is** allowed to create a proposal

- [ ] Verify that the created proposal includes all necessary actions

### Verfication

- [ ] Take the addresses from this file `packages/contracts/deployed_contracts.json`
- [ ] Wait for the deployment script finishing verification
- [ ] Go to the blockchain explorer and verify that each address is verified
  - [ ] If it is not try to verfiy it with `npx hardhat verify --network NETWORK ADDRESS CONTRUCTOR-ARGS`. More infos on how to use this command can be found here: [https://hardhat.org/hardhat-runner/docs/guides/verifying](https://hardhat.org/hardhat-runner/docs/guides/verifying)
  - [ ] If it is a proxy try to activate the blockchain explorer's proxy feature
  - [ ] If the proxies are not verified with the `Similar Match Source Code` feature
    - [ ] Remove `import '@openzeppelin/hardhat-upgrades'` from `packages/contracts/hardhat.config.ts`
    - [ ] Verify one of the proxies
    - [ ] Check if the other proxies are now verified with `Similar Match Source Code`

### Configuration

- [ ] Check if all permissions (if) given to the deployer are revoked and transfered to the managing DAO
- [ ] Check if the `dao` parameter is set to the managing DAO where it can be set
- [ ] Check that the permissions are set correctly for the framework to function

### Packages

Wait until the managing DAO has made the necessary changes and then:

- [ ] Publish a new version of `@aragon/osx-artifacts` (`./packages/contracts`) to NPM
- [ ] Publish a new version of `@aragon/osx-ethers` (`./packages/contracts-ethers`) to NPM

if the new contracts **aren't** published:

- [ ] Publish a new version of `@aragon/osx` (`./packages/contracts/src`) to NPM
- [ ] Update the changelog with the new version

### Subgraph

- [ ] Update `packages/subgraph/manifest/data/NETWORK.json` where `NETWORK` is replaced with the deployed network with the new contract addresses
- [ ] Update the version in `packages/subgraph/package.json`
- [ ] Update `packages/subgraph/.env` with the correct values
  - [ ] set `NETWORK_NAME` to the deployed network
  - [ ] set `SUBGRAPH_NAME` to `osx`
  - [ ] set `GRAPH_KEY` with the value obtained from the [Satsuma Dashboard](https://app.satsuma.xyz/dashboard)
  - [ ] set the `SUBGRAPH_VERSION` to the same value as in `packages/subgraph/package.json`
- [ ] Run `yarn manifest` in `packages/subgraph` to generate the manifest
- [ ] Run `yarn build` in `packages/subgraph` to build the subgraph
- [ ] Run `yarn test` in `packages/subgraph` to test the subgraph
- [ ] Run `yarn deploy` in `packages/subgraph` to deploy the subgraph
- [ ] Test the new deployed subgraph with the frontend team
- [ ] Promote the new subgraph to live in the [Satsuma Dashboard](https://app.satsuma.xyz/dashboard)

## Version tasks

### v1.3.0

#### Pre-Update

Nothing to do.

#### After-Update

Wait until the managing DAO has made the necessary changes and then:

- [ ] Verify that the `DAO` base contract in the `DAOFactory` has been updated
- [ ] Verify that the managing DAO implementation has been updated to the new implementation
- [ ] Verify that the managing DAO is reinitialized to `_initialized = 2`
- [ ] Verify that the old `DAOFactory` has no permissions on the `DAORegistry`
- [ ] Verify that the new `DAOFactory` has the `REGISTER_DAO_PERMISSION_ID` permission on the `DAORegistry`
- [ ] Verify that the `PluginRepo` base contract in the `PluginRepoFactory` has been updated
- [ ] Verify that all `PluginRepo`s controlled by the managing DAO have been updated to the new implementation and are still initialized with `_initialized = 1`
  - [ ] 'multisig-repo'
  - [ ] 'admin-repo'
  - [ ] 'token-voting-repo'
  - [ ] 'address-list-voting-repo'
- [ ] Verify that the old `PluginRepoFactory` has no permissions on the `PluginRepoRegistry`
- [ ] Verify that the new `PluginRepoFactory` has the `REGISTER_PLUGIN_REPO_PERMISSION_ID` permission on the `PluginRepoRegistry`
- [ ] Verify that Release 1 Build 2 of the `Multisig` plugin has been created
- [ ] Verify that Release 1 Build 2 of the `TokenVoting` plugin has been created
- [ ] Verify that Release 1 Build 2 of the `AddresslistVoting` plugin has been created
