/// xcoin is a series of eXtensions to [AptosFramework::Coin].
/// 
/// - `xcoin::fund` creates an account if it doesn't exist before transferring `TestCoin`.
/// - `xcoin::xfer` allows transferring Coins to users that may not have an account.

module xcoin::xcoin {
    use Std::Signer;
    use Std::Errors;

    use AptosFramework::Account::{Self, SignerCapability};

    use Deployer::Deployer;

    friend xcoin::xfer;

    /// Must sign as the module.
    const ENOT_SELF: u64 = 1;

    /// Module has already been initialized.
    const ESELF_ALREADY_PUBLISHED: u64 = 2;

    struct SelfResources has key {
        signer_cap: SignerCapability,
    }

    /// Initializes the protocol with this module being its own signer.
    public(script) fun initialize(self: signer) {
        let signer_cap = Deployer::retrieve_resource_account_cap(&self);
        let s = Account::create_signer_with_capability(&signer_cap);
        assert!(
            Signer::address_of(&s) == @xcoin,
            Errors::requires_capability(ENOT_SELF)
        );
        move_to(&self, SelfResources { signer_cap });
    }

    #[test_only]
    /// Initializes the protocol without a separate LP store.
    /// This requires one to call `Pair::create_for_testing` to create pairs.
    public fun initialize_for_testing(
        deployer: &signer,
        self: &signer,
    ) {
        let (resource, resource_signer_cap) = Account::create_resource_account(deployer, b"xcoin");
        assert!(
            Signer::address_of(&resource) == @xcoin,
            Errors::requires_capability(ENOT_SELF)
        );
        move_to(self, SelfResources {
            signer_cap: resource_signer_cap,
        });
    }

    /// Creates the xcoin signer.
    public(friend) fun get_signer(): signer acquires SelfResources {
        let store = borrow_global<SelfResources>(@xcoin);
        Account::create_signer_with_capability(&store.signer_cap)
    }
}