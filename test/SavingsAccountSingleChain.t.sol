// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/SavingsAccountSingleChain.sol";

contract SavingsAccountTest is Test {
    SavingsAccount pwdDeposits;

    function setUp() public {
        pwdDeposits = new SavingsAccount();
    }

    function testNative() public {
        uint256 amount = 100;

        pwdDeposits.depositNative{value: amount}();

        uint256 balance = pwdDeposits.getDeposit(address(0));
        assertTrue(balance == amount);

        uint256 preBalance = address(this).balance;
        pwdDeposits.withdrawNative(amount / 2);
        uint256 postBalance = address(this).balance;
        assertTrue(postBalance - preBalance == amount / 2);

        balance = pwdDeposits.getDeposit(address(0));
        assertTrue(balance == amount / 2);

        pwdDeposits.depositNative{value: amount}();
        balance = pwdDeposits.getDeposit(address(0));
        assertTrue(balance == amount + amount / 2);

        preBalance = address(this).balance;
        pwdDeposits.withdrawNative();
        postBalance = address(this).balance;
        assertTrue(postBalance - preBalance == amount + amount / 2);
    }

    receive() external payable {}
}
