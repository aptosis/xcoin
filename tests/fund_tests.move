/// Tests for `xcoin::fund`.
module xcoin::fund_tests {
    use aptos_framework::account;
    use aptos_framework::test_coin::TestCoin;
    use xcoin::fund;

    use aptest::aptest;
    use aptest::acct;
    use aptest::check;

    #[test(
        resources = @core_resources,
        framework = @aptos_framework,
        sender = @0xa11ce
    )]
    /// Test sending coins and initializing an account
    public entry fun test_fund_account_to_new_account(
        resources: signer,
        framework: signer,
        sender: signer
    ) {
        aptest::setup(&resources, &framework);
        acct::create(&resources, &sender, 1);

        // account should not exist initially
        assert!(!account::exists_at(@0xb0b), 1);

        fund::fund_account(
            &sender,
            @0xb0b, // random address we know does not exist
            1,
        );

        // now account exists
        assert!(account::exists_at(@0xb0b), 1);
        check::address_balance<TestCoin>(@0xb0b, 1);
    }

    #[test(
        resources = @core_resources,
        framework = @aptos_framework,
        sender = @0xa11ce,
        recipient = @0xb0b,
    )]
    /// Test sending coins and initializing an account
    public entry fun test_fund_account_to_existing_account(
        resources: signer,
        framework: signer,
        sender: signer,
        recipient: signer,
    ) {
        aptest::setup(&resources, &framework);

        acct::create(&resources, &sender, 1);
        acct::create(&resources, &recipient, 1);

        // account should exist initially
        assert!(account::exists_at(@0xb0b), 1);
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