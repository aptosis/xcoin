#[test_only]
module xcoin::xcoin_tests {
    use Std::Signer;
    use AptosFramework::Account;
    use AptosFramework::Coin;
    use AptosFramework::TestCoin::{Self, TestCoin};
    use xcoin::xcoin;

    struct Trash has key {
        mint_cap: Coin::MintCapability<TestCoin>,
        burn_cap: Coin::BurnCapability<TestCoin>,
    }

    #[test(
        core = @CoreResources,
        framework = @AptosFramework,
        sender = @0xa11ce
    )]
    /// Test sending coins and initializing an account
    public(script) fun test_fund_account_to_new_account(
        core: signer,
        framework: signer,
        sender: signer
    ) {
        let (mint_cap, burn_cap) = TestCoin::initialize(&framework, &core);
        move_to(&core, Trash {
            mint_cap,
            burn_cap,
        });

        // set up the sender
        Account::create_account(Signer::address_of(&sender));
        TestCoin::mint(&core, Signer::address_of(&sender), 1);

        // account should not exist initially
        assert!(!Account::exists_at(@0xb0b), 1);

        xcoin::fund_account(
            &sender,
            @0xb0b, // random address we know does not exist
            1,
        );

        // now account exists
        assert!(Account::exists_at(@0xb0b), 1);
        assert!(Coin::balance<TestCoin>(@0xb0b) == 1, 1);
    }

    #[test(
        core = @CoreResources,
        framework = @AptosFramework,
        sender = @0xa11ce,
        recipient = @0xb0b,
    )]
    /// Test sending coins and initializing an account
    public(script) fun test_fund_account_to_existing_account(
        core: signer,
        framework: signer,
        sender: signer,
        recipient: signer,
    ) {
        let (mint_cap, burn_cap) = TestCoin::initialize(&framework, &core);
        move_to(&core, Trash {
            mint_cap,
            burn_cap,
        });

        // set up the sender
        Account::create_account(Signer::address_of(&sender));
        TestCoin::mint(&core, Signer::address_of(&sender), 1);

        // set up the revipient
        Account::create_account(Signer::address_of(&recipient));
        TestCoin::mint(&core, Signer::address_of(&recipient), 1);

        // account should exist initially
        assert!(Account::exists_at(@0xb0b), 1);
        assert!(Coin::balance<TestCoin>(@0xb0b) == 1, 1);

        xcoin::fund_account(
            &sender,
            @0xb0b, // random address we know does not exist
            1,
        );

        // now account has two coins
        assert!(Coin::balance<TestCoin>(@0xb0b) == 2, 1);
    }
}