// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./interfaces/IWormholeRelayer.sol";
import "./interfaces/IWormholeReceiver.sol";
import "./interfaces/IERC20.sol";

enum Action {
    Deposit,
    Withdraw
}

struct Deposit {
    address depositor;
}

struct Withdraw {
    address depositor;
    uint256 amount;
}

struct WithdrawResponse {
    address depositor;
}

contract SavingsAccountHub is IWormholeReceiver {
    IWormholeRelayer public immutable wormholeRelayer;
    // address public immutable owner;

    // (depositor, token) => amount
    mapping(address => mapping(address => uint256)) deposits;
    // replay protection
    mapping(bytes32 => bool) public processedMessages;

    // mapping(uint16 => address) public spokes;

    constructor(address _wormholeRelayer) {
        // owner = msg.sender;
        wormholeRelayer = IWormholeRelayer(_wormholeRelayer);
    }

    // function registerSpoke(uint16 chainId, address spokeAddress) public {
    //     require(msg.sender == owner, "SavingsAccount: not owner");
    //     spokes[chainId] = spokeAddress;
    // }

    function receiveWormholeMessages(
        bytes memory payload,
        bytes[] memory, // additionalVaas
        bytes32 sourceAddress,
        uint16 sourceChain,
        bytes32 deliveryHash
    ) public payable override {
        address sender = fromWormholeFormat(sourceAddress);

        // replay protection
        require(
            processedMessages[deliveryHash] == false,
            "SavingsAccount: message already processed"
        );
        processedMessages[deliveryHash] == true;

        (Action action, bytes memory data) = abi.decode(
            payload,
            (Action, bytes)
        );
        if (action == Action.Deposit) {
            Deposit memory deposit = abi.decode(data, (Deposit));
            handleDeposit(deposit.depositor);
        } else if (action == Action.Withdraw) {
            Withdraw memory withdraw = abi.decode(data, (Withdraw));
            handleWithdraw(
                withdraw.amount,
                withdraw.depositor,
                sourceChain,
                sender
            );
        } else {
            revert("SavingsAccount: unknown action");
        }
    }

    function handleDeposit(address depositor) public payable {
        require(msg.value > 0, "SavingsAccount: amount is zero");
        deposits[depositor][address(0)] += msg.value;
    }

    function handleWithdraw(
        uint256 amount,
        address depositor,
        uint16 targetChain,
        address targetContract
    ) public payable {
        require(amount > 0, "SavingsAccount: amount is zero");

        (uint256 cost, ) = wormholeRelayer.quoteEVMDeliveryPrice(
            targetChain,
            amount,
            50_000
        );

        require(
            deposits[depositor][address(0)] >= cost,
            "SavingsAccount: insufficient balance"
        );
        deposits[depositor][address(0)] -= cost;

        wormholeRelayer.forwardPayloadToEvm(
            targetChain,
            targetContract,
            abi.encode(WithdrawResponse({depositor: depositor})),
            amount,
            50_000
        );
    }
}

contract SavingsAccountSpoke is IWormholeReceiver {
    IWormholeRelayer public immutable wormholeRelayer;
    address public immutable hub;
    uint16 public immutable hubChain;

    mapping(bytes32 => bool) public processedMessages;

    constructor(address _wormholeRelayer, address _hub, uint16 _hubChain) {
        wormholeRelayer = IWormholeRelayer(_wormholeRelayer);
        hub = _hub;
        hubChain = _hubChain;
    }

    function deposit(
        uint256 hubNativeAmt
    ) public payable returns (uint256 sequence) {
        (uint256 cost, ) = wormholeRelayer.quoteEVMDeliveryPrice(
            hubChain,
            hubNativeAmt,
            50_000
        );
        require(msg.value >= cost, "SavingsAccount: insufficient amount");
        sequence = wormholeRelayer.sendPayloadToEvm{value: cost}(
            hubChain,
            hub,
            abi.encode(
                Action.Deposit,
                abi.encode(Deposit({depositor: msg.sender}))
            ),
            hubNativeAmt,
            50_000
        );
        if (msg.value > cost) {
            (bool success, ) = msg.sender.call{value: msg.value - cost}("");
            require(success, "SavingsAccount: transfer failed");
        }
    }

    function receiveWormholeMessages(
        bytes memory payload,
        bytes[] memory, // additionalVaas
        bytes32, // sourceAddress in wormhole format
        uint16, // sourceChain
        bytes32 deliveryHash
    ) public payable override {
        address depositor = abi.decode(payload, (WithdrawResponse)).depositor;

        // replay protection
        require(
            processedMessages[deliveryHash] == false,
            "SavingsAccount: message already processed"
        );
        processedMessages[deliveryHash] == true;

        (bool success, ) = depositor.call{value: msg.value}("");
        require(success, "SavingsAccount: transfer failed");
    }
}

function fromWormholeFormat(
    bytes32 whFormatAddress
) pure returns (address) {
    if (uint256(whFormatAddress) >> 160 != 0)
        revert NotAnEvmAddress(whFormatAddress);
    return address(uint160(uint256(whFormatAddress)));
}
