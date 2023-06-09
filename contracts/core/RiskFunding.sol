// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;

import "../libraries/SafeMath.sol";
import "../interfaces/IManager.sol";
import "../interfaces/IERC20.sol";
import "../libraries/TransferHelper.sol";

contract RiskFunding {
    using SafeMath for uint256;

    address public manager;
    address public rewardAsset;
    uint256 public executeLiquidateFee;//fee to price provider by liquidator
    //liquidator => fee
    mapping(address => uint256)public liquidatorExecutedFees;

    event SetRewardAsset(address feeAsset);
    event SetExecuteLiquidateFee(uint256 _fee);

    constructor(address _manager) {
        require(_manager != address(0), "RiskFunding: invalid manager");
        manager = _manager;
    }

    modifier onlyController() {
        require(IManager(manager).checkController(msg.sender), "RiskFunding: Must be controller");
        _;
    }

    modifier onlyRouter(){
        require(IManager(manager).checkRouter(msg.sender), "RiskFunding: no permission!");
        _;
    }

    function setRewardAsset(address _rewardAsset) external onlyController {
        require(_rewardAsset != address(0), "RiskFunding: invalid reward asset");
        rewardAsset = _rewardAsset;
        emit SetRewardAsset(_rewardAsset);
    }

    function setExecuteLiquidateFee(uint256 _fee) external onlyController {
        executeLiquidateFee = _fee;
        emit SetExecuteLiquidateFee(_fee);
    }

    function updateLiquidatorExecutedFee(address _liquidator) external onlyRouter {
        liquidatorExecutedFees[_liquidator] = liquidatorExecutedFees[_liquidator].add(executeLiquidateFee);
    }

    function useRiskFunding(address token, address to) external {
        require(IManager(manager).checkTreasurer(msg.sender), "RiskFunding: no permission!");
        TransferHelper.safeTransfer(token, to, IERC20(token).balanceOf(address(this)));
    }

    function collectExecutedFee() external {
        require(liquidatorExecutedFees[msg.sender] > 0, "RiskFunding: no fee to collect");
        TransferHelper.safeTransfer(rewardAsset, msg.sender, liquidatorExecutedFees[msg.sender]);
        liquidatorExecutedFees[msg.sender] = 0;
    }
}
