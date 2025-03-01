// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../../proxy/utils/initializable.sol";

contract ERC165NotSupportedUpgradeable is Initializable {    function __ERC165NotSupported_init() internal onlyInitializing {
    }

    function __ERC165NotSupported_init_unchained() internal onlyInitializing {
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}
