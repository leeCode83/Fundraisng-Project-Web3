// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract FundraisingProject is Ownable{
    using SafeERC20 for IERC20;

    IERC20 public usdtToken;

    //Global variable
    address public immutable projectOwner;
    uint256 public targetAmount;
    uint256 public immutable deadline;
    uint256 public amountRaised;
    bool public fundWidthdrawn = false;

    mapping(address => uint256) public contributors;

    //Modifier
    modifier onlyProjectOwner(){
        require(msg.sender == projectOwner, "Only owner can call this function");
        _;
    }

    modifier isActived(){
        require(block.timestamp < deadline, "Fundraising has ended.");
        _;
    }

    modifier hasEnded(){
        require(block.timestamp >= deadline, "Fundraising still ongoing.");
        _;
    }

    //events
    event Contribution(address indexed contributor, uint256 amout);
    event FundWidthdrawn(address indexed owner, uint256 amount);

    constructor(
        address _projectOwner,
        uint256 _targetAmount, 
        uint256 _durationInDays,
        address _usdtContractAddress
        ) Ownable(msg.sender){
            projectOwner = _projectOwner;
            targetAmount = _targetAmount;
            deadline = block.timestamp + (_durationInDays * 1 days);
            usdtToken = IERC20(_usdtContractAddress);
    }

    function contribute(uint256 _usdtAmount) external isActived(){
        require(_usdtAmount > 0, "USDT amount must be greater than 0.");

        // The allowance check is still a good practice for a clearer error message.
        uint256 approvedAmount = usdtToken.allowance(msg.sender, address(this));
        require(approvedAmount >= _usdtAmount, "Insufficient allowance. Please approve first.");

        // Use SafeERC20 to handle the transfer safely. It will revert on failure.
        usdtToken.safeTransferFrom(msg.sender, address(this), _usdtAmount);

        contributors[msg.sender] += _usdtAmount;
        amountRaised += _usdtAmount;
        emit Contribution(msg.sender, _usdtAmount);
    }

    function withdrawFunding() external onlyProjectOwner() hasEnded(){
        require(amountRaised > 0, "There is no USDT to widthdraw");
        fundWidthdrawn = true;
        usdtToken.safeTransfer(projectOwner, amountRaised);
        emit FundWidthdrawn(projectOwner, amountRaised);
    }

    function getDeadline() public view returns (uint256){
        return block.timestamp + deadline * 1 days;
    }

    function checkTimeRemaining() public view returns (uint256) {
        if(block.timestamp >= deadline){
            return 0;
        }
        return deadline - block.timestamp;
    }
}

