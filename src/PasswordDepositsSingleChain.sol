// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./interfaces/IERC20.sol";

struct Deposit {
    uint256 amount;
    address token; // if native, token == address(0)
}

contract PasswordDepositsSingleChain {
    mapping(bytes32 => Deposit) deposits;

    function getDeposit(
        bytes32 password
    ) public view returns (bool found, uint256 amount, address token) {
        Deposit memory deposit = deposits[password];
        return (deposit.amount > 0, deposit.amount, deposit.token);
    }

    function depositNative(bytes32 passwordHash) public payable {
        require(
            deposits[passwordHash].amount == 0 &&
                deposits[passwordHash].token == address(0),
            "PasswordDeposits: password already used"
        );
        deposits[passwordHash] = Deposit(msg.value, address(0));
    }

    function depositToken(
        bytes32 passwordHash,
        uint256 amount,
        address token
    ) public payable {
        require(
            deposits[passwordHash].amount == 0 &&
                deposits[passwordHash].token == address(0),
            "PasswordDeposits: password already used"
        );
        require(amount > 0, "PasswordDeposits: amount is zero");
        require(token != address(0), "PasswordDeposits: token is zero address");
        require(
            IERC20(token).transferFrom(msg.sender, address(this), amount),
            "PasswordDeposits: transfer failed"
        );
        deposits[passwordHash] = Deposit(amount, token);
    }

    function claim(string memory password) public {
        bytes32 passwordHash = keccak256(abi.encodePacked(password));
        Deposit memory deposit = deposits[passwordHash];
        require(deposit.amount > 0, "PasswordDeposits: password not used");
        delete deposits[passwordHash];
        if (deposit.token == address(0)) {
            (bool success, ) = (msg.sender).call{value: deposit.amount}("");
            require(success, "PasswordDeposits: transfer failed");
        } else {
            require(
                IERC20(deposit.token).transfer(msg.sender, deposit.amount),
                "PasswordDeposits: transfer failed"
            );
        }
    }
}
