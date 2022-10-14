// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-IERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20VotesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";

import {DaoAuthorizableUpgradeable} from "../core/component/DaoAuthorizableUpgradeable.sol";
import {IDAO} from "../core/IDAO.sol";

/// @title GovernanceERC20
/// @author Aragon Association
/// @notice An [ERC-20](https://eips.ethereum.org/EIPS/eip-20) token that can be used for voting and is managed by a DAO.
contract GovernanceERC20 is ERC165Upgradeable, ERC20VotesUpgradeable, DaoAuthorizableUpgradeable {
    /// @notice The permission identifier to mint new tokens
    bytes32 public constant MINT_PERMISSION_ID = keccak256("MINT_PERMISSION");

    /// @notice Internal initialization method.
    /// @param _dao The managing DAO.
    /// @param _name The name of the wrapped token.
    /// @param _symbol The symbol fo the wrapped token.
    function __GovernanceERC20_init(
        IDAO _dao,
        string calldata _name,
        string calldata _symbol
    ) internal onlyInitializing {
        __ERC20_init(_name, _symbol);
        __ERC20Permit_init(_name);
        __DaoAuthorizableUpgradeable_init(_dao);
    }

    /// @notice Initializes the component.
    /// @param _dao The managing DAO.
    /// @param _name The name of the wrapped token.
    /// @param _symbol The symbol fo the wrapped token.
    function initialize(
        IDAO _dao,
        string calldata _name,
        string calldata _symbol
    ) external initializer {
        __GovernanceERC20_init(_dao, _name, _symbol);
    }

    /// @inheritdoc ERC165Upgradeable
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC20Upgradeable).interfaceId ||
            interfaceId == type(IERC20PermitUpgradeable).interfaceId ||
            interfaceId == type(IERC20MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @notice Mints tokens to an address.
    /// @param to The address receiving the tokens.
    /// @param amount The amount of tokens to be minted.
    function mint(address to, uint256 amount) external auth(MINT_PERMISSION_ID) {
        _mint(to, amount);
    }

    // The functions below are overrides required by Solidity.
    // https://forum.openzeppelin.com/t/self-delegation-in-erc20votes/17501/12?u=novaknole
    /// @inheritdoc ERC20VotesUpgradeable
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        super._afterTokenTransfer(from, to, amount);
        // reduce _delegate calls only when minting
        if (from == address(0) && to != address(0) && delegates(to) == address(0)) {
            _delegate(to, to);
        }
    }

    /// @inheritdoc ERC20VotesUpgradeable
    function _mint(address to, uint256 amount) internal override {
        super._mint(to, amount);
    }

    /// @inheritdoc ERC20VotesUpgradeable
    function _burn(address account, uint256 amount) internal override {
        super._burn(account, amount);
    }

    /// @inheritdoc ContextUpgradeable
    function _msgSender()
        internal
        view
        override(ContextUpgradeable, DaoAuthorizableUpgradeable)
        returns (address)
    {
        return ContextUpgradeable._msgSender();
    }

    /// @inheritdoc ContextUpgradeable
    function _msgData()
        internal
        view
        override(ContextUpgradeable, DaoAuthorizableUpgradeable)
        returns (bytes calldata)
    {
        return ContextUpgradeable._msgData();
    }
}
