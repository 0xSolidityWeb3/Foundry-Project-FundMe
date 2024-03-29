// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {Script} from "forge-std/Script.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test, Script {
    FundMe fundMe;
    uint256 constant SENDING_AMOUNT = 10e18;
    uint256 constant FAKE_ETH = 10 ether;
    address sendingAddress = makeAddr("USER");

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(sendingAddress, FAKE_ETH);
    }

    function testMinimumUsdIsFive() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public view {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsFour() public view {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWithNotEnoughEth() public {
        vm.expectRevert();
        fundMe.fund();
    }

    modifier funded() {
        vm.prank(sendingAddress);
        fundMe.fund{value: SENDING_AMOUNT}();
        _;
    }

    function testFundPassWithEnoughEth() public funded {
        uint256 amountFunded = fundMe.getAddressToFundedAmount(sendingAddress);
        assertEq(amountFunded, SENDING_AMOUNT);
    }

    function testFunderAddedToFundersArray() public funded {
        address funder = fundMe.getFunders(0);
        assertEq(funder, sendingAddress);
    }

    function testWithdrawByOnlyOwner() public funded {
        vm.expectRevert();
        vm.prank(sendingAddress);
        fundMe.withdrawLessGasFee();
    }

    function testWithdrawWithSingleFunder() public funded {
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingContractBalance = address(fundMe).balance;

        vm.prank(fundMe.getOwner());
        fundMe.withdrawLessGasFee();

        uint256 endingOnwerBalance = fundMe.getOwner().balance;
        uint256 endingContractBalance = address(fundMe).balance;

        assertEq(endingContractBalance, 0);
        assertEq(
            startingOwnerBalance + startingContractBalance,
            endingOnwerBalance
        );
    }

    function testWithdrawWithManyFunder() public {
        uint160 numberOfFunders = 10;
        uint160 startingIndex = 1;
        for (uint160 i = startingIndex; i < numberOfFunders; i++) {
            //vm.prank
            //vm.deal
            //address()
            hoax(address(i), SENDING_AMOUNT);
            fundMe.fund{value: SENDING_AMOUNT}();
            //fund it to the fundMe
        }
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingContractBalance = address(fundMe).balance;
        vm.startPrank(fundMe.getOwner());
        fundMe.withdrawLessGasFee();
        vm.stopPrank();

        assertEq(address(fundMe).balance, 0);
        assertEq(
            startingContractBalance + startingOwnerBalance,
            fundMe.getOwner().balance
        );
    }
}
