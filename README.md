# TransportDApp

TransportDApp is a decentralized application (dApp) that enables users to book rides with registered drivers and manage ride transactions on the Ethereum blockchain. Built on Solidity with OpenZeppelin’s industry-standard contracts for access control and security, TransportDApp handles essential ride functionalities—from driver and user registration to ride booking, completion, and cancellation.

## Table of Contents

- [TransportDApp](#transportdapp)
  - [Table of Contents](#table-of-contents)
  - [Overview](#overview)
  - [Features](#features)
  - [Technologies Used](#technologies-used)
  - [Installation](#installation)
  - [Usage](#usage)
  - [Testing](#testing)
  - [Deployment](#deployment)
  - [Project Structure](#project-structure)
  - [Contributing](#contributing)
  - [Contact](#contact)

## Overview

TransportDApp leverages the power of decentralized blockchain technology to facilitate secure, trustless ride-booking services. In this smart contract, drivers can register and add destinations with specific fares, while users can register, book rides with a selected driver, complete rides to release escrowed funds, or cancel rides and receive refunds after a deduction. The contract incorporates robust security by adopting OpenZeppelin’s Ownable and ReentrancyGuard, reducing risks of unauthorized access and reentrancy attacks.

## Features

- **User & Driver Registration:**  
  - Users register to book rides.  
  - Drivers register and set up payable addresses.
  
- **Destination Management:**  
  - Registered drivers can add destinations with associated fares (in ether).  
  - Ensure fare validations (only non-zero fares accepted).

- **Ride Booking and Payment Escrow:**  
  - Users book rides by sending the correct fare amount.  
  - The fare is split: 10% is transferred to the driver immediately, and 90% is held in escrow.
  
- **Ride Completion:**  
  - Either party (user or driver) can mark a ride as complete, releasing the escrowed funds.
  
- **Ride Cancellation:**  
  - Users can cancel rides prior to completion.  
  - Cancellation fees are applied, and the remaining funds are refunded to the user.

- **Secure Access Control & Reentrancy Protection:**  
  - Uses OpenZeppelin’s Ownable for secure administrative control.
  - Utilizes ReentrancyGuard to prevent reentrancy attacks.

## Technologies Used

- **Solidity** – Smart contract language.
- **OpenZeppelin Contracts** – Provides audited implementations of common patterns (Ownable, ReentrancyGuard).
- **Foundry/Forge** – Ethereum development framework for testing, deploying, and analyzing smart contracts.
- **Anvil** – Local Ethereum node provided by Foundry for development and testing.

## Installation

1. **Clone the Repository:**
   ```bash
   git clone https://github.com/rocknwa/Transport-Dapp
   cd Transport-Dapp
   ```

2. **Install Dependencies:**
   Install OpenZeppelin contracts:
   ```bash
   forge install openzeppelin/openzeppelin-contracts@v4.8.3 --no-commit
   ```
   If you haven’t already, install Foundry using the Foundry installation instructions from the [Foundry Book](https://book.getfoundry.sh/getting-started/installation).


3. **Compile the Contracts:**
   ```bash
   forge build
   ```

## Usage

After compiling, you can interact with the deployed TransportDApp contract using your preferred Ethereum client (e.g., Hardhat, Remix) or via Foundry scripts. The functions include:

- **registerUser()** – Registers the caller as a user.
- **registerDriver()** – Registers the caller as a driver.
- **addDestination(string _location, uint256 _fareInEther)** – Lets a registered driver add a ride destination.
- **bookRide(address driverAddress, uint256 destinationId)** – Allows a registered user to book a ride by sending the correct fare.
- **completeRide(uint256 rideId)** – Completes a ride and releases escrowed funds to the driver.
- **cancelRide(uint256 rideId)** – Cancels a ride and refunds the user after deducting a cancellation fee.

## Testing

TransportDApp is thoroughly tested using Foundry’s Forge framework. To run the tests:
  
```bash
forge test
```

For coverage:
```
  forge coverage
```

Or for full coverage analysis:
  
```bash
forge coverage --report lcov && genhtml lcov.info --branch-coverage --output-dir coverage
```

This will generate a detailed HTML report in the `coverage/` directory.

## Deployment

You can deploy the TransportDApp contract using the provided Foundry deployment script located in the `script/` directory. To deploy:

```bash
forge script script/TransportDapp.s.sol --broadcast --verify
```


## Project Structure

```
TransportDApp/
├── src/
│   └── TransportDapp.sol       # Main contract implementing the ride-booking logic
├── script/
│   └── TransportDapp.s.sol     # Deployment script using Foundry’s Script module
├── test/
│   └── TransportDApp.t.sol     # Comprehensive test suite covering all functionalities
├── remappings.txt              # Remappings for dependencies
├── foundry.toml                # Foundry project configuration              
└── README.md                   # Project documentation
```

## Contributing

Contributions are welcome! Please open an issue or submit a pull request for any improvements, optimizations, or bug fixes. Follow the coding standards used in this repository to maintain consistency.


## Contact

For questions or further information, please reach out to [Email](anitherock44@gmail.com) or visit [Tech_Scorpion](https://t.me/Tech_Scorpion).