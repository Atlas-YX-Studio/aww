address 0x222 {
module ARMMarket {

    use 0x1::Event;
    use 0x1::Account;
    use 0x1::Option::{Self, Option};
    use 0x1::Signer;
    use 0x1::Token;
    use 0x1::Vector;
    use 0x1::Timestamp;
    use 0x1::NFT::{Self, NFT};
    use 0x1::NFTGallery;

    use 0x4444::AWW::AWW;
    use 0x5555::ARM;

    const NFT_MARKET_ADDRESS: address = @0x222;

    //error
    const PERMISSION_DENIED: u64 = 200001;
    const OFFERING_NOT_EXISTS: u64 = 200002;
    const OFFERING_NOT_ON_SALE: u64 = 200003;
    const INSUFFICIENT_BALANCE: u64 = 200004;
    const ID_NOT_EXIST: u64 = 200005;
    const BID_FAILED: u64 = 200006;
    const NFT_SELL_INFO_NOT_EXISTS: u64 = 200007;
    const EXCESSIVE_FEE_RATE: u64 = 200008;
    const BOX_SELLING_NOT_EXIST: u64 = 200009;
    const BOX_SELLING_IS_EMPTY: u64 = 200010;
    const BOX_SELLING_PRICE_SMALL: u64 = 200011;
    const BOX_SELLING_INDEX_OUT_BOUNDS: u64 = 200012;
    const PRICE_TOO_LOW: u64 = 200013;

    // ******************** Config ********************
    struct Config has key, store {
        // creator fee, 10 mean 1%
        creator_fee: u128,
        // platform fee
        platform_fee: u128
    }

    // init
    public fun init_config(sender: &signer, creator_fee: u128, platform_fee: u128) {
        assert(Signer::address_of(sender) == NFT_MARKET_ADDRESS, PERMISSION_DENIED);
        assert(creator_fee < 1000 && platform_fee < 1000, EXCESSIVE_FEE_RATE);

        move_to<Config>(sender, Config {
            creator_fee: creator_fee,
            platform_fee: platform_fee,
        });
    }

    // update
    public fun update_config(sender: &signer, creator_fee: u128, platform_fee: u128)
    acquires Config {
        assert(Signer::address_of(sender) == NFT_MARKET_ADDRESS, PERMISSION_DENIED);
        assert(creator_fee < 1000 && platform_fee < 1000, EXCESSIVE_FEE_RATE);

        let config = borrow_global_mut<Config>(NFT_MARKET_ADDRESS);
        config.creator_fee = creator_fee;
        config.platform_fee = platform_fee;
    }

    // get fee
    public fun get_fee(amount: u128): (u128, u128) acquires Config {
        let config = borrow_global<Config>(NFT_MARKET_ADDRESS);
        (amount * config.creator_fee / 1000, amount * config.platform_fee / 1000)
    }

    // ******************** Initial Offering ********************
    // init market resource for different PayToken
    public fun init_market<NFTMeta: store + drop, NFTBody: store + drop, BoxToken: store, PayToken: store>(
        sender: &signer,
        creator: address,
    ) {
        let sender_address = Signer::address_of(sender);
        assert(sender_address == NFT_MARKET_ADDRESS, PERMISSION_DENIED);
        if (!exists<BoxSelling<BoxToken, PayToken>>(sender_address)) {
            move_to(sender, BoxSelling<BoxToken, PayToken> {
                items: Vector::empty(),
                creator: creator,
                last_id: 0u128,
                sell_events: Event::new_event_handle<BoxSellEvent>(sender),
                change_price_events: Event::new_event_handle<BoxChangePriceEvent>(sender),
                offline_events: Event::new_event_handle<BoxOfflineEvent>(sender),
                bid_events: Event::new_event_handle<BoxBidEvent>(sender),
                buy_events: Event::new_event_handle<BoxBuyEvent>(sender),
                accept_bid_events: Event::new_event_handle<BoxAcceptBidEvent>(sender),
            });
        };
        if (!exists<ARMSelling>(sender_address)) {
            move_to(sender, ARMSelling {
                items: Vector::empty(),
                sell_events: Event::new_event_handle<NFTSellEvent<NFTMeta, NFTBody>>(sender),
                change_price_events: Event::new_event_handle<NFTChangePriceEvent<NFTMeta, NFTBody>>(sender),
                offline_events: Event::new_event_handle<NFTOfflineEvent<NFTMeta, NFTBody>>(sender),
                bid_events: Event::new_event_handle<NFTBidEvent<NFTMeta, NFTBody>>(sender),
                buy_events: Event::new_event_handle<NFTBuyEvent<NFTMeta, NFTBody>>(sender),
                accept_bid_events: Event::new_event_handle<NFTAcceptBidEvent<NFTMeta, NFTBody>>(sender),
            });
        };
        // auto accept token
        Account::set_auto_accept_token(sender, true);
    }

    // ******************** NFT Transaction ********************
    // ARM selling list
    struct ARMSelling has key, store {
        // arm selling list
        items: vector<ARMSellInfo>,
        sell_events: Event::EventHandle<ARMPlaceOrderEvent>,
        offline_events: Event::EventHandle<ARMCancelOrderEvent>,
        buy_events: Event::EventHandle<ARMTakeOrderEvent>,
    }

    // ARM extra sell info
    struct ARMSellInfo has store {
        seller: address,
        // arm item
        nft: Option<NFT<ARM::ARMMeta, ARM::ARMBody>>,
        // arm id
        id: u64,
        // selling price
        selling_price: u128,
        // buyer address
        bidder: address,
    }

    // ARM place order event
    struct ARMPlaceOrderEvent has drop, store {
        seller: address,
        id: u64,
        pay_token_code: Token::TokenCode,
        selling_price: u128,
    }

    // ARM cancel order event
    struct ARMCancelOrderEvent has drop, store {
        seller: address,
        id: u64,
        pay_token_code: Token::TokenCode,
        selling_price: u128,
        bid_price: u128,
        bidder: address,
    }

    // ARM match order event
    struct ARMTakeOrderEvent has drop, store {
        seller: address,
        id: u64,
        pay_token_code: Token::TokenCode,
        price: u128,
        buyer: address,
        platform_fee: u128,
    }

    // ARM sell
    public fun nft_sell(
        account: &signer,
        id: u64,
        selling_price: u128
    ) acquires ARMSelling {
        // ARMSelling exists
        assert(exists<ARMSelling>(NFT_MARKET_ADDRESS), OFFERING_NOT_EXISTS);
        assert(selling_price > 0, PRICE_TOO_LOW);

        let nft_selling = borrow_global_mut<ARMSelling>(NFT_MARKET_ADDRESS);
        let owner_address = Signer::address_of(account);
        // Withdraw one NFT token from your account
        let option_nft = NFTGallery::withdraw(account, id);
        assert(Option::is_some<NFT>(&option_nft), ID_NOT_EXIST);
        let nft_sell_info = ARMSellInfo {
            seller: owner_address,
            nft: option_nft,
            id: id,
            selling_price: selling_price,
            bid_tokens: Token::zero<AWW>(),
            bidder: @0x1,
        };
        // arm_sell_info add Vector
        Vector::push_back(&mut nft_selling.items, nft_sell_info);
        // accept PayToken
        if (!Account::is_accepts_token<AWW>(owner_address)){
            Account::do_accept_token<AWW>(account);
        };
        Event::emit_event(&mut nft_selling.sell_events,
            NFTSellEvent {
                seller: owner_address,
                id: id,
                pay_token_code: Token::token_code<AWW>(),
                selling_price: selling_price,
            },
        );
    }

    // ARM offline
    public fun nft_offline(
        account: &signer,
        id: u64,
    ) acquires ARMSelling {
        assert(exists<ARMSelling>(NFT_MARKET_ADDRESS), OFFERING_NOT_EXISTS);
        let nft_selling = borrow_global_mut<ARMSelling>(NFT_MARKET_ADDRESS);
        let nft_sell_info = find_ntf_sell_info_by_id(&mut nft_selling.items, id);
        // check seller
        let user_address = Signer::address_of(account);
        assert(user_address == nft_sell_info.seller, PERMISSION_DENIED);
        // give back payToken to bidder
        let bid_amount = Token::value(&nft_sell_info.bid_tokens);
        if (bid_amount > 0) {
            let bid_tokens = Token::withdraw<AWW>(&mut nft_sell_info.bid_tokens, bid_amount);
            Account::deposit<AWW>(user_address, bid_tokens);
        };
        // get back NFT
        let nft = Option::extract(&mut nft_sell_info.nft);
        NFTGallery::deposit_to(nft_sell_info.seller, nft);
        Event::emit_event(&mut nft_selling.offline_events,
            NFTOfflineEvent {
                seller: nft_sell_info.seller,
                id: nft_sell_info.id,
                pay_token_code: Token::token_code<AWW>(),
                selling_price: nft_sell_info.selling_price,
                bid_price: bid_amount,
                bidder: nft_sell_info.bidder,
            },
        );
        // destory
        let ARMSellInfo {
            seller: _,
            nft,
            id: _,
            selling_price: _,
            bid_tokens,
            bidder: _,
        } = nft_sell_info;
        Token::destroy_zero(bid_tokens);
        Option::destroy_none(nft);
    }

    // ARM buy
    public fun nft_buy(
        account: &signer,
        id: u64
    ) acquires ARMSelling, Config {
        let nft_selling = borrow_global_mut<ARMSelling>(NFT_MARKET_ADDRESS);
        let nft_sell_info = find_ntf_sell_info_by_id(&mut nft_selling.items, id);
        f_nft_buy<>(account, nft_sell_info);
    }

    // ARM buy private
    fun f_nft_buy(
        account: &signer,
        nft_sell_info: ARMSellInfo,
    ) acquires ARMSelling, Config {
        let user_address = Signer::address_of(account);
        let nft_selling = borrow_global_mut<ARMSelling>(NFT_MARKET_ADDRESS);
        let selling_price = nft_sell_info.selling_price;
        let token_balance = Account::balance<AWW>(user_address);
        assert(token_balance >= selling_price, INSUFFICIENT_BALANCE);
        let nft = Option::extract(&mut nft_sell_info.nft);

        let (creator_fee, platform_fee) = get_fee(selling_price);

        let creator_address = NFT::get_creator(&nft);
        let creator_fee_token = Account::withdraw<AWW>(account, creator_fee);
        Account::deposit<AWW>(creator_address, creator_fee_token);

        let platform_fee_token = Account::withdraw<PayToken>(account, platform_fee);
        Account::deposit<AWW>(NFT_MARKET_ADDRESS, platform_fee_token);

        let surplus_amount = selling_price - creator_fee - platform_fee;
        let surplus_amount_token = Account::withdraw<AWW>(account, surplus_amount);
        Account::deposit<AWW>(nft_sell_info.seller, surplus_amount_token);

        //        let balance_stc = Account::balance<PayToken>(nft_sell_info.seller);
        //        Debug::print<u128>(&balance_stc);

        // accept
        NFTGallery::accept(account);
        // arm transer Own
        NFTGallery::deposit(account, nft);
        // give back bid token to bidder
        let bid_price = Token::value<AWW>(&nft_sell_info.bid_tokens);
        if (bid_price > 0u128) {
            let withdraw_bid_token = Token::withdraw<AWW>(&mut nft_sell_info.bid_tokens, bid_price);
            Account::deposit<AWW>(nft_sell_info.bidder, withdraw_bid_token);
        };

        //send NFTSellEvent event
        Event::emit_event(&mut nft_selling.buy_events,
            NFTBuyEvent {
                seller: nft_sell_info.seller,
                id: nft_sell_info.id,
                pay_token_code: Token::token_code<AWW>(),
                price: selling_price,
                buyer: user_address,
                platform_fee: platform_fee,
            },
        );
        let ARMSellInfo {
            seller: _,
            nft,
            id: _,
            selling_price: _,
            bid_tokens,
            bidder: _,
        } = nft_sell_info;
        Token::destroy_zero(bid_tokens);
        Option::destroy_none(nft);
    }

    //get nft_sell_info by id
    fun find_ntf_sell_info_by_id(
        c: &mut vector<ARMSellInfo>,
        id: u64): ARMSellInfo {
        let len = Vector::length(c);
        assert(len > 0, ID_NOT_EXIST);
        let i = len - 1;
        loop {
            // ARMSellInfo
            let nftSellInfo = Vector::borrow(c, i);
            let nft = Option::borrow(&nftSellInfo.nft);
            if (NFT::get_id(nft) == id) {
                return Vector::remove(c, i)
            };
            assert(i > 0, ID_NOT_EXIST);
            i = i - 1;
        }
    }

}
}