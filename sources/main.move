module gift_coin::main {
    use std::option;

    use sui::object::{Self, UID, ID};
    use sui::tx_context::{TxContext};
    use sui::balance::{Self, Supply};
    use sui::transfer;
    use sui::coin::{Self, Coin};
    use sui::package::{Publisher};
    use sui::tx_context;
    use sui::vec_set::{Self, VecSet};
    use sui::table::{Self, Table};

    // Error code for unauthorized actions
    const ERROR_UNAUTHORIZED: u64 = 1;
    const ERROR_INSUFFICIENT_BALANCE: u64 = 2;
    const ERROR_BALANCE_OVERFLOW: u64 = 3;

    // A marker struct for the MAIN token type
    struct MAIN has drop {}

    // The main storage structure that keeps track of the token supply, balances, and authorized managers
    struct Storage has key {
        id: UID,                       // Unique identifier for the storage object
        supply: Supply<MAIN>,          // Total supply of the MAIN tokens
        balances: Table<address, u64>, // Table of addresses and their respective balances
        managers: VecSet<ID>           // Set of IDs that are authorized to mint and burn tokens
    }

    // An admin capability object that allows certain administrative actions
    struct AdminCap has key { id: UID }

    // Initializer function to create the token and set up the initial state
    fun init(witness: MAIN, ctx: &mut TxContext) {
        // Create the MAIN token with specified properties
        let (treasury, metadata) = coin::create_currency<MAIN>(
            witness,
            9, // Number of decimal places
            b"GFT", // Token symbol
            b"Gift Coin", // Token name
            b"Token for gifting friends and family", // Token description
            option::none(), // No icon
            ctx
        );

        // Convert the treasury_cap into a supply struct for minting/burning tokens
        let supply = coin::treasury_into_supply(treasury);

        // Share the storage object with the network
        transfer::share_object(
            Storage {
                id: object::new(ctx),
                supply,
                balances: table::new(ctx),
                managers: vec_set::empty()
            },
        );

        // Transfer the admin capability to the sender
        transfer::transfer(AdminCap { id: object::new(ctx) }, tx_context::sender(ctx));

        // Freeze the metadata object to prevent further updates
        transfer::public_freeze_object(metadata);
    }

    // Function to mint new tokens and transfer them to a recipient
    public fun mint(
        publisher: &Publisher,
        storage: &mut Storage,
        recipient: address,
        amount: u64,
        ctx: &mut TxContext
    ): Coin<MAIN> {
        // Check if the publisher is authorized to mint
        assert!(is_authorized(storage, object::id(publisher)), ERROR_UNAUTHORIZED);

        // Increase the recipient's balance by the specified amount
        increase_account_balance(storage, recipient, amount);

        // Mint new tokens and return them as a Coin object
        coin::from_balance(
            balance::increase_supply(&mut storage.supply, amount),
            ctx
        )
    }

    // Function to burn a specified amount of tokens from a recipient's balance
    public fun burn(
        publisher: &Publisher,
        storage: &mut Storage,
        recipient: address,
        asset: Coin<MAIN>
    ) {
        // Check if the publisher is authorized to burn
        assert!(is_authorized(storage, object::id(publisher)), ERROR_UNAUTHORIZED);

        // Decrease the recipient's balance by the value of the asset being burned
        decrease_account_balance(storage, recipient, coin::value(&asset));

        // Decrease the total supply of tokens
        balance::decrease_supply(&mut storage.supply, coin::into_balance(asset));
    }

    // Entry function to transfer tokens from the sender to a recipient
    entry public fun transfer(
        storage: &mut Storage,
        asset: Coin<MAIN>,
        recipient: address,
        ctx: &mut TxContext
    ) {
        // Decrease the sender's balance
        decrease_account_balance(storage, tx_context::sender(ctx), coin::value(&asset));

        // Increase the recipient's balance
        increase_account_balance(storage, recipient, coin::value(&asset));

        // Execute the transfer
        transfer::public_transfer(asset, recipient);
    }

    // Function to update the balance of a specific account
    public fun update_account_balance(
        publisher: &Publisher,
        storage: &mut Storage,
        recipient: address,
        amount: u64,
        is_increase: bool
    ) {
        // Check if the publisher is authorized to update balances
        assert!(is_authorized(storage, object::id(publisher)), ERROR_UNAUTHORIZED);

        // Update the balance accordingly
        if (is_increase) increase_account_balance(storage, recipient, amount)
        else decrease_account_balance(storage, recipient, amount)
    }

    // Entry function to add a manager ID to the list of authorized managers
    entry public fun add_manager(admin: &AdminCap, storage: &mut Storage, id: ID) {
        // Check if the admin is authorized
        assert!(is_authorized(storage, object::id(admin)), ERROR_UNAUTHORIZED);

        vec_set::insert(&mut storage.managers, id);
    }

    // Entry function to remove a manager ID from the list of authorized managers
    entry public fun remove_manager(admin: &AdminCap, storage: &mut Storage, id: ID) {
        // Check if the admin is authorized
        assert!(is_authorized(storage, object::id(admin)), ERROR_UNAUTHORIZED);

        vec_set::remove(&mut storage.managers, &id);
    }

    // Function to get the current supply of tokens
    public fun get_supply(storage: &Storage): u64 {
        balance::supply_value(&storage.supply)
    }

    // Function to get the balance of a specific address
    public fun get_balance(storage: &Storage, recipient: address): u64 {
        if (!table::contains(&storage.balances, recipient)) {
            return 0
        };
        *table::borrow(&storage.balances, recipient)
    }

    // Function to check if an ID is authorized as a manager
    public fun is_authorized(storage: &Storage, id: ID): bool {
        vec_set::contains(&storage.managers, &id)
    }

    // Helper function to increase the balance of an address
    fun increase_account_balance(storage: &mut Storage, recipient: address, amount: u64) {
        if (table::contains(&storage.balances, recipient)) {
            let existing_balance = table::remove(&mut storage.balances, recipient);
            let new_balance = existing_balance + amount;
            assert!(new_balance >= existing_balance, ERROR_BALANCE_OVERFLOW);
            table::add(&mut storage.balances, recipient, new_balance);
        } else {
            table::add(&mut storage.balances, recipient, amount);
        };
    }

    // Helper function to decrease the balance of an address
    fun decrease_account_balance(storage: &mut Storage, recipient: address, amount: u64) {
        let existing_balance = table::remove(&mut storage.balances, recipient);
        assert!(existing_balance >= amount, ERROR_INSUFFICIENT_BALANCE);
        table::add(&mut storage.balances, recipient, existing_balance - amount);
    }

    // Entry function for administrative minting, useful for testing purposes
    entry fun mint_admin(
        admin: &AdminCap,
        storage: &mut Storage,
        recipient: address,
        amount: u64,
        ctx: &mut TxContext
    ) {
        // Check if the admin is authorized
        assert!(is_authorized(storage, object::id(admin)), ERROR_UNAUTHORIZED);

        // Increase the recipient's balance by the specified amount
        increase_account_balance(storage, recipient, amount);

        // Mint new tokens and transfer them to the recipient
        let coin = coin::from_balance(
            balance::increase_supply(&mut storage.supply, amount),
            ctx
        );

        transfer::public_transfer(coin, recipient);
    }

    // Entry function for administrative burning, useful for testing purposes
    entry fun burn_admin(
        admin: &AdminCap,
        storage: &mut Storage,
        recipient: address,
        asset: Coin<MAIN>,
    ) {
        // Check if the admin is authorized
        assert!(is_authorized(storage, object::id(admin)), ERROR_UNAUTHORIZED);

        // Decrease the recipient's balance by the value of the asset being burned
        decrease_account_balance(storage, recipient, coin::value(&asset));

        // Decrease the total supply of tokens
        balance::decrease_supply(&mut storage.supply, coin::into_balance(asset));
    }

    // Function to initialize the token for testing purposes
    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(MAIN {}, ctx);
    }

    // Function to mint tokens for testing purposes
    #[test_only]
    public fun mint_for_testing(
        storage: &mut Storage,
        amount: u64,
        ctx: &mut TxContext
    ): Coin<MAIN> {
        coin::from_balance(balance::increase_supply(&mut storage.supply, amount), ctx)
    }
}
