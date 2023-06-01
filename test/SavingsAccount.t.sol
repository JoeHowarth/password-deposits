// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/SavingsAccountNative.sol";
import "./MockWormholeRelayer.sol";
import "../src/interfaces/IWormholeRelayer.sol";

contract SavingsAccountTest is Test {
    SavingsAccountHub hub;
    SavingsAccountSpoke spoke;
    IWormholeRelayer relayer;

    uint16 constant targetChain = 4;

    function setUp() public {
        address _relayer = address(new MockWormholeRelayer());
        (bool success, ) = _relayer.call{value: 100e18}("");
        require(success, "failed to send ether to relayer");
        relayer = IWormholeRelayer(_relayer);
        hub = new SavingsAccountHub(_relayer);
        spoke = new SavingsAccountSpoke(_relayer, address(hub), targetChain);
    }

    function testNative() public {
        uint256 hubAmt = 1e18;

        (uint cost, ) = relayer.quoteEVMDeliveryPrice(
            targetChain,
            hubAmt,
            50_000
        );
        spoke.deposit{value: cost}(hubAmt);
        assertTrue(address(hub).balance == hubAmt);

        assertTrue(hub.deposits(address(this)) == hubAmt);

        (cost, ) = relayer.quoteEVMDeliveryPrice(targetChain, 0, 50_000);
        spoke.withdraw{value: cost}(hubAmt / 2);

        console.log(hub.deposits(address(this)));

        assertTrue(hub.deposits(address(this)) == hubAmt / 2);
    }

    receive() external payable {}
}
