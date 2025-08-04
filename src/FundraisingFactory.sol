// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {FundraisingProject} from "src/FundraisingProject.sol";
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract FundraisingFactory is Ownable {
    address public immutable usdtContract;
    uint256 public creationFee;

    address[] public projectList;

    event ProjectCreated(
        address indexed projectAddress,
        address indexed projectOwner,
        uint256 targetAmount,
        uint256 deadline
    );

    constructor(
        address _usdtContract,
        uint256 _initialFee
    ) Ownable(msg.sender) {
        usdtContract = _usdtContract;
        creationFee = _initialFee;
    }

    function setCreationFee(uint256 _newFee) external onlyOwner {
        creationFee = _newFee;
    }

    function createNewFundraisingProject(
        uint256 _targetAmount,
        uint256 _durationInDays
    ) external payable {
        require(msg.value == creationFee, "Factory: Incorrect creation fee");
        require(
            _targetAmount > 0,
            "Factory: Target amount must be greater than zero"
        );
        require(
            _durationInDays > 0,
            "Factory: Duration must be greater than zero"
        );

        FundraisingProject newProject = new FundraisingProject(
            msg.sender,
            _targetAmount,
            _durationInDays,
            usdtContract
        );

        address newProjectAddress = address(newProject);
        projectList.push(newProjectAddress);

        emit ProjectCreated(
            newProjectAddress,
            msg.sender,
            _targetAmount,
            newProject.getDeadline()
        );
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        require(success, "Factory: Transfer failed");
    }

    function getAllProjects() public view returns (address[] memory) {
        return projectList;
    }

    function projectCount() public view returns (uint256) {
        return projectList.length;
    }
}
