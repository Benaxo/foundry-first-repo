//SPDX-Licencese-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
import {Script} from "forge-std/Script.sol";

contract FundMeTest is Test{
    FundMe fundMe;

    address USER = makeAddr("user");
    address USER2 = makeAddr("user2");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

    receive() external payable {}

    function setUp() external {
        //fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testMinimumDollarIsFive() public view{
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public view{
        assertEq(fundMe.getOwner(), address(this));
    }

    function testPriceFeedVersionIsAccurate() public view{
        uint version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailedWithoutEnoughEth() public{
        vm.expectRevert(); //hey, the next line should revert!
        //assert(this tx fails/reverts)
        fundMe.fund(); // we send 0 value
    }

    function testFundUpdatesFundedDataStructure() public{
        vm.prank(USER); // the next tx will be sent by USER

        fundMe.fund{value: SEND_VALUE}();

        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);

    }

    function testAddsFunderToArrayOfFunders() public{
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        address funder = fundMe.getFunder(0);
        assertEq(USER, funder);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdrawByMe() public{
        vm.expectRevert();
        vm.prank(USER2);
        fundMe.withdraw();
    }

    function testOnlyOwnerCanWithdraw() public funded{
        
        vm.prank(USER);
        vm.expectRevert();
        fundMe.withdraw();
    }

    // function testWithdrawUpdateOwnerBalance() public {
    //     vm.prank(USER);
    //     fundMe.fund{value: SEND_VALUE}();
    //     fundMe.withdraw();

    //     assertEq(fundMe.getAddressToAmountFunded(USER), 0);
    // }

    function testWithdrawWithASingleFunder() public funded{
        //Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //Act
        // uint256 gasStart = gasleft();
        // vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        // uint256 gasEnd = gasleft();
        // uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;

        // console.log(gasUsed);

        //Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        //console.log("Ending Owner Balance: ",endingOwnerBalance);
        uint256 endingFundMeBalance = address(fundMe).balance;
        //console.log("Ending FundMe Balance: ",endingFundMeBalance);
        assertEq(endingFundMeBalance, 0);
        assertEq(startingOwnerBalance + startingFundMeBalance, endingOwnerBalance);
        //100 + 100, 200
    }

    function testWithdrawFromMultipleFunders() public funded {
        //Arrange
        uint256 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;

        for(uint160 i = startingFunderIndex; i < numberOfFunders; i++){
            
            hoax(address(i), SEND_VALUE); // a combination of vm.deal and vm.prank
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //Act
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        //Assert
        assert(address(fundMe).balance == 0);
        assert(fundMe.getOwner().balance == startingOwnerBalance + startingFundMeBalance);

    }

    function testWithdrawFromMultipleFundersCheaper() public funded {
        //Arrange
        uint256 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;

        for(uint160 i = startingFunderIndex; i < numberOfFunders; i++){
            
            hoax(address(i), SEND_VALUE); // a combination of vm.deal and vm.prank
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //Act
        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        //Assert
        assert(address(fundMe).balance == 0);
        assert(fundMe.getOwner().balance == startingOwnerBalance + startingFundMeBalance);

    }
}