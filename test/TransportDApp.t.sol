// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/TransportDapp.sol";

contract TransportDAppTest is Test {
    TransportDApp public dapp;
    address public user = address(0x1);
    address public driver = address(0x2);
    address public other = address(0x3); // For invalid caller tests

    // Set up funds for testing ride payments
    function setUp() public {
        dapp = new TransportDApp();
        vm.deal(user, 10 ether);
        vm.deal(driver, 10 ether);
        vm.deal(other, 10 ether);
    }

    // ---------- Registration Tests ----------
    function testUserAndDriverRegistration() public {
        // Successful registration of user and driver
        vm.prank(user);
        dapp.registerUser();
        assertTrue(dapp.isUser(user));

        vm.prank(driver);
        dapp.registerDriver();
        assertTrue(dapp.isDriver(driver));
    }

    function testDuplicateUserRegistrationReverts() public {
        vm.prank(user);
        dapp.registerUser();
        vm.prank(user);
        vm.expectRevert(bytes("Already registered as a user"));
        dapp.registerUser();
    }

    function testDuplicateDriverRegistrationReverts() public {
        vm.prank(driver);
        dapp.registerDriver();
        vm.prank(driver);
        vm.expectRevert(bytes("Already registered as a driver"));
        dapp.registerDriver();
    }

    // ---------- Destination Tests ----------
    function testAddDestinationWithValidFare() public {
        // Register driver and add a valid destination
        vm.prank(driver);
        dapp.registerDriver();
        vm.prank(driver);
        dapp.addDestination("Central Park", 1);
        // No revert means pass.
    }

    function testAddDestinationWithZeroFareReverts() public {
        // Register driver and attempt to add destination with fare = 0
        vm.prank(driver);
        dapp.registerDriver();
        vm.prank(driver);
        vm.expectRevert(bytes("Fare must be greater than zero"));
        dapp.addDestination("Central Park", 0);
    }

    // ---------- Book Ride Tests ----------
    function testBookRideWithCorrectFare() public {
        // Set up by registering driver and user, add destination with fare 1.
        vm.prank(driver);
        dapp.registerDriver();
        vm.prank(driver);
        dapp.addDestination("Central Park", 1);

        vm.prank(user);
        dapp.registerUser();

        // Book ride with exact correct fare (1 ether)
        vm.prank(user);
        dapp.bookRide{value: 1 ether}(driver, 0);
    }

    function testBookRideWithIncorrectFareReverts() public {
        // Setup: register driver, add destination.
        vm.prank(driver);
        dapp.registerDriver();
        vm.prank(driver);
        dapp.addDestination("Central Park", 1);

        vm.prank(user);
        dapp.registerUser();
        
        // Provide an incorrect fare value (e.g., 0.5 ether instead of 1 ether)
        vm.prank(user);
        vm.expectRevert(bytes("Incorrect fare amount"));
        dapp.bookRide{value: 0.5 ether}(driver, 0);
    }

    function testBookRideByNonUserReverts() public {
        // Register driver and add destination
        vm.prank(driver);
        dapp.registerDriver();
        vm.prank(driver);
        dapp.addDestination("Central Park", 1);

        // Caller is not registered as a user.
        vm.prank(other);
        vm.expectRevert(bytes("Not a registered user"));
        dapp.bookRide{value: 1 ether}(driver, 0);
    }

    // ---------- Complete Ride Tests ----------
    function testCompleteRideSuccess() public {
        // Setup a ride: register driver and user, add destination, and book a ride.
        vm.prank(driver);
        dapp.registerDriver();
        vm.prank(driver);
        dapp.addDestination("Central Park", 1);
        vm.prank(user);
        dapp.registerUser();
        vm.prank(user);
        dapp.bookRide{value: 1 ether}(driver, 0);
        
        // Complete the ride successfully (can be called by either user or driver)
        vm.prank(user);
        dapp.completeRide(0);
    }

    function testCompleteRideByUnauthorizedCallerReverts() public {
        // Setup ride
        vm.prank(driver);
        dapp.registerDriver();
        vm.prank(driver);
        dapp.addDestination("Central Park", 1);
        vm.prank(user);
        dapp.registerUser();
        vm.prank(user);
        dapp.bookRide{value: 1 ether}(driver, 0);

        // Attempt to complete ride by an address not involved in the ride (other)
        vm.prank(other);
        vm.expectRevert(bytes("Only the user or driver can complete the ride"));
        dapp.completeRide(0);
    }

    function testCompleteRideAlreadyCompletedReverts() public {
        // Setup ride and complete it
        vm.prank(driver);
        dapp.registerDriver();
        vm.prank(driver);
        dapp.addDestination("Central Park", 1);
        vm.prank(user);
        dapp.registerUser();
        vm.prank(user);
        dapp.bookRide{value: 1 ether}(driver, 0);
        vm.prank(user);
        dapp.completeRide(0);

        // Attempt to complete it again should revert
        vm.prank(user);
        vm.expectRevert(bytes("Ride is already completed"));
        dapp.completeRide(0);
    }

    function testCompleteRideCancelledReverts() public {
        // Setup ride and cancel it
        vm.prank(driver);
        dapp.registerDriver();
        vm.prank(driver);
        dapp.addDestination("Central Park", 1);
        vm.prank(user);
        dapp.registerUser();
        vm.prank(user);
        dapp.bookRide{value: 1 ether}(driver, 0);
        vm.prank(user);
        dapp.cancelRide(0);

        // Attempt to complete a cancelled ride should revert
        vm.prank(user);
        vm.expectRevert(bytes("Ride has been cancelled"));
        dapp.completeRide(0);
    }

    // ---------- Cancel Ride Tests ----------
    function testCancelRideSuccess() public {
        // Setup ride
        vm.prank(driver);
        dapp.registerDriver();
        vm.prank(driver);
        dapp.addDestination("Central Park", 1);
        vm.prank(user);
        dapp.registerUser();
        vm.prank(user);
        dapp.bookRide{value: 1 ether}(driver, 0);

        // Cancel the ride successfully
        vm.prank(user);
        dapp.cancelRide(0);
    }

    function testCancelRideByNonUserReverts() public {
        // Setup ride
        vm.prank(driver);
        dapp.registerDriver();
        vm.prank(driver);
        dapp.addDestination("Central Park", 1);
        vm.prank(user);
        dapp.registerUser();
        vm.prank(user);
        dapp.bookRide{value: 1 ether}(driver, 0);

        // Attempt to cancel ride from an address other than the ride user
        vm.prank(other);
        vm.expectRevert(bytes("Not a registered user"));
        dapp.cancelRide(0);
    }

    function testCancelRideAlreadyCancelledReverts() public {
        // Setup ride and cancel it
        vm.prank(driver);
        dapp.registerDriver();
        vm.prank(driver);
        dapp.addDestination("Central Park", 1);
        vm.prank(user);
        dapp.registerUser();
        vm.prank(user);
        dapp.bookRide{value: 1 ether}(driver, 0);
        vm.prank(user);
        dapp.cancelRide(0);

        // Attempt to cancel the same ride again
        vm.prank(user);
        vm.expectRevert(bytes("Ride is already cancelled"));
        dapp.cancelRide(0);
    }

    function testCancelRideAfterCompletionReverts() public {
        // Setup ride and complete it
        vm.prank(driver);
        dapp.registerDriver();
        vm.prank(driver);
        dapp.addDestination("Central Park", 1);
        vm.prank(user);
        dapp.registerUser();
        vm.prank(user);
        dapp.bookRide{value: 1 ether}(driver, 0);
        vm.prank(user);
        dapp.completeRide(0);

        // Attempt to cancel a completed ride
        vm.prank(user);
        vm.expectRevert(bytes("Ride is already completed"));
        dapp.cancelRide(0);
    }
}
