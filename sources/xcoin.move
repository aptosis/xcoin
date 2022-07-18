/// xcoin is a series of eXtensions to [AptosFramework::Coin].
/// 
/// - `xcoin::transfer_test_coin` creates an account if it doesn't exist before transferring `TestCoin`.

module xcoin::xcoin {
    use AptosFramework::Account;
    use AptosFramework::Coin;
    use AptosFramework::TestCoin::TestCoin;

    /// Transfers `TestCoin`.
    /// If the account does not exist, it creates an account before doing so.
    public(script) fun transfer_test_coin(
        from: &signer,
        to: address,
        amount: u64,
    ) {
        if (!Account::exists_at(to)) {
            Account::create_account(to);
        };
        Coin::transfer<TestCoin>(from, to, amount);
    }
}