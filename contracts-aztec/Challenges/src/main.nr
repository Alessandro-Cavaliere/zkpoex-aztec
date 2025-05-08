use dep::aztec::macros::aztec;

#[aztec]
pub contract Challenge {
    // Import the BasicVulnerable contract
    use dep::basic_vulnerable::BasicVulnerable;
    // Import the Attacker contract
    use dep::attacker::Attacker;
    // Import the public entrypoint decorator
    use dep::aztec::macros::functions::{initializer, public};
    // Import the storage attribute macro
    use dep::aztec::macros::storage::storage;
    // Import prelude types for address & storage map
    use dep::aztec::prelude::{AztecAddress, PublicMutable};

    #[storage]
    struct Storage<Context> {
        // Flag to indicate if the exploit has been executed
        exploit_executed: PublicMutable<bool, Context>,
        // The initial balance of the vulnerable contract
        pre_exploit_balance: PublicMutable<u128, Context>,
        /// The address of the vulnerable contract
        vulnerable_contract: PublicMutable<AztecAddress, Context>,
    }

    /// Constructor now takes the vulnerable_contract address
    #[public]
    #[initializer]
    fn constructor(attacker_addr: AztecAddress, vulnerable_addr: AztecAddress, pre_exploit_balance: u128) {
        // Initialize the storage for exploit executed
        storage.exploit_executed.write(false);
        // Set the initial balance to 1000 wei
        storage.pre_exploit_balance.write(pre_exploit_balance);
        // Store the vulnerable contract address
        storage.vulnerable_contract.write(vulnerable_addr);
        // Store the attacker contract address
        storage.vulnerable_contract.write(attacker_addr);
    }

    #[public]
    fn entry_point() {
        let vulnerable_contract = storage.vulnerable_contract.read();
        let attacker_contract = storage.vulnerable_contract.read();

        // Pre-exploit check
        let vulnerable_contract_balance_before = BasicVulnerable::at(vulnerable_contract).balance_of(vulnerable_contract).view(&mut context);
        assert(vulnerable_contract_balance_before == storage.pre_exploit_balance.read());

        // Run the exploit on the vulnerable_contract
        exploit(attacker_contract);

        // Post-exploit check
        let vault_balance_post = BasicVulnerable::at(vulnerable_contract).balance_of(vulnerable_contract).view(&mut context);
        assert(vault_balance_post == 0);

        storage.exploit_executed.write(true);

        // TODO: Reward the exploiter
    }

    #[public]
    fn exploit(attacker_contract: AztecAddress) {
        // Call fallback on the attacker contract
        let attacker = Attacker::at(attacker_contract);
        attacker.default_handler().call(&mut context);
    }
}
