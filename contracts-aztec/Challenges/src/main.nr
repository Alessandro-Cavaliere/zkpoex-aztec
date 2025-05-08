use dep::aztec::prelude::{AztecAddress, Field, PublicContext, PublicMutable};
use dep::aztec::macros::{public, storage, aztec};

#[aztec]
contract Challenge {
    #[storage]
    struct Storage {
        solved: PublicMutable<Field>,
        exploit_executed: PublicMutable<bool, Context>,
        pre_exploit_balance: PublicMutable<Field, Context>,
    }

    const VULNERABLE_CONTRACT: AztecAddress = AztecAddress::from_field(Field::from(0x4330E5E62a8FB0219900b20f4c6C78D11Bf9D1f5));

    // === Constructor ===
    #[public]
    #[initializer]
    fn constructor(target: AztecAddress) {
        storage.solved.write(false);
        storage.exploit_executed.write(false);
        storage.pre_exploit_balance.write(0.into());
    }

    #[public]
    fn entry_point(context: &mut PublicContext) {
        // Pre-exploit check (not a relevant amount, just for exploit proving)
        let vault_balance_pre = context.public_balance(Self::VULNERABLE_CONTRACT);
        assert(vault_balance_pre == get_pre_exploit_balance());

        // Execute exploit
        Self::exploit(context);

        // Post-exploit check
        let vault_balance_post = context.public_balance(Self::VULNERABLE_CONTRACT);

        // An exploit is successful if the vault balance is 0 (all funds drained)
        assert(vault_balance_post == 0);

        // Set solved flags so external triggering can be done
        storage.solved.set(1);

        // Reward the exploiter
        let exploiter_address = context.sender();
        let exploiter_balance = context.public_balance(exploiter_address);
        context.transfer_public(exploiter_address, Self::VULNERABLE_CONTRACT, exploiter_balance);
    }

    #[public]
    fn exploit(context: &mut PublicContext) {
        let target_address = AztecAddress::from_field(
            Field::from(0xBAda550000000000000000000000000000000000)
        );
        
        // Execute low-level call (function selector 0 for fallback)
        let (success, _) = context.call_public_function(
            target_address,
            0,  // Function selector
            []  // No arguments
        );
        assert(success);
    }

    // === Utility: read saved balance ===
    #[utility]
    unconstrained fn get_pre_exploit_balance() -> Field {
        storage.pre_exploit_balance.read()
    }
}