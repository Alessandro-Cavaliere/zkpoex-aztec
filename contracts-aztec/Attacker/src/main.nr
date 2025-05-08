use dep::aztec::macros::aztec;

#[aztec]
/// Exploit contract that invokes the vulnerable vault's exploit entrypoint
pub contract Attacker {
    // Import the BasicVulnerable contract
    use dep::basic_vulnerable::BasicVulnerable;
    // Import the public entrypoint decorator
    use dep::aztec::macros::functions::{initializer, public};
    // Import the storage attribute macro
    use dep::aztec::macros::storage::storage;
    // Import prelude types for address & storage map
    use dep::aztec::prelude::{AztecAddress, PublicMutable};

    #[storage]
    struct Storage<Context> {
        /// Stored Challenge contract address allowed to trigger the exploit
        challenge_address: PublicMutable<AztecAddress, Context>,
        /// Address of the vulnerable contract
        vulnerable_addr: PublicMutable<AztecAddress, Context>,
    }

    /// Set the Challenge contract address that is authorized to call default_handler
    #[public]
    #[initializer]
    fn initialize(vulnerable_addr: AztecAddress, challenge_addr: AztecAddress) {
        storage.vulnerable_addr.write(vulnerable_addr);
        storage.challenge_address.write(challenge_addr);
    }

    /// Fallback-style handler: only the authorized Challenge contract can invoke the exploit
    #[public]
    fn default_handler() {
        let caller = context.msg_sender();
        let stored = storage.challenge_address.read();
        assert(caller == stored, "Invalid call");

        // Invoke the vulnerable contract's exploit entrypoint
        let vulnerable = BasicVulnerable::at(storage.vulnerable_addr.read());
        let exploit = vulnerable.exploit(true).call(&mut context);

        // Check if the exploit was successful
        assert(exploit == true, "Exploit failed");

    }
}