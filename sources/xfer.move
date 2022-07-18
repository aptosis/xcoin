/// The `xfer` module defines a method of revocable transfers to another party.
/// 
/// The primary use case of this module is to be able to send coins to any address,
/// even if they do not have an existing `CoinStore`.
/// 
/// Transfers may also be revoked by the sender if its `deadline` has elapsed. This
/// prevents the sender from sending coins to invalid addresses.
///
/// # Lifecycle
///
/// 1. Call `xfer::initiate` to create a transfer of coins to another party for the given amount.
/// 2. Call `xfer::accept` to accept coins.
///   a. If the recipient does not want to accept the coins, call `xfer::reject` to reject the coins.
module xcoin::xfer {
    use Std::BCS;
    use Std::Errors;
    use Std::Signer;

    use AptosFramework::Account::{Self, SignerCapability};
    use AptosFramework::Coin::{Self, Coin};
    use AptosFramework::Table::{Self, Table};
    use AptosFramework::Timestamp;

    use xcoin::xcoin;

    /// The `CoinTransfers` struct has not been published.
    const ECOIN_TRANSFERS_NOT_PUBLISHED: u64 = 1;

    /// Recipient does not have any pending transfers.
    const EUSER_NOT_PUBLISHED: u64 = 2;

    /// No pending transfer was found with this id.
    const ETRANSFER_NOT_PUBLISHED: u64 = 3;

    /// Only the creator of a transfer may refund it.
    const ECANNOT_REFUND_NOT_CREATOR: u64 = 4;

    /// Not enough time has passed since creating this transfer.
    const EREFUND_DEADLINE_NOT_MET: u64 = 5;

    /// A transfer of coins.
    struct Transfer<phantom CoinType> has store {
        /// The address which initiated this transfer.
        creator: address,
        /// Amount of coins transferred.
        amount: Coin<CoinType>,
        /// If coins are not accepted by this time, the transfer may be cancelled.
        deadline: u64,
    }

    /// An inbox holds the incoming `Transfer`s to a given address.
    /// Inboxes are stored on a resource account.
    struct Inbox<phantom CoinType> has key {
        /// A Table of pending transfers.
        pending: Table<u64, Transfer<CoinType>>,
        /// The total number of items in this inbox.
        /// This is also the next unused index of the inbox.
        size: u64,
    }

    /// Metadata about an inbox account.
    struct InboxMeta has key {
        /// A Table of `recipient` -> `inbox` address.
        signer_cap: SignerCapability,
    }

    /// A mapping of addresses to their inbox.
    struct InboxMapping has key {
        /// A Table of `recipient` -> `inbox` address.
        addresses: Table<address, address>,
    }

    /// Gets the inbox address of the given recipient, creating it if it doesn't exist.
    public fun get_or_create_inbox_address(recipient: address): address acquires InboxMapping {
        if (!exists<InboxMapping>(@xcoin)) {
            let s = xcoin::get_signer();
            move_to<InboxMapping>(&s, InboxMapping {
                addresses: Table::new(),
            });
        };
        let mapping = borrow_global<InboxMapping>(@xcoin); 
        if (!Table::contains(&mapping.addresses, recipient)) {
            let mapping_mut = borrow_global_mut<InboxMapping>(@xcoin); 
            let s = xcoin::get_signer();
            let (inbox_signer, inbox_cap) = Account::create_resource_account(&s, BCS::to_bytes(&recipient));
            let inbox_addr = Signer::address_of(&inbox_signer);
            Table::add(&mut mapping_mut.addresses, recipient, inbox_addr);
            move_to<InboxMeta>(&inbox_signer, InboxMeta {
                signer_cap: inbox_cap,
            });
            inbox_addr
        } else {
            *Table::borrow(&mapping.addresses, recipient)
        }
    }

    /// Creates a transfer.
    ///
    /// @param deadline_duration - the duration in seconds until the transfer may be cancelled.
    public(script) fun initiate<CoinType>(
        from: &signer,
        to: address,
        amount: u64,
        deadline_duration: u64,
    ) acquires InboxMapping, InboxMeta, Inbox {
        let coin = Coin::withdraw<CoinType>(from, amount);
        let deadline = Timestamp::now_seconds() + deadline_duration;
        initiate_transfer(from, to, coin, deadline);
    }

    /// Cancels a transfer.
    public(script) fun cancel<CoinType>(
        sender: &signer,
        recipient_addr: address,
        id: u64,
    ) acquires InboxMapping, Inbox {
        let coin = cancel_transfer<CoinType>(sender, recipient_addr, id);
        Coin::deposit<CoinType>(Signer::address_of(sender), coin);
    }

    /// Accepts a transfer.
    public(script) fun accept<CoinType>(
        recipient: &signer,
        id: u64,
    ) acquires InboxMapping, Inbox {
        let recipient_addr = Signer::address_of(recipient);
        if (!Coin::is_account_registered<CoinType>(recipient_addr)) {
            Coin::register<CoinType>(recipient);
        };
        let coin = accept_transfer<CoinType>(recipient, id);
        Coin::deposit<CoinType>(recipient_addr, coin);
    }

    /// Initiates a transfer to an inbox.
    public fun initiate_transfer<CoinType>(
        from: &signer,
        to: address,
        source: Coin<CoinType>,
        deadline: u64,
    ): u64 acquires InboxMapping, Inbox, InboxMeta {
        let inbox_addr = get_or_create_inbox_address(to);
        // If there are no transfers for this coin, create the table for the coin.
        if (!exists<Inbox<CoinType>>(inbox_addr)) {
            let signer_cap = &borrow_global<InboxMeta>(inbox_addr).signer_cap;
            let inbox_signer = Account::create_signer_with_capability(signer_cap);
            move_to<Inbox<CoinType>>(&inbox_signer, Inbox {
                pending: Table::new(),
                size: 0,
            });
        };

        let inbox = borrow_global_mut<Inbox<CoinType>>(inbox_addr);
        inbox_create_transfer_internal(
            inbox,
            Signer::address_of(from),
            source,
            deadline,
        )
    }

    /// Cancels a transfer, returning the coins.
    /// 
    /// If the `deadline` has not yet been met, this transaction should fail.
    public fun cancel_transfer<CoinType>(
        sender: &signer,
        recipient_addr: address,
        id: u64,
    ): Coin<CoinType> acquires InboxMapping, Inbox {
        let Transfer {
            amount,
            deadline,
            creator,
        } = remove_transfer_internal<CoinType>(recipient_addr, id);
        assert!(
            creator == Signer::address_of(sender),
            Errors::requires_role(ECANNOT_REFUND_NOT_CREATOR),
        );
        assert!(
            Timestamp::now_seconds() >= deadline,
            Errors::invalid_state(EREFUND_DEADLINE_NOT_MET)
        );
        amount
    }

    /// Accepts a transfer.
    public fun accept_transfer<CoinType>(
        recipient: &signer,
        id: u64,
    ): Coin<CoinType> acquires InboxMapping, Inbox {
        let Transfer {
            amount,
            creator: _creator,
            deadline: _deadline,
        } = remove_transfer_internal<CoinType>(Signer::address_of(recipient), id);
        amount
    }

    /// Removes a transfer from the recipient.
    /// Internal only-- this does not validate the recipient.
    fun remove_transfer_internal<CoinType>(
        recipient_addr: address,
        id: u64,
    ): Transfer<CoinType> acquires InboxMapping, Inbox {
        let inbox_addr = get_or_create_inbox_address(recipient_addr);
        let inbox = borrow_global_mut<Inbox<CoinType>>(inbox_addr);
        inbox_remove_transfer_internal<CoinType>(inbox, id)
    }

    /// Creates a transfer and adds it to the inbox.
    fun inbox_create_transfer_internal<CoinType>(
        inbox: &mut Inbox<CoinType>,
        from: address,
        amount: Coin<CoinType>,
        deadline: u64,
    ): u64 {
        let id = inbox.size;
        Table::add(&mut inbox.pending, id, Transfer {
            creator: from,
            amount,
            deadline,
        });
        inbox.size = inbox.size + 1;
        id
    }

    /// Remove the transfer from the inbox.
    fun inbox_remove_transfer_internal<CoinType>(
        inbox: &mut Inbox<CoinType>,
        id: u64,
    ): Transfer<CoinType> {
        assert!(
            Table::contains(&mut inbox.pending, id),
            Errors::not_published(ETRANSFER_NOT_PUBLISHED)
        );
        Table::remove(&mut inbox.pending, id)
    }
}