// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/PasswordDepositsSingleChain.sol";

contract PasswordDepositSingleChainTest is Test {
    PasswordDepositsSingleChain pwdDeposits;

    function setUp() public {
        pwdDeposits = new PasswordDepositsSingleChain();
    }

    function testDepositNative() public {
        bytes32 password = "password";
        uint256 amount = 100;
        pwdDeposits.depositNative{value: amount}(password);
        (bool found, uint256 amt, address token) = pwdDeposits.getDeposit(
            password
        );
        assertTrue(found);
        assertTrue(amt == amount);
        assertTrue(token == address(0));
    }

    function testClaimNative() public {
        string memory password = "password";
        bytes32 passwordHash = keccak256(abi.encodePacked(password));
        uint256 amount = 100;
        pwdDeposits.depositNative{value: amount}(passwordHash);
        (bool found, uint256 amt, address token) = pwdDeposits.getDeposit(
            passwordHash
        );
        assertTrue(found);
        assertTrue(amt == amount);
        assertTrue(token == address(0));

        uint256 preBalance = address(this).balance;
        console.log("preBalance", preBalance);
        pwdDeposits.claim(password);
        uint256 postBalance = address(this).balance;
        console.log("postBalance", postBalance);

        assertTrue(postBalance - preBalance == amount);

        (found, amt, token) = pwdDeposits.getDeposit(passwordHash);
        assertTrue(!found);
        assertTrue(amt == 0);
        assertTrue(token == address(0));
    }
}
