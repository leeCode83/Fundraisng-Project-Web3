// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {FundraisingFactory} from "../src/FundraisingFactory.sol";
import {FundraisingProject} from "../src/FundraisingProject.sol";
import {MyUSDT} from "../src/MyUSDT.sol";

contract FundraisingTest is Test {
    FundraisingFactory public factory;
    FundraisingProject public project;
    MyUSDT public usdt;

    address public creator = address(1);
    address public contributor = address(2);
    uint256 public goalAmount = 1000 * 1e18;
    uint32 public duration = 30; // 30 days

    function setUp() public {
        usdt = new MyUSDT();
        factory = new FundraisingFactory(address(usdt), 0.5);

        // Mint some USDT for the contributor
        usdt.mint(contributor, 1000 * 1e18);

        // Create a new project
        vm.startPrank(creator);
        factory.createProject("Test Project", "Test Description", goalAmount, duration);
        address projectAddress = factory.allProjects(0);
        project = FundraisingProject(projectAddress);
        vm.stopPrank();
    }

    function test_Contribute() public {
        vm.startPrank(contributor);
        usdt.approve(address(project), 500 * 1e18);
        project.contribute(500 * 1e18);
        vm.stopPrank();

        assertEq(project.totalContributions(), 500 * 1e18, "Contribution amount should be 500 USDT");
        assertEq(usdt.balanceOf(address(project)), 500 * 1e18, "Project USDT balance should be 500");
    }

    function test_WithdrawFunds_GoalReached() public {
        // Contributor contributes enough to meet the goal
        vm.startPrank(contributor);
        usdt.approve(address(project), goalAmount);
        project.contribute(goalAmount);
        vm.stopPrank();

        // Fast forward time to after the deadline
        vm.warp(block.timestamp + duration * 1 days + 1);

        uint256 creatorInitialBalance = usdt.balanceOf(creator);

        // Creator withdraws the funds
        vm.startPrank(creator);
        project.withdrawFunds();
        vm.stopPrank();

        assertEq(usdt.balanceOf(creator), creatorInitialBalance + goalAmount, "Creator should receive the funds");
    }

    function test_Refund_GoalNotReached() public {
        // Contributor contributes, but not enough to meet the goal
        uint256 contributionAmount = 100 * 1e18;
        vm.startPrank(contributor);
        usdt.approve(address(project), contributionAmount);
        project.contribute(contributionAmount);
        vm.stopPrank();

        // Fast forward time to after the deadline
        vm.warp(block.timestamp + duration * 1 days + 1);

        uint256 contributorInitialBalance = usdt.balanceOf(contributor);

        // Contributor gets a refund
        vm.startPrank(contributor);
        project.refund();
        vm.stopPrank();

        assertEq(usdt.balanceOf(contributor), contributorInitialBalance + contributionAmount, "Contributor should be refunded");
    }

    function test_Fail_WithdrawBeforeDeadline() public {
        vm.startPrank(contributor);
        usdt.approve(address(project), goalAmount);
        project.contribute(goalAmount);
        vm.stopPrank();

        // Try to withdraw before deadline (should fail)
        vm.startPrank(creator);
        vm.expectRevert("Project deadline has not passed yet");
        project.withdrawFunds();
        vm.stopPrank();
    }

    function test_Fail_ContributeAfterDeadline() public {
        // Fast forward time to after the deadline
        vm.warp(block.timestamp + duration * 1 days + 1);

        vm.startPrank(contributor);
        usdt.approve(address(project), 100 * 1e18);
        vm.expectRevert("Project has already ended");
        project.contribute(100 * 1e18);
        vm.stopPrank();
    }
}
