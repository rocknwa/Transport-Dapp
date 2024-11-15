// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract TransportDApp is Ownable, ReentrancyGuard {
    struct Destination {
        string location;
        uint256 fare; // Fare in ether
        bool isAvailable;
    }

    struct Driver {
        address payable driverAddress;
        uint256 destinationCount;
    }

    struct Ride {
        address user;
        address driver;
        string destination;
        uint256 fare; // Fare in ether
        bool isCompleted;
        bool isCancelled;
    }

    mapping(address => Driver) private drivers;
    mapping(uint256 => Destination) private destinations;
    mapping(uint256 => Ride) private rides;
    uint256 private destinationCount;
    uint256 private rideCount;

    mapping(address => bool) public isDriver;
    mapping(address => bool) public isUser;

    uint256 public constant DRIVER_PERCENTAGE = 10;
    uint256 public constant ESCROW_PERCENTAGE = 90;
    uint256 public constant CANCELLATION_FEE_PERCENTAGE = 5;

    event DestinationAdded(address indexed driver, uint256 destinationId, string location, uint256 fare);
    event RideBooked(uint256 rideId, address indexed user, address indexed driver, string destination, uint256 fare);
    event RideCompleted(uint256 rideId, address indexed driver, address indexed user);
    event RideCancelled(uint256 rideId, address indexed driver, address indexed user, uint256 refundAmount, string reason);

    /**
     * @dev Registers the caller as a user.
     * This function sets the caller's address as a user if they are not already registered.
     */
    function registerUser() public {
        require(!isUser[msg.sender], "Already registered as a user");
        isUser[msg.sender] = true;
    }

    /**
     * @dev Registers the caller as a driver.
     * This function sets the caller's address as a driver if they are not already registered,
     * and assigns their address as a payable driver address.
     */
    function registerDriver() public {
        require(!isDriver[msg.sender], "Already registered as a driver");
        isDriver[msg.sender] = true;
        drivers[msg.sender].driverAddress = payable(msg.sender);
    }

    modifier onlyDriver() {
        require(isDriver[msg.sender], "Not a registered driver");
        _;
    }

    modifier onlyUser() {
        require(isUser[msg.sender], "Not a registered user");
        _;
    }

    /**
     * @dev Allows a registered driver to add a destination.
     * @param _location The location of the destination.
     * @param _fareInEther The fare amount for this destination, in ether.
     * This function only works for registered drivers and saves the new destination in the contract.
     */
    function addDestination(string memory _location, uint256 _fareInEther) public onlyDriver {
        require(_fareInEther > 0, "Fare must be greater than zero");

        destinations[destinationCount] = Destination({
            location: _location,
            fare: _fareInEther,
            isAvailable: true
        });

        emit DestinationAdded(msg.sender, destinationCount, _location, _fareInEther);
        destinationCount++;
    }

    /**
     * @dev Allows a user to book a ride with a specified driver to a destination.
     * @param driverAddress The address of the driver.
     * @param destinationId The ID of the destination.
     * This function requires the correct fare in ether and pays the driver 10% upfront while keeping
     * 90% in escrow. It creates a new ride record and emits a RideBooked event.
     */
    function bookRide(address driverAddress, uint256 destinationId) public payable onlyUser nonReentrant {
        Destination storage destination = destinations[destinationId];
        Driver storage driver = drivers[driverAddress];

        require(destination.isAvailable, "Destination is not available");
        require(msg.value == destination.fare * 1 ether, "Incorrect fare amount");

        uint256 driverAmount = (msg.value * DRIVER_PERCENTAGE) / 100;
        uint256 escrowAmount = msg.value - driverAmount;

        (bool success, ) = driver.driverAddress.call{value: driverAmount}("");
        require(success, "Transfer to driver failed");

        rides[rideCount] = Ride({
            user: msg.sender,
            driver: driverAddress,
            destination: destination.location,
            fare: escrowAmount,
            isCompleted: false,
            isCancelled: false
        });

        emit RideBooked(rideCount, msg.sender, driverAddress, destination.location, destination.fare);
        rideCount++;
    }

    /**
     * @dev Allows the user or driver to complete the ride and transfer the remaining escrowed fare to the driver.
     * @param rideId The ID of the ride to be completed.
     * This function can be called by either the user or the driver involved in the ride. It marks
     * the ride as completed and transfers the escrowed funds to the driver.
     */
    function completeRide(uint256 rideId) public nonReentrant {
        Ride storage ride = rides[rideId];

        require(msg.sender == ride.driver || msg.sender == ride.user, "Only the user or driver can complete the ride");
        require(!ride.isCompleted, "Ride is already completed");
        require(!ride.isCancelled, "Ride has been cancelled");

        ride.isCompleted = true;

        (bool success, ) = payable(ride.driver).call{value: ride.fare}("");
        require(success, "Transfer to driver failed");

        emit RideCompleted(rideId, ride.driver, ride.user);
    }

    /**
     * @dev Allows a user to cancel a ride and receive a refund after a cancellation fee deduction.
     * @param rideId The ID of the ride to be cancelled.
     * This function can only be called by the user who booked the ride. It deducts a cancellation fee,
     * refunds the remaining amount, and marks the ride as cancelled.
     */
    function cancelRide(uint256 rideId) public onlyUser nonReentrant {
        Ride storage ride = rides[rideId];

        require(msg.sender == ride.user, "Only the user can cancel");
        require(!ride.isCompleted, "Ride is already completed");
        require(!ride.isCancelled, "Ride is already cancelled");

        ride.isCancelled = true;

        uint256 cancellationFee = (ride.fare * CANCELLATION_FEE_PERCENTAGE) / 100;
        uint256 refundAmount = ride.fare - cancellationFee;

        require(address(this).balance >= refundAmount, "Insufficient contract balance for refund");

        (bool success, ) = payable(ride.user).call{value: refundAmount}("");
        require(success, "Refund transfer to user failed");

        emit RideCancelled(rideId, ride.driver, ride.user, refundAmount, "User cancelled the ride");
    }
}
