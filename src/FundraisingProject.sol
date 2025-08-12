// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract FundraisingProject is Ownable {
    using SafeERC20 for IERC20;

    IERC20 public usdtToken;

    //Global variable

    //Data project
    address public immutable projectOwner;
    uint256 public immutable deadline;
    uint256 public immutable targetAmount;

    //Data dan status project
    uint256 public amountRaised;
    bool public fundWithdrawn = false;
    bool public fundsRefunded = false;

    //Data contributor
    mapping(address => uint256) public contributors;
    address[] public contributorAddresses;
    uint256 public contributorsCount = 0;

    //Data untuk melakukan voting milestone withdraw
    uint256 public votePeriode;
    bool votingStart = false;
    mapping(uint8 => uint256) public percentageVoteAmount;
    mapping(address => bool) public voted;
    uint8 percentageWithdraw = 0;

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

    modifier isContributors() {
        require(
            contributors[msg.sender] > 0,
            "Only contributors who can vote."
        );
        _;
    }

    modifier alreadyVoted() {
        require(voted[msg.sender] == false, "You already voted.");
        _;
    }

    //events
    event Contribution(address indexed contributor, uint256 amout);
    event FundWidthdrawn(address indexed owner, uint256 amount);
    event Refund(address indexed contributor, uint256 amount);
    event Voting(address indexed voter, uint8 percentage);
    event PercentageDecided(uint8 percentage);

    constructor(
        address _projectOwner,
        uint256 _targetAmount,
        uint256 _durationInDays,
        address _usdtContractAddress
    ) Ownable(msg.sender) {
        projectOwner = _projectOwner;
        targetAmount = _targetAmount;
        deadline = block.timestamp + (_durationInDays * 1 days); //deadline dituliskan dalam satuan harian
        usdtToken = IERC20(_usdtContractAddress);
    }

    /*
        Fungsi untuk menyumbangkan USDT ke project.
        Memerlukan approve jumlah usdt yang akan disumbangkan dari calon penyumbang untuk project ini.
        Jumlah usdt yang diaaprove harus semua dengan yang ada di parameter _usdtAmount.
        Setelah transefer dari penyumbang ke contract selesai, address penyumbang akan dicatat.
        Fungsi hanya dapat dipanggil ketika project masih dalam periode aktif.
    */
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

    /*
        Function untuk menarik dana dari contract ke address pemilik projek.
        Function hanya dapat dipanggil ketika deadline funding project sudah berakhir.
        Penarikan hanya dapat dilakukan ketika ada usdt di dalam contract dan jumlahnya >= target dana yang ditetapkan.
        Setelah semua syarat terpenuhi, dana akan ditransfer dari contract ke address project owner
    */
    function withdrawFunding() external onlyProjectOwner hasEnded {
        require(amountRaised >= targetAmount, "Target not reached");
        require(amountRaised > 0, "There is no USDT to widthdraw");

        fundWithdrawn = true;

        usdtToken.safeTransfer(projectOwner, amountRaised);

        emit FundWidthdrawn(projectOwner, amountRaised);
    }

    /*
        Function untuk melaksanakan refund usdt yang telah terkumpul di dalam contract project.
        Function hanya dapat dipanggil jika dana yang terkumpulkan tidak mencapai target yang ditetapkan.
        Dana akan dikembalikan ke para penyumbang sesuai dengan jumlah yang mereka sumbangkan.
    */
    function refund() external hasEnded {
        require(
            amountRaised < targetAmount && amountRaised != 0,
            "Target has been reached"
        );
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

    function startVoting() external hasEnded {
        votePeriode = block.timestamp + 7 days;
        votingStart = true;
    }

    function vote(
        uint8 _votedPercentage
    ) external hasEnded isContributors alreadyVoted {
        require(votingStart == true, "Vote periode already done.");
        percentageVoteAmount[_votedPercentage] += 1;

        emit Voting(msg.sender, _votedPercentage);
    }

    function decideWithdrawPercentage() external {
        require(block.timestamp > votePeriode, "Vote periode still on going.");
        uint256 maxVoted = 0;
        for (uint8 i = 1; i <= 100; i++) {
            if (percentageVoteAmount[i] > maxVoted) {
                percentageWithdraw = i;
            }
        }

        emit PercentageDecided(percentageWithdraw);
    }

    function checkTimeRemaining() public view returns (uint256) {
        if (block.timestamp >= deadline) {
            return 0;
        }
        return deadline - block.timestamp;
    }

    //Getter Function untuk mengambil data dedaline, jumlah dana yang dikumpulkan, address project owner,
    //dan jumlah penumbang
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
