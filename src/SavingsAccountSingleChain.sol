// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./interfaces/IERC20.sol";

contract SavingsAccount {
    // (owner, token) => amount
    mapping(address => mapping(address => uint256)) deposits;

    function getDeposit(address token) public view returns (uint256 amount) {
        return deposits[msg.sender][token];
    }

    function depositNative() public payable {
        require(msg.value > 0, "PasswordDeposits: amount is zero");
        deposits[msg.sender][address(0)] += msg.value;
    }


    function withdrawNative() public {
        uint amount = deposits[msg.sender][address(0)];
        deposits[msg.sender][address(0)] = 0;

        (bool success, ) = (msg.sender).call{value: amount}("");
        require(success, "PasswordDeposits: transfer failed");
    }

    function withdrawNative(uint256 amount) public {
        require(amount > 0, "PasswordDeposits: amount is zero");
        require(
            deposits[msg.sender][address(0)] >= amount,
            "PasswordDeposits: insufficient balance"
        );
        deposits[msg.sender][address(0)] -= amount;
        (bool success, ) = (msg.sender).call{value: amount}("");
        require(success, "PasswordDeposits: transfer failed");
    }

    /*
     * ERC20 tokens
     */

    function depositToken(uint256 amount, address token) public payable {
        require(amount > 0, "PasswordDeposits: amount is zero");
        require(token != address(0), "PasswordDeposits: token is zero address");
        require(
            IERC20(token).transferFrom(msg.sender, address(this), amount),
            "PasswordDeposits: transfer failed"
        );
        deposits[msg.sender][token] += amount;
    }

    function withdrawToken(address token) public {
        uint256 amount = deposits[msg.sender][token];
        deposits[msg.sender][token] = 0;
        require(
            IERC20(token).transfer(msg.sender, amount),
            "PasswordDeposits: transfer failed"
        );
    }

    function withdrawToken(address token, uint256 amount) public {
        require(amount > 0, "PasswordDeposits: amount is zero");
        require(token != address(0), "PasswordDeposits: token is zero address");
        require(
            deposits[msg.sender][token] >= amount,
            "PasswordDeposits: insufficient balance"
        );
        deposits[msg.sender][token] -= amount;
        require(
            IERC20(token).transfer(msg.sender, amount),
            "PasswordDeposits: transfer failed"
        );
    }
}
