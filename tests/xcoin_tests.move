#[test_only]
module xcoin::xcoin_tests {
    use AptosFramework::Account;
    use AptosFramework::TestCoin::TestCoin;
    use xcoin::fund;

    use aptest::account;
    use aptest::check;

    #[test(
        resources = @CoreResources,
        framework = @AptosFramework,
        sender = @0xa11ce
    )]
    /// Test sending coins and initializing an account
    public(script) fun test_fund_account_to_new_account(
        resources: signer,
        framework: signer,
        sender: signer
    ) {
        account::prepare(&resources, &framework);
        account::setup(&resources, &sender, 1);

        // account should not exist initially
        assert!(!Account::exists_at(@0xb0b), 1);

        fund::fund_account(
            &sender,
            @0xb0b, // random address we know does not exist
            1,
        );

        // now account exists
        assert!(Account::exists_at(@0xb0b), 1);
        check::address_balance<TestCoin>(@0xb0b, 1);
    }

    #[test(
        resources = @CoreResources,
        framework = @AptosFramework,
        sender = @0xa11ce,
        recipient = @0xb0b,
    )]
    /// Test sending coins and initializing an account
    public(script) fun test_fund_account_to_existing_account(
        resources: signer,
        framework: signer,
        sender: signer,
        recipient: signer,
    ) {
        account::prepare(&resources, &framework);

        account::setup(&resources, &sender, 1);
        account::setup(&resources, &recipient, 1);

        // account should exist initially
        assert!(Account::exists_at(@0xb0b), 1);
        check::address_balance<TestCoin>(@0xb0b, 1);

        fund::fund_account(
            &sender,
            @0xb0b, // random address we know does not exist
            1,
        );

        // now account has two coins
        check::address_balance<TestCoin>(@0xb0b, 2);
    }
}