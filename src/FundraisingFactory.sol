// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {FundraisingProject} from "src/FundraisingProject.sol";
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract FundraisingFactory is Ownable {
    address public usdtContract;

    address [] public projectList;

    event ProjectCreated(
        address indexed projectAddress,
        address indexed projectOwner,
        uint256 targetAmount,
        uint256 deadline
    );

    constructor(address _usdtContract) Ownable(msg.sender){
        usdtContract = _usdtContract;
    }

    function createNewFundraisingProject(
        address _projectOwner,
        uint256 _targetAmount, 
        uint256 _durationInDays
    ) external {
        require(_projectOwner != address(0), "Factory: Project owner cannot be the zero address");
        require(_targetAmount > 0, "Factory: Target amount must be greater than zero");
        require(_durationInDays > 0, "Factory: Duration must be greater than zero");

        FundraisingProject newProject = new FundraisingProject(
            _projectOwner,
            _targetAmount,
            _durationInDays,
            usdtContract
        );
        address newProjectAddress = address(newProject);
        projectList.push(newProjectAddress);

        emit ProjectCreated(
            newProjectAddress,
            _projectOwner,
            _targetAmount,
            newProject.getDeadline() // Asumsi ada fungsi getDeadline() di FundraisingProject
        );
    }

    function getAllProjects() public view returns (address[] memory){
        return projectList;
    }

    function projectCount() public view returns (uint256) {
        return projectList.length;
    }
}