/// Funds new accounts.

module xcoin::fund {
    use aptos_framework::account;
    use aptos_framework::coin;
    use aptos_framework::test_coin::TestCoin;

    /// Transfers `TestCoin`.
    /// If the account does not exist, it creates an account before doing so.
    public entry fun fund_account(
        from: &signer,
        to: address,
        amount: u64,
    ) {
        if (!account::exists_at(to)) {
            account::create_account(to);
        };
        coin::transfer<TestCoin>(from, to, amount);
    }
}