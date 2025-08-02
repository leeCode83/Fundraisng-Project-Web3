// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract MyUSDT is ERC20 {
    constructor() ERC20("My Tether Token", "MYUSDT") {
        _mint(msg.sender, 1000 * 10**6); // Mint 1000 MYUSDT ke deployer (1 MYUSDT = 1.000.000 unit)
    }
}