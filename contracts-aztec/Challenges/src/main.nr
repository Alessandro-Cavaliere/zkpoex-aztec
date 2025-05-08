use dep::aztec::macros::aztec;

#[aztec]
pub contract Challenge {
    // Import the BasicVulnerable contract
    use dep::basic_vulnerable::BasicVulnerable;
    // Import the public entrypoint decorator
    use dep::aztec::macros::functions::{initializer, public, utility};
    // Import the storage attribute macro
    use dep::aztec::macros::storage::storage;
    // Import prelude types for address & storage map
    use dep::aztec::prelude::{AztecAddress, PublicMutable};

    #[storage]
    struct Storage<Context> {
        exploit_executed: PublicMutable<bool, Context>,
        pre_exploit_balance: PublicMutable<Field, Context>,
        /// Now holds the target vulnerable_contract address
        vulnerable_contract: PublicMutable<AztecAddress, Context>,
    }

    /// Constructor now takes the vulnerable_contract address
    #[public]
    #[initializer]
    fn constructor(vault_addr: AztecAddress) {
        // Initialize the storage for exploit executed
        storage.exploit_executed.write(false);
        // Set the initial balance to 1000 wei
        storage.pre_exploit_balance.write(Field::from(1000));
        // Store the vulnerable contract address
        storage.vulnerable_contract.write(vault_addr);
    }

    #[public]
    fn entry_point() {
        let vulnerable_contract = storage.vulnerable_contract.read();

        // Pre-exploit check
        let vulnerable_contract_balance_before = context.public_balance(vulnerable_contract);
        assert(vulnerable_contract_balance_before == storage.pre_exploit_balance.read());

        // Run the exploit on the vulnerable_contract
        exploit();

        // Post-exploit check
        let vault_balance_post = context.public_balance(vulnerable_contract);
        assert(vault_balance_post == 0);

        storage.exploit_executed.write(true);

        // Reward the exploiter
        let exploiter = context.msg_sender();
        let bal = context.public_balance(exploiter);
        context.transfer_public(exploiter, vulnerable_contract, bal);
    }

    #[public]
    fn exploit() {
        BasicVulnerable::at(storage.vulnerable_contract.read())
            .exploit(true)
            .call(&mut context);
    }

    #[utility]
    unconstrained fn get_pre_exploit_balance() -> Field {
        storage.pre_exploit_balance.read()
    }
}
