// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title AI-Training On-Chain Game
 * @dev A blockchain game where players train AI models and compete based on performance
 */
contract Project is Ownable, ReentrancyGuard {
    
    struct AIModel {
        string name;
        uint256 trainingCost;
        uint256 performanceScore;
        uint256 trainingTime;
        address trainer;
        bool isActive;
        uint256 createdAt;
    }
    
    struct Player {
        string username;
        uint256 totalModels;
        uint256 bestScore;
        uint256 totalEarnings;
        bool isRegistered;
    }
    
    // State variables
    mapping(uint256 => AIModel) public aiModels;
    mapping(address => Player) public players;
    mapping(address => uint256[]) public playerModels;
    
    uint256 public nextModelId;
    uint256 public constant BASE_TRAINING_COST = 0.01 ether;
    uint256 public constant TRAINING_DURATION = 300; // 5 minutes in seconds
    uint256 public totalPrizePool;
    
    // Events
    event PlayerRegistered(address indexed player, string username);
    event ModelCreated(uint256 indexed modelId, address indexed trainer, string name);
    event TrainingCompleted(uint256 indexed modelId, uint256 performanceScore);
    event RewardClaimed(address indexed player, uint256 amount);
    
    constructor() Ownable(msg.sender) {
        nextModelId = 1;
    }
    
    /**
     * @dev Register a new player in the game
     * @param _username The username for the player
     */
    function registerPlayer(string memory _username) external {
        require(!players[msg.sender].isRegistered, "Player already registered");
        require(bytes(_username).length > 0, "Username cannot be empty");
        
        players[msg.sender] = Player({
            username: _username,
            totalModels: 0,
            bestScore: 0,
            totalEarnings: 0,
            isRegistered: true
        });
        
        emit PlayerRegistered(msg.sender, _username);
    }
    
    /**
     * @dev Create and train a new AI model
     * @param _modelName The name of the AI model
     */
    function createAndTrainModel(string memory _modelName) external payable nonReentrant {
        require(players[msg.sender].isRegistered, "Must register as player first");
        require(msg.value >= BASE_TRAINING_COST, "Insufficient training cost");
        require(bytes(_modelName).length > 0, "Model name cannot be empty");
        
        uint256 modelId = nextModelId++;
        
        // Create the AI model
        aiModels[modelId] = AIModel({
            name: _modelName,
            trainingCost: msg.value,
            performanceScore: 0,
            trainingTime: block.timestamp + TRAINING_DURATION,
            trainer: msg.sender,
            isActive: true,
            createdAt: block.timestamp
        });
        
        // Update player stats
        playerModels[msg.sender].push(modelId);
        players[msg.sender].totalModels++;
        
        // Add to prize pool (90% goes to prize pool, 10% for contract maintenance)
        totalPrizePool += (msg.value * 90) / 100;
        
        emit ModelCreated(modelId, msg.sender, _modelName);
    }
    
    /**
     * @dev Complete training and calculate performance score for an AI model
     * @param _modelId The ID of the model to complete training
     */
    function completeTraining(uint256 _modelId) external {
        require(_modelId < nextModelId, "Model does not exist");
        AIModel storage model = aiModels[_modelId];
        require(model.trainer == msg.sender, "Not the model trainer");
        require(model.isActive, "Model is not active");
        require(block.timestamp >= model.trainingTime, "Training not yet complete");
        require(model.performanceScore == 0, "Training already completed");
        
        // Generate pseudo-random performance score based on training cost and time
        uint256 performanceScore = _generatePerformanceScore(
            _modelId,
            model.trainingCost,
            block.timestamp
        );
        
        model.performanceScore = performanceScore;
        
        // Update player's best score if this is better
        if (performanceScore > players[msg.sender].bestScore) {
            players[msg.sender].bestScore = performanceScore;
        }
        
        emit TrainingCompleted(_modelId, performanceScore);
    }
    
    /**
     * @dev Claim rewards based on model performance
     * @param _modelId The ID of the model to claim rewards for
     */
    function claimRewards(uint256 _modelId) external nonReentrant {
        require(_modelId < nextModelId, "Model does not exist");
        AIModel storage model = aiModels[_modelId];
        require(model.trainer == msg.sender, "Not the model trainer");
        require(model.performanceScore > 0, "Training not completed");
        require(model.isActive, "Rewards already claimed");
        
        model.isActive = false;
        
        // Calculate reward based on performance score
        uint256 reward = _calculateReward(model.performanceScore, model.trainingCost);
        
        if (reward > 0 && reward <= address(this).balance) {
            players[msg.sender].totalEarnings += reward;
            totalPrizePool -= reward;
            
            payable(msg.sender).transfer(reward);
            emit RewardClaimed(msg.sender, reward);
        }
    }
    
    /**
     * @dev Generate performance score based on training parameters
     */
    function _generatePerformanceScore(
        uint256 _modelId,
        uint256 _trainingCost,
        uint256 _timestamp
    ) private view returns (uint256) {
        uint256 randomSeed = uint256(
            keccak256(abi.encodePacked(
                _modelId,
                _trainingCost,
                _timestamp,
                block.prevrandao,
                msg.sender
            ))
        );
        
        // Base score influenced by training cost (more cost = higher potential)
        uint256 baseScore = (_trainingCost * 100) / BASE_TRAINING_COST;
        
        // Add randomness (50-150% of base score)
        uint256 performanceScore = (baseScore * (50 + (randomSeed % 101))) / 100;
        
        // Cap at 1000 for game balance
        return performanceScore > 1000 ? 1000 : performanceScore;
    }
    
    /**
     * @dev Calculate reward based on performance score
     */
    function _calculateReward(uint256 _performanceScore, uint256 _trainingCost) private pure returns (uint256) {
        if (_performanceScore < 50) return 0;
        
        // Base reward is training cost back, bonus for high performance
        uint256 baseReward = _trainingCost;
        uint256 bonusMultiplier = _performanceScore > 500 ? (_performanceScore - 500) / 100 : 0;
        
        return baseReward + (baseReward * bonusMultiplier) / 10;
    }
    
    // View functions
    function getPlayerModels(address _player) external view returns (uint256[] memory) {
        return playerModels[_player];
    }
    
    function getModelDetails(uint256 _modelId) external view returns (AIModel memory) {
        require(_modelId < nextModelId, "Model does not exist");
        return aiModels[_modelId];
    }
    
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    // Owner functions
    function withdrawFees() external onlyOwner {
        uint256 fees = address(this).balance - totalPrizePool;
        require(fees > 0, "No fees to withdraw");
        payable(owner()).transfer(fees);
    }
    
    function emergencyWithdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
