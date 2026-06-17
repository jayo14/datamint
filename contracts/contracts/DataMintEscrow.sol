// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract DataMintEscrow is Ownable, ReentrancyGuard {
    IERC20 public immutable cusdToken;

    struct Dataset {
        uint256 id;
        address creator;
        uint256 rewardPerTask;
        uint256 totalRequired;
        uint256 fundedAmount;
        uint256 paidOutAmount;
        bool active;
    }

    mapping(uint256 => Dataset) public datasets;
    mapping(uint256 => mapping(address => bool)) public hasSubmitted;

    event DatasetCreated(uint256 indexed datasetId, address indexed creator, uint256 rewardPerTask, uint256 totalRequired);
    event DatasetFunded(uint256 indexed datasetId, uint256 amount);
    event WorkSubmitted(uint256 indexed datasetId, address indexed contributor);
    event PaymentReleased(uint256 indexed datasetId, address indexed contributor, uint256 amount);

    constructor(address _cusdToken) Ownable(msg.sender) {
        cusdToken = IERC20(_cusdToken);
    }

    function createDataset(uint256 _datasetId, uint256 _rewardPerTask, uint256 _totalRequired) external {
        require(datasets[_datasetId].creator == address(0), "Dataset already exists");

        datasets[_datasetId] = Dataset({
            id: _datasetId,
            creator: msg.sender,
            rewardPerTask: _rewardPerTask,
            totalRequired: _totalRequired,
            fundedAmount: 0,
            paidOutAmount: 0,
            active: true
        });

        emit DatasetCreated(_datasetId, msg.sender, _rewardPerTask, _totalRequired);
    }

    function fundDataset(uint256 _datasetId, uint256 _amount) external nonReentrant {
        Dataset storage dataset = datasets[_datasetId];
        require(dataset.active, "Dataset not active");

        require(cusdToken.transferFrom(msg.sender, address(this), _amount), "Transfer failed");

        dataset.fundedAmount += _amount;

        emit DatasetFunded(_datasetId, _amount);
    }

    function submitWork(uint256 _datasetId, address _contributor) external {
        // In a real scenario, this might be called by an oracle or a validator
        // For MVP, we'll allow anyone to log a submission, but only creator approves
        require(datasets[_datasetId].active, "Dataset not active");
        require(!hasSubmitted[_datasetId][_contributor], "Already submitted");

        emit WorkSubmitted(_datasetId, _contributor);
    }

    function approveWork(uint256 _datasetId, address _contributor) external nonReentrant {
        Dataset storage dataset = datasets[_datasetId];
        require(msg.sender == dataset.creator, "Only creator can approve");
        require(dataset.fundedAmount >= dataset.rewardPerTask, "Insufficient escrow balance");

        dataset.fundedAmount -= dataset.rewardPerTask;
        dataset.paidOutAmount += dataset.rewardPerTask;

        require(cusdToken.transfer(_contributor, dataset.rewardPerTask), "Payout failed");

        emit PaymentReleased(_datasetId, _contributor, dataset.rewardPerTask);
    }

    function getDatasetBalance(uint256 _datasetId) external view returns (uint256) {
        return datasets[_datasetId].fundedAmount;
    }
}
