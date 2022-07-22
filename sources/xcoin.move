/// xcoin is a series of eXtensions to [aptos_framework::coin].
/// 
/// - `xcoin::fund` creates an account if it doesn't exist before transferring `TestCoin`.
/// - `xcoin::xfer` allows transferring Coins to users that may not have an account.

module xcoin::xcoin {
    use std::signer;
    use std::errors;

    use aptos_framework::account::{Self, SignerCapability};

    use deployer::deployer;

    friend xcoin::xfer;

    /// Must sign as the module.
    const ENOT_SELF: u64 = 1;

    /// Module has already been initialized.
    const ESELF_ALREADY_PUBLISHED: u64 = 2;

    struct SelfResources has key {
        signer_cap: SignerCapability,
    }

    /// Initializes the protocol with this module being its own signer.
    public entry fun initialize(self: &signer) {
        let signer_cap = deployer::retrieve_resource_account_cap(self);
        initialize_internal(signer_cap);
    }

    #[test_only]
    /// Initializes the protocol for testing.
    public fun initialize_for_testing(deployer: &signer) {
        let (_, resource_signer_cap) = account::create_resource_account(deployer, b"xcoin");
        initialize_internal(resource_signer_cap);
    }

    fun initialize_internal(
        resource_signer_cap: SignerCapability,
    ) {
        let self = &account::create_signer_with_capability(&resource_signer_cap);
        assert!(
            signer::address_of(self) == @xcoin,
            errors::requires_capability(ENOT_SELF)
        );
        move_to(self, SelfResources {
            signer_cap: resource_signer_cap,
        });
    }

    /// Creates the xcoin signer.
    public(friend) fun get_signer(): signer acquires SelfResources {
        let store = borrow_global<SelfResources>(@xcoin);
        account::create_signer_with_capability(&store.signer_cap)
    }
}