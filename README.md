# XCoin by Aptos.is

xcoin is a series of eXtensions to [AptosFramework::Coin].

- `xcoin::fund` creates an account if it doesn't exist before transferring `TestCoin`.
- `xcoin::xfer` allows transferring Coins to users that may not have an account.

## Installation

To use xcoin in your code, add the following to the `[addresses]` section of your `Move.toml`:

```toml
[addresses]
xcoin = "0x69718ef82997b31b7c1612cbc6b7eb0e3224897e631506d9675888b71f0c775a"
```



## License

Apache-2.0

