// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract FundraisingProject is Ownable {
    using SafeERC20 for IERC20;

    IERC20 public usdtToken;

    //Global variable
    address public immutable projectOwner;
    uint256 public immutable deadline;
    uint256 public immutable targetAmount;
    uint256 public amountRaised;
    bool public fundWithdrawn = false;
    bool public fundsRefunded = false;
    uint256 public contributorsCount = 0;

    mapping(address => uint256) public contributors;
    address[] public contributorAddresses;

    //Modifier
    modifier onlyProjectOwner() {
        require(
            msg.sender == projectOwner,
            "Only owner can call this function"
        );
        _;
    }

    modifier isActived() {
        require(block.timestamp < deadline, "Fundraising has ended.");
        _;
    }

    modifier hasEnded() {
        require(block.timestamp >= deadline, "Fundraising still ongoing.");
        _;
    }

    //events
    event Contribution(address indexed contributor, uint256 amout);
    event FundWidthdrawn(address indexed owner, uint256 amount);
    event Refund(address indexed contributor, uint256 amount);

    constructor(
        address _projectOwner,
        uint256 _targetAmount,
        uint256 _durationInDays,
        address _usdtContractAddress
    ) Ownable(msg.sender) {
        projectOwner = _projectOwner;
        targetAmount = _targetAmount;
        deadline = block.timestamp + (_durationInDays * 1 days);
        usdtToken = IERC20(_usdtContractAddress);
    }

    function contribute(uint256 _usdtAmount) external isActived {
        require(_usdtAmount > 0, "USDT amount must be greater than 0.");

        // Periksa apakah jumlah USDT yang diizinkan untuk ditransfer mencukupi _usdtAmount dari user
        uint256 approvedAmount = usdtToken.allowance(msg.sender, address(this));
        require(
            approvedAmount >= _usdtAmount,
            "Insufficient allowance. Please approve first."
        );

        usdtToken.safeTransferFrom(msg.sender, address(this), _usdtAmount);

        if (contributors[msg.sender] == 0) {
            contributorAddresses.push(msg.sender);
        }

        contributors[msg.sender] += _usdtAmount;
        amountRaised += _usdtAmount;
        contributorsCount += 1;
        emit Contribution(msg.sender, _usdtAmount);
    }

    function withdrawFunding() external onlyProjectOwner hasEnded {
        require(amountRaised >= targetAmount, "Target not reached");
        require(amountRaised > 0, "There is no USDT to widthdraw");

        fundWithdrawn = true;

        usdtToken.safeTransfer(projectOwner, amountRaised);

        emit FundWidthdrawn(projectOwner, amountRaised);
    }

    function refund() external hasEnded {
        require(amountRaised < targetAmount, "Target has been reached");
        require(!fundWithdrawn, "Funds have been withdrawn");
        require(!fundsRefunded, "Funds have already been refunded");

        for (uint i = 0; i < contributorAddresses.length; i++) {
            address contributor = contributorAddresses[i];
            uint256 amount = contributors[contributor];
            if (amount > 0) {
                usdtToken.safeTransfer(contributor, amount);
                emit Refund(contributor, amount);
            }
        }

        fundsRefunded = true;
    }

    function checkTimeRemaining() public view returns (uint256) {
        if (block.timestamp >= deadline) {
            return 0;
        }
        return deadline - block.timestamp;
    }

    //Getter Function
    function getDeadline() public view returns (uint256) {
        return deadline;
    }

    function getAmountRaised() public view returns (uint256) {
        return amountRaised;
    }

    function getProjectOwner() public view returns (address) {
        return projectOwner;
    }

    function getContributorsCount() public view returns (uint256) {
        return contributorsCount;
    }
}
