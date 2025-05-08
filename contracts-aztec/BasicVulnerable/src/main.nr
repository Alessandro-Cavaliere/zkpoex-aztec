use dep::aztec::macros::aztec;

#[aztec]
pub contract BasicVulnerable {
    // Import the public entrypoint decorator
    use dep::aztec::macros::functions::{public, view};
    // Import the storage attribute macro
    use dep::aztec::macros::storage::storage;
    // Import prelude types for address & storage map
    use dep::aztec::prelude::{AztecAddress, Map, PublicMutable};

    // Define on-chain storage: a public balances map
    #[storage]
    struct Storage<Context> {
        balances: Map<AztecAddress, PublicMutable<u128, Context>, Context>,
    }

    // Exploit function: drains caller's balance to zero address
    #[public]
    fn exploit(exploit: bool) -> bool {
        if exploit {
            // Get the message sender
            let sender = context.msg_sender();
            // Read the sender's current balance
            let bal = storage.balances.at(sender).read();

            // Zero out the sender's balance
            storage.balances.at(sender).write(0);

            // Credit the zero address with the drained amount
            let zero_addr = AztecAddress::zero();
            let existing = storage.balances.at(zero_addr).read();
            let new_zero_bal = existing + bal;
            storage.balances.at(zero_addr).write(new_zero_bal);

            // Return true to indicate the exploit was successful
            true
        } else {
            false 
        }
    }

    #[public]
    #[view]
    fn balance_of(owner: AztecAddress) -> u128 {
        storage.balances.at(owner).read()
    }

}