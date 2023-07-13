// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract CompromisedAggregator is Ownable {
    event AnswerUpdated(
        int256 indexed current,
        uint256 indexed roundId,
        uint256 updatedAt
    );
    event NewRound(
        uint256 indexed roundId,
        address indexed startedBy,
        uint256 startedAt
    );
    // Storing these fields used on the hot path in a HotVars variable reduces the
    // retrieval of all of them to a single SLOAD. If any further fields are
    // added, make sure that storage of the struct still takes at most 32 bytes.
    struct HotVars {
        // Provides 128 bits of security against 2nd pre-image attacks, but only
        // 64 bits against collisions. This is acceptable, since a malicious owner has
        // easier way of messing up the protocol than to find hash collisions.
        bytes16 latestConfigDigest;
        uint40 latestEpochAndRound; // 32 most sig bits for epoch, 8 least sig bits for round
        // Current bound assumed on number of faulty/dishonest oracles participating
        // in the protocol, this value is referred to as f in the design
        uint8 threshold;
        // Chainlink Aggregators expose a roundId to consumers. The offchain reporting
        // protocol does not use this id anywhere. We increment it whenever a new
        // transmission is made to provide callers with contiguous ids for successive
        // reports.
        uint32 latestAggregatorRoundId;
    }
    HotVars internal s_hotVars;
    struct Transmission {
        int192 answer; // 192 bits ought to be enough for anyone
        uint64 timestamp;
    }

    mapping(uint32 /* aggregator round ID */ => Transmission)
        internal s_transmissions;

    int192 public immutable minAnswer;
    int192 public immutable maxAnswer;
    // int256 public answer;

    uint8 public decimals;

    // string internal s_description = "USDC / USD";
    string internal s_description;

    uint256 public constant version = 4;

    // Compromised Agg Storage
    address internal validator;
    uint32 internal gasLimit = 450000;
    uint256 constant maxNumOracles = 10;

    constructor(
        string memory _description,
        address _validator,
        uint8 _decimals,
        int192 _minAnswer,
        int192 _maxAnswer
    ) Ownable() {
        s_description = _description;
        validator = _validator;
        decimals = _decimals;
        minAnswer = _minAnswer;
        maxAnswer = _maxAnswer;
    }

    /*
     * Transmission logic
     */
    function validateAnswer(uint32 _aggregatorRoundId, int256 _answer) private {
        uint32 prevAggregatorRoundId = _aggregatorRoundId - 1;
        int256 prevAggregatorRoundAnswer = s_transmissions[
            prevAggregatorRoundId
        ].answer;
        require(
            callWithExactGasEvenIfTargetIsNoContract(
                gasLimit,
                address(validator),
                abi.encodeWithSignature(
                    "validate(uint256,int256,uint256,int256)",
                    uint256(prevAggregatorRoundId),
                    prevAggregatorRoundAnswer,
                    uint256(_aggregatorRoundId),
                    _answer
                )
            ),
            "insufficient gas"
        );
    }

    /**
     * @dev calls target address with exactly gasAmount gas and data as calldata
     * or reverts if at least gasAmount gas is not available.
     */
    function callWithExactGasEvenIfTargetIsNoContract(
        uint256 _gasAmount,
        address _target,
        bytes memory _data
    ) private returns (bool sufficientGas) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let g := gas()
            // Compute g -= CALL_WITH_EXACT_GAS_CUSHION and check for underflow. We
            // need the cushion since the logic following the above call to gas also
            // costs gas which we cannot account for exactly. So cushion is a
            // conservative upper bound for the cost of this logic.
            if iszero(lt(g, CALL_WITH_EXACT_GAS_CUSHION)) {
                g := sub(g, CALL_WITH_EXACT_GAS_CUSHION)
                // If g - g//64 <= _gasAmount, we don't have enough gas. (We subtract g//64
                // because of EIP-150.)
                if gt(sub(g, div(g, 64)), _gasAmount) {
                    // Call and ignore success/return data. Note that we did not check
                    // whether a contract actually exists at the _target address.
                    pop(
                        call(
                            _gasAmount,
                            _target,
                            0,
                            add(_data, 0x20),
                            mload(_data),
                            0,
                            0
                        )
                    )
                    sufficientGas := true
                }
            }
        }
    }

    uint256 private constant CALL_WITH_EXACT_GAS_CUSHION = 5_000;

    /**
     * @notice indicates that a new report was transmitted
     * @param aggregatorRoundId the round to which this report was assigned
     * @param answer median of the observations attached this report
     * @param transmitter address from which the report was transmitted
     * @param observations observations transmitted with this report
     * @param rawReportContext signature-replay-prevention domain-separation tag
     */
    event NewTransmission(
        uint32 indexed aggregatorRoundId,
        int192 answer,
        address transmitter,
        int192[] observations,
        bytes observers,
        bytes32 rawReportContext
    );

    // decodeReport is used to check that the solidity and go code are using the
    // same format. See TestOffchainAggregator.testDecodeReport and TestReportParsing
    function decodeReport(
        bytes memory _report
    )
        internal
        pure
        returns (
            bytes32 rawReportContext,
            bytes32 rawObservers,
            int192[] memory observations
        )
    {
        (rawReportContext, rawObservers, observations) = abi.decode(
            _report,
            (bytes32, bytes32, int192[])
        );
    }

    // Used to relieve stack pressure in transmit
    struct ReportData {
        HotVars hotVars; // Only read from storage once
        bytes observers; // ith element is the index of the ith observer
        int192[] observations; // ith element is the ith observation
        bytes vs; // jth element is the v component of the jth signature
        bytes32 rawReportContext;
    }

    /*
   * @notice details about the most recent report

   * @return configDigest domain separation tag for the latest report
   * @return epoch epoch in which the latest report was generated
   * @return round OCR round in which the latest report was generated
   * @return latestAnswer median value from latest report
   * @return latestTimestamp when the latest report was transmitted
   */
    function latestTransmissionDetails()
        external
        view
        returns (
            bytes16 configDigest,
            uint32 epoch,
            uint8 round,
            int192 _latestAnswer,
            uint64 _latestTimestamp
        )
    {
        require(msg.sender == tx.origin, "Only callable by EOA");
        return (
            s_hotVars.latestConfigDigest,
            uint32(s_hotVars.latestEpochAndRound >> 8),
            uint8(s_hotVars.latestEpochAndRound),
            s_transmissions[s_hotVars.latestAggregatorRoundId].answer,
            s_transmissions[s_hotVars.latestAggregatorRoundId].timestamp
        );
    }

    /*
     * v2 Aggregator interface
     */

    /**
     * @notice median from the most recent report
     */
    function latestAnswer() public view virtual returns (int256) {
        return s_transmissions[s_hotVars.latestAggregatorRoundId].answer;
    }

    /**
     * @notice timestamp of block in which last report was transmitted
     */
    function latestTimestamp() public view virtual returns (uint256) {
        return s_transmissions[s_hotVars.latestAggregatorRoundId].timestamp;
    }

    /**
     * @notice Aggregator round (NOT OCR round) in which last report was transmitted
     */
    function latestRound() public view virtual returns (uint256) {
        return s_hotVars.latestAggregatorRoundId;
    }

    /**
     * @notice median of report from given aggregator round (NOT OCR round)
     * @param _roundId the aggregator round of the target report
     */
    function getAnswer(uint256 _roundId) public view virtual returns (int256) {
        if (_roundId > 0xFFFFFFFF) {
            return 0;
        }
        return s_transmissions[uint32(_roundId)].answer;
    }

    /**
     * @notice timestamp of block in which report from given aggregator round was transmitted
     * @param _roundId aggregator round (NOT OCR round) of target report
     */
    function getTimestamp(
        uint256 _roundId
    ) public view virtual returns (uint256) {
        if (_roundId > 0xFFFFFFFF) {
            return 0;
        }
        return s_transmissions[uint32(_roundId)].timestamp;
    }

    /*
     * v3 Aggregator interface
     */

    string private constant V3_NO_DATA_ERROR = "No data present";

    /**
     * @notice human-readable description of observable this contract is reporting on
     */
    function description() public view virtual returns (string memory) {
        return s_description;
    }

    /**
     * @notice details for the given aggregator round
     * @param _roundId target aggregator round (NOT OCR round). Must fit in uint32
     * @return roundId _roundId
     * @return answer median of report from given _roundId
     * @return startedAt timestamp of block in which report from given _roundId was transmitted
     * @return updatedAt timestamp of block in which report from given _roundId was transmitted
     * @return answeredInRound _roundId
     */
    function getRoundData(
        uint80 _roundId
    )
        public
        view
        virtual
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        require(_roundId <= 0xFFFFFFFF, V3_NO_DATA_ERROR);
        Transmission memory transmission = s_transmissions[uint32(_roundId)];
        return (
            _roundId,
            transmission.answer,
            transmission.timestamp,
            transmission.timestamp,
            _roundId
        );
    }

    /**
     * @notice aggregator details for the most recently transmitted report
     * @return roundId aggregator round of latest report (NOT OCR round)
     * @return answer median of latest report
     * @return startedAt timestamp of block containing latest report
     * @return updatedAt timestamp of block containing latest report
     * @return answeredInRound aggregator round of latest report
     */
    function latestRoundData()
        public
        view
        virtual
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        roundId = s_hotVars.latestAggregatorRoundId;

        // Skipped for compatability with existing FluxAggregator in which latestRoundData never reverts.
        // require(roundId != 0, V3_NO_DATA_ERROR);

        Transmission memory transmission = s_transmissions[uint32(roundId)];
        return (
            roundId,
            transmission.answer,
            transmission.timestamp,
            transmission.timestamp,
            roundId
        );
    }

    /**
     * @notice transmit is called to post a new report to the contract
     * @param _report serialized report, which the signatures are signing. See parsing code below for format. The ith element of the observers component must be the index in s_signers of the address for the ith signature
     */
    function transmit(bytes calldata _report) external onlyOwner {

        ReportData memory r; // Relieves stack pressure
        {
            r.hotVars = s_hotVars; // cache read from storage

            bytes32 rawObservers;
            uint40 epochAndRound;
            // (epochAndRound, rawObservers, r.observations) = abi.decode(
            //     _report,
            //     (uint40, bytes32, int192[])
            // );
            (epochAndRound, rawObservers, r.observations) = abi.decode(
                _report,
                (uint40, bytes32, int192[])
            );

            require(
                r.hotVars.latestEpochAndRound < epochAndRound,
                "stale report"
            );

            require(
                r.observations.length > 2 * r.hotVars.threshold,
                "too few values to trust median"
            );

            // Copy observer identities in bytes32 rawObservers to bytes r.observers
            r.observers = new bytes(r.observations.length);
            bool[maxNumOracles] memory seen;
            for (uint8 i = 0; i < r.observations.length; i++) {
                uint8 observerIdx = uint8(rawObservers[i]);
                require(!seen[observerIdx], "observer index repeated");
                seen[observerIdx] = true;
                r.observers[i] = rawObservers[i];
            }

            // record epochAndRound here, so that we don't have to carry the local
            // variable in transmit. The change is reverted if something fails later.
            r.hotVars.latestEpochAndRound = epochAndRound;
        }

        {
            // Check the report contents, and record the result
            for (uint i = 0; i < r.observations.length - 1; i++) {
                bool inOrder = r.observations[i] <= r.observations[i + 1];
                require(inOrder, "observations not sorted");
            }

            int192 median = r.observations[r.observations.length / 2];
            require(
                minAnswer <= median && median <= maxAnswer,
                "median is out of min-max range"
            );
            r.hotVars.latestAggregatorRoundId++;
            s_transmissions[r.hotVars.latestAggregatorRoundId] = Transmission(
                median,
                uint64(block.timestamp)
            );

            emit NewTransmission(
                r.hotVars.latestAggregatorRoundId,
                median,
                msg.sender,
                r.observations,
                r.observers,
                r.rawReportContext
            );
            // Emit these for backwards compatability with offchain consumers
            // that only support legacy events
            emit NewRound(
                r.hotVars.latestAggregatorRoundId,
                address(0x0), // use zero address since we don't have anybody "starting" the round here
                block.timestamp
            );
            emit AnswerUpdated(
                median,
                r.hotVars.latestAggregatorRoundId,
                block.timestamp
            );

            validateAnswer(r.hotVars.latestAggregatorRoundId, median);
        }
        s_hotVars = r.hotVars;
    }
}
