#[test_only]
/// Tests for `xcoin::xfer`.
module xcoin::xfer_tests {
    use Std::ASCII;
    use Std::Signer;

    use AptosFramework::Coin;
    use AptosFramework::Timestamp;

    use xcoin::xcoin;
    use xcoin::xfer;

    use aptest::account;
    use aptest::check;

    struct FMD { }

    #[test(
        resources = @CoreResources,
        framework = @AptosFramework,
        xcoin = @xcoin,
        xcoin_deployer = @xcoin_deployer,
        sender = @0xa11ce,
        recipient = @0xb0b,
    )]
    /// Test sending coins and initializing an account
    public(script) fun test_accept(
        resources: signer,
        framework: signer,
        xcoin: signer,
        xcoin_deployer: signer,
        sender: signer,
        recipient: signer,
    ) {
        account::prepare(&resources, &framework);
        xcoin::initialize_for_testing(&xcoin_deployer, &xcoin);

        account::setup(&resources, &sender, 1000);
        account::setup(&resources, &recipient, 1000);

        Timestamp::set_time_has_started_for_testing(&resources);

        let (mint_cap, burn_cap) = Coin::initialize<FMD>(
            &xcoin,
            ASCII::string(b"Fake money"),
            ASCII::string(b"FMD"),
            1,
            false,
        );

        // create sender FMD
        Coin::register<FMD>(&sender);
        Coin::deposit(Signer::address_of(&sender), Coin::mint<FMD>(100, &mint_cap));
        check::balance<FMD>(&sender, 100);

        // initiate coin transfer
        xfer::initiate<FMD>(&sender, Signer::address_of(&recipient), 100, 0);
        check::balance<FMD>(&sender, 0);

        // accept coin transfer
        xfer::accept<FMD>(&recipient, 0);
        check::balance<FMD>(&sender, 0);
        check::balance<FMD>(&recipient, 100);

        Coin::destroy_mint_cap(mint_cap);
        Coin::destroy_burn_cap(burn_cap);
    }

    #[test(
        resources = @CoreResources,
        framework = @AptosFramework,
        xcoin = @xcoin,
        xcoin_deployer = @xcoin_deployer,
        sender = @0xa11ce,
        recipient = @0xb0b,
    )]
    /// Test sending coins and initializing an account
    public(script) fun test_cancel(
        resources: signer,
        framework: signer,
        xcoin: signer,
        xcoin_deployer: signer,
        sender: signer,
        recipient: signer,
    ) {
        account::prepare(&resources, &framework);
        xcoin::initialize_for_testing(&xcoin_deployer, &xcoin);

        account::setup(&resources, &sender, 1000);
        account::setup(&resources, &recipient, 1000);

        Timestamp::set_time_has_started_for_testing(&resources);

        let (mint_cap, burn_cap) = Coin::initialize<FMD>(
            &xcoin,
            ASCII::string(b"Fake money"),
            ASCII::string(b"FMD"),
            1,
            false,
        );

        // create sender FMD
        Coin::register<FMD>(&sender);
        Coin::deposit(Signer::address_of(&sender), Coin::mint<FMD>(100, &mint_cap));
        check::balance<FMD>(&sender, 100);

        // initiate coin transfer
        xfer::initiate<FMD>(&sender, Signer::address_of(&recipient), 100, 0);
        check::balance<FMD>(&sender, 0);

        // cancel coin transfer
        xfer::cancel<FMD>(&sender, Signer::address_of(&recipient), 0);
        check::balance<FMD>(&sender, 100);

        Coin::destroy_mint_cap(mint_cap);
        Coin::destroy_burn_cap(burn_cap);
    }
}