// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (governance/compatibility/GovernorCompatibilityBravo.sol)

pragma solidity ^0.8.0;

import "../../utils/math/SafeCastUpgradeable.sol";
import "../extensions/IGovernorTimelockUpgradeable.sol";
import "../GovernorUpgradeable.sol";
import "./IGovernorCompatibilityBravoUpgradeable.sol";
import "../../proxy/utils/initializable.sol";

/**
 * @dev Compatibility layer that implements GovernorBravo compatibility on top of {Governor}.
 *
 * This compatibility layer includes a voting system and requires a {IGovernorTimelock} compatible module to be added
 * through inheritance. It does not include token bindings, nor does it include any variable upgrade patterns.
 *
 * NOTE: When using this module, you may need to enable the Solidity optimizer to avoid hitting the contract size limit.
 *
 * _Available since v4.3._
 */
abstract contract GovernorCompatibilityBravoUpgradeable is Initializable, IGovernorTimelockUpgradeable, IGovernorCompatibilityBravoUpgradeable, GovernorUpgradeable {
    enum VoteType {
        Against,
        For,
        Abstain
    }

    struct ProposalDetails {
        address proposer;
        address[] targets;
        uint256[] values;
        string[] signatures;
        bytes[] calldatas;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 abstainVotes;
        mapping(address => Receipt) receipts;
        bytes32 descriptionHash;
    }

    mapping(uint256 => ProposalDetails) private _proposalDetails;

    function __GovernorCompatibilityBravo_init() internal onlyInitializing {
    }

    function __GovernorCompatibilityBravo_init_unchained() internal onlyInitializing {
    }
    // solhint-disable-next-line func-name-mixedcase
    function COUNTING_MODE() public pure virtual override returns (string memory) {
        return "support=bravo&quorum=bravo";
    }

    // ============================================== Proposal lifecycle ==============================================
    /**
     * @dev See {IGovernor-propose}.
     */
    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public virtual override(IGovernorUpgradeable, GovernorUpgradeable) returns (uint256) {
        // Stores the proposal details (if not already present) and executes the propose logic from the core.
        _storeProposal(_msgSender(), targets, values, new string[](calldatas.length), calldatas, description);
        return super.propose(targets, values, calldatas, description);
    }

    /**
     * @dev See {IGovernorCompatibilityBravo-propose}.
     */
    function propose(
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory description
    ) public virtual override returns (uint256) {
        require(signatures.length == calldatas.length, "GovernorBravo: invalid signatures length");
        // Stores the full proposal and fallback to the public (possibly overridden) propose. The fallback is done
        // after the full proposal is stored, so the store operation included in the fallback will be skipped. Here we
        // call `propose` and not `super.propose` to make sure if a child contract override `propose`, whatever code
        // is added there is also executed when calling this alternative interface.
        _storeProposal(_msgSender(), targets, values, signatures, calldatas, description);
        return propose(targets, values, _encodeCalldata(signatures, calldatas), description);
    }

    /**
     * @dev See {IGovernorCompatibilityBravo-queue}.
     */
    function queue(uint256 proposalId) public virtual override {
        (
            address[] memory targets,
            uint256[] memory values,
            bytes[] memory calldatas,
            bytes32 descriptionHash
        ) = _getProposalParameters(proposalId);

        queue(targets, values, calldatas, descriptionHash);
    }

    /**
     * @dev See {IGovernorCompatibilityBravo-execute}.
     */
    function execute(uint256 proposalId) public payable virtual override {
        (
            address[] memory targets,
            uint256[] memory values,
            bytes[] memory calldatas,
            bytes32 descriptionHash
        ) = _getProposalParameters(proposalId);

        execute(targets, values, calldatas, descriptionHash);
    }

    /**
     * @dev Cancel a proposal with GovernorBravo logic.
     */
    function cancel(uint256 proposalId) public virtual override {
        (
            address[] memory targets,
            uint256[] memory values,
            bytes[] memory calldatas,
            bytes32 descriptionHash
        ) = _getProposalParameters(proposalId);

        cancel(targets, values, calldatas, descriptionHash);
    }

    /**
     * @dev Cancel a proposal with GovernorBravo logic. At any moment a proposal can be cancelled, either by the
     * proposer, or by third parties if the proposer's voting power has dropped below the proposal threshold.
     */
    function cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public virtual override(IGovernorUpgradeable, GovernorUpgradeable) returns (uint256) {
        uint256 proposalId = hashProposal(targets, values, calldatas, descriptionHash);
        address proposer = _proposalDetails[proposalId].proposer;

        require(
            _msgSender() == proposer || getVotes(proposer, clock() - 1) < proposalThreshold(),
            "GovernorBravo: proposer above threshold"
        );

        return _cancel(targets, values, calldatas, descriptionHash);
    }

    /**
     * @dev Encodes calldatas with optional function signature.
     */
    function _encodeCalldata(
        string[] memory signatures,
        bytes[] memory calldatas
    ) private pure returns (bytes[] memory) {
        bytes[] memory fullcalldatas = new bytes[](calldatas.length);
        for (uint256 i = 0; i < fullcalldatas.length; ++i) {
            fullcalldatas[i] = bytes(signatures[i]).length == 0
                ? calldatas[i]
                : abi.encodePacked(bytes4(keccak256(bytes(signatures[i]))), calldatas[i]);
        }

        return fullcalldatas;
    }

    /**
     * @dev Retrieve proposal parameters by id, with fully encoded calldatas.
     */
    function _getProposalParameters(
        uint256 proposalId
    )
        private
        view
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes32 descriptionHash)
    {
        ProposalDetails storage details = _proposalDetails[proposalId];
        return (
            details.targets,
            details.values,
            _encodeCalldata(details.signatures, details.calldatas),
            details.descriptionHash
        );
    }

    /**
     * @dev Store proposal metadata (if not already present) for later lookup.
     */
    function _storeProposal(
        address proposer,
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory description
    ) private {
        bytes32 descriptionHash = keccak256(bytes(description));
        uint256 proposalId = hashProposal(targets, values, _encodeCalldata(signatures, calldatas), descriptionHash);

        ProposalDetails storage details = _proposalDetails[proposalId];
        if (details.descriptionHash == bytes32(0)) {
            details.proposer = proposer;
            details.targets = targets;
            details.values = values;
            details.signatures = signatures;
            details.calldatas = calldatas;
            details.descriptionHash = descriptionHash;
        }
    }

    // ==================================================== Views =====================================================
    /**
     * @dev See {IGovernorCompatibilityBravo-proposals}.
     */
    function proposals(
        uint256 proposalId
    )
        public
        view
        virtual
        override
        returns (
            uint256 id,
            address proposer,
            uint256 eta,
            uint256 startBlock,
            uint256 endBlock,
            uint256 forVotes,
            uint256 againstVotes,
            uint256 abstainVotes,
            bool canceled,
            bool executed
        )
    {
        id = proposalId;
        eta = proposalEta(proposalId);
        startBlock = proposalSnapshot(proposalId);
        endBlock = proposalDeadline(proposalId);

        ProposalDetails storage details = _proposalDetails[proposalId];
        proposer = details.proposer;
        forVotes = details.forVotes;
        againstVotes = details.againstVotes;
        abstainVotes = details.abstainVotes;

        ProposalState currentState = state(proposalId);
        canceled = currentState == ProposalState.Canceled;
        executed = currentState == ProposalState.Executed;
    }

    /**
     * @dev See {IGovernorCompatibilityBravo-getActions}.
     */
    function getActions(
        uint256 proposalId
    )
        public
        view
        virtual
        override
        returns (
            address[] memory targets,
            uint256[] memory values,
            string[] memory signatures,
            bytes[] memory calldatas
        )
    {
        ProposalDetails storage details = _proposalDetails[proposalId];
        return (details.targets, details.values, details.signatures, details.calldatas);
    }

    /**
     * @dev See {IGovernorCompatibilityBravo-getReceipt}.
     */
    function getReceipt(uint256 proposalId, address voter) public view virtual override returns (Receipt memory) {
        return _proposalDetails[proposalId].receipts[voter];
    }

    /**
     * @dev See {IGovernorCompatibilityBravo-quorumVotes}.
     */
    function quorumVotes() public view virtual override returns (uint256) {
        return quorum(clock() - 1);
    }

    // ==================================================== Voting ====================================================
    /**
     * @dev See {IGovernor-hasVoted}.
     */
    function hasVoted(uint256 proposalId, address account) public view virtual override returns (bool) {
        return _proposalDetails[proposalId].receipts[account].hasVoted;
    }

    /**
     * @dev See {Governor-_quorumReached}. In this module, only forVotes count toward the quorum.
     */
    function _quorumReached(uint256 proposalId) internal view virtual override returns (bool) {
        ProposalDetails storage details = _proposalDetails[proposalId];
        return quorum(proposalSnapshot(proposalId)) <= details.forVotes;
    }

    /**
     * @dev See {Governor-_voteSucceeded}. In this module, the forVotes must be strictly over the againstVotes.
     */
    function _voteSucceeded(uint256 proposalId) internal view virtual override returns (bool) {
        ProposalDetails storage details = _proposalDetails[proposalId];
        return details.forVotes > details.againstVotes;
    }

    /**
     * @dev See {Governor-_countVote}. In this module, the support follows Governor Bravo.
     */
    function _countVote(
        uint256 proposalId,
        address account,
        uint8 support,
        uint256 weight,
        bytes memory // params
    ) internal virtual override {
        ProposalDetails storage details = _proposalDetails[proposalId];
        Receipt storage receipt = details.receipts[account];

        require(!receipt.hasVoted, "GovernorCompatibilityBravo: vote already cast");
        receipt.hasVoted = true;
        receipt.support = support;
        receipt.votes = SafeCastUpgradeable.toUint96(weight);

        if (support == uint8(VoteType.Against)) {
            details.againstVotes += weight;
        } else if (support == uint8(VoteType.For)) {
            details.forVotes += weight;
        } else if (support == uint8(VoteType.Abstain)) {
            details.abstainVotes += weight;
        } else {
            revert("GovernorCompatibilityBravo: invalid vote type");
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}
