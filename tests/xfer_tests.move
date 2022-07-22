/// Tests for `xcoin::xfer`.
module xcoin::xfer_tests {
    use std::string;
    use std::signer;

    use aptos_framework::coin;
    use aptos_framework::timestamp;

    use xcoin::xcoin;
    use xcoin::xfer;

    use aptest::aptest;
    use aptest::acct;
    use aptest::check;

    struct FMD { }

    #[test(
        resources = @core_resources,
        framework = @aptos_framework,
        xcoin = @xcoin,
        xcoin_deployer = @xcoin_deployer,
        sender = @0xa11ce,
        recipient = @0xb0b,
    )]
    /// Test sending coins and initializing an account
    public entry fun test_accept(
        resources: signer,
        framework: signer,
        xcoin: signer,
        xcoin_deployer: signer,
        sender: signer,
        recipient: signer,
    ) {
        aptest::setup(&resources, &framework);
        xcoin::initialize_for_testing(&xcoin_deployer);

        acct::create(&resources, &sender, 1000);
        acct::create(&resources, &recipient, 1000);

        timestamp::set_time_has_started_for_testing(&framework);

        let (mint_cap, burn_cap) = coin::initialize<FMD>(
            &xcoin,
            string::utf8(b"Fake money"),
            string::utf8(b"FMD"),
            1,
            false,
        );

        // create sender FMD
        coin::register<FMD>(&sender);
        coin::deposit(signer::address_of(&sender), coin::mint<FMD>(100, &mint_cap));
        check::balance<FMD>(&sender, 100);

        // initiate coin transfer
        xfer::initiate<FMD>(&sender, signer::address_of(&recipient), 100, 0);
        check::balance<FMD>(&sender, 0);

        // accept coin transfer
        xfer::accept<FMD>(&recipient, 0);
        check::balance<FMD>(&sender, 0);
        check::balance<FMD>(&recipient, 100);

        coin::destroy_mint_cap(mint_cap);
        coin::destroy_burn_cap(burn_cap);
    }

    #[test(
        resources = @core_resources,
        framework = @aptos_framework,
        xcoin = @xcoin,
        xcoin_deployer = @xcoin_deployer,
        sender = @0xa11ce,
        recipient = @0xb0b,
    )]
    /// Test sending coins and initializing an account
    public entry fun test_cancel(
        resources: signer,
        framework: signer,
        xcoin: signer,
        xcoin_deployer: signer,
        sender: signer,
        recipient: signer,
    ) {
        aptest::setup(&resources, &framework);
        xcoin::initialize_for_testing(&xcoin_deployer);

        acct::create(&resources, &sender, 1000);
        acct::create(&resources, &recipient, 1000);

        timestamp::set_time_has_started_for_testing(&framework);

        let (mint_cap, burn_cap) = coin::initialize<FMD>(
            &xcoin,
            string::utf8(b"Fake money"),
            string::utf8(b"FMD"),
            1,
            false,
        );

        // create sender FMD
        coin::register<FMD>(&sender);
        coin::deposit(signer::address_of(&sender), coin::mint<FMD>(100, &mint_cap));
        check::balance<FMD>(&sender, 100);

        // initiate coin transfer
        xfer::initiate<FMD>(&sender, signer::address_of(&recipient), 100, 0);
        check::balance<FMD>(&sender, 0);

        // cancel coin transfer
        xfer::cancel<FMD>(&sender, signer::address_of(&recipient), 0);
        check::balance<FMD>(&sender, 100);

        coin::destroy_mint_cap(mint_cap);
        coin::destroy_burn_cap(burn_cap);
    }
}