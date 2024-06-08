```markdown
# Gift Coin Smart Contract

## Overview

This repository contains the implementation of the Gift Coin (GFT) smart contract on the Sui blockchain. The Gift Coin is designed for gifting friends and family, allowing users to mint, burn, and transfer tokens in a secure and decentralized manner.

## Features

- **Minting**: Authorized managers can mint new Gift Coins.
- **Burning**: Authorized managers can burn existing Gift Coins.
- **Transferring**: Users can transfer Gift Coins to others.
- **Balance Management**: Query and update balances of accounts.
- **Administrative Control**: Special administrative capabilities for managing authorized minters and burning tokens.

## Installation

To deploy and interact with this smart contract, follow these steps:

1. **Clone the repository:**
   ```bash
   git clone https://github.com/boyw5785/gift-coin.git
   cd gift-coin
   ```

2. **Install dependencies:**
   Ensure you have the Sui Move CLI installed and set up.

3. **Compile the smart contract:**
   ```bash
   sui move build
   ```

4. **Deploy the smart contract:**
   ```bash
   sui move publish --gas-budget 3000
   ```

## Usage

### Initialization

Initialize the token by calling the `init` function. This sets up the initial state, including the total supply, balances, and authorized managers.

### Minting Tokens

Authorized managers can mint new tokens using the `mint` function. This function checks the caller's authorization and updates the recipient's balance.

### Burning Tokens

Authorized managers can burn tokens using the `burn` function. This function reduces the total supply and updates the recipient's balance accordingly.

### Transferring Tokens

Users can transfer tokens to others using the `transfer` function. This updates the balances of the sender and the recipient and performs the transfer.

### Balance Management

- **Get Balance**: Use the `get_balance` function to query the balance of a specific address.
- **Update Balance**: Use the `update_account_balance` function to adjust the balance of a specific address.

### Administrative Functions

- **Add Manager**: Use the `add_manager` function with `AdminCap` to add a new authorized manager.
- **Remove Manager**: Use the `remove_manager` function with `AdminCap` to remove an authorized manager.

## Testing

The contract includes functions for testing purposes:

- `init_for_testing`: Initializes the token for testing.
- `mint_for_testing`: Mints tokens for testing purposes.

Use the following command to run tests:
```bash
sui move test
```

## Contributing

Contributions are welcome! Please submit a pull request or open an issue to discuss any changes.

## License

This project is licensed under the MIT License. See the LICENSE file for details.

## Contact

For questions or support, please contact boyw5785@gmail.com.

```

This README provides an overview of the smart contract, instructions for installation, usage details, and other relevant information. You can adjust any sections as needed to better fit your project's specifics.
