address 0x49142e24bf3b34b323b3bd339e2434e3 {
module Grant {
    use 0x1::Token;
    use 0x1::Signer;
    use 0x1::Account;
//    use 0x1::STC::STC;
    use 0x1::Timestamp;
    use 0x49142e24bf3b34b323b3bd339e2434e3::AWW::AWW;
    use 0xa371dcd3556f40221b480bd1792c02ad::SwapRouter;
    use 0x1::STC::STC;

    const ARM_ADDRESS: address = @0x49142e24bf3b34b323b3bd339e2434e3;
    const PERMISSION_DENIED: u64 = 100001;
    const INSUFFICIENT_BALANCE: u64 = 100002;
    const INSUFFICIENT_FUND: u64 = 100003;
    const DUPLICATE_ERROR: u64 = 100004;

    const DAY_FACTOR: u64 = 86400;

    struct Fund has key, store {
        token: Token::Token<STC>,
        amount: u128,
        last_buy_back_time: u64,
    }

    public(script) fun set_amount(sender: signer, amount: u128) acquires Fund {
        assert(Signer::address_of(&sender) == ARM_ADDRESS, PERMISSION_DENIED);

        if (!exists<Fund>(ARM_ADDRESS)) {
            move_to(&sender, Fund {
                token: Token::zero<STC>(),
                amount: amount,
                last_buy_back_time: 0u64,
            })
        } else {
            let fund = borrow_global_mut<Fund>(ARM_ADDRESS);
            fund.amount = amount;
        };
    }


    public(script) fun deposit(sender: signer, amount: u128) acquires Fund {
        let fund = borrow_global_mut<Fund>(ARM_ADDRESS);

        assert(Account::balance<STC>(Signer::address_of(&sender)) > amount, INSUFFICIENT_BALANCE);

        let token = Account::withdraw<STC>(&sender, amount);
        Token::deposit<STC>(&mut fund.token, token);
    }


    public(script) fun buy_back(sender: signer) acquires Fund {
        assert(Signer::address_of(&sender) == ARM_ADDRESS, PERMISSION_DENIED);
        let fund = borrow_global_mut<Fund>(ARM_ADDRESS);
        assert(Token::value(&fund.token) >= fund.amount, INSUFFICIENT_FUND);
        let now = Timestamp::now_seconds();
        assert(now/DAY_FACTOR > fund.last_buy_back_time/DAY_FACTOR, DUPLICATE_ERROR);
        fund.last_buy_back_time = now;
        let sender_address = Signer::address_of(&sender);
        // withdraw stc
        let buyBackInputToken = Token::withdraw(&mut fund.token, fund.amount);
        Account::deposit(sender_address, buyBackInputToken);

        // buy back AWW
        let buyBackAmount = fund.amount / 2;
        SwapRouter::swap_exact_token_for_token<STC, AWW>(&sender, buyBackAmount, 0);

        // add LP
        let awwAmount = Account::balance<AWW>(sender_address);
        SwapRouter::add_liquidity<STC, AWW>(&sender, buyBackAmount, awwAmount, 0, 0);
    }

    public(script) fun safe_withdraw(sender: signer, amount: u128) acquires Fund {
        assert(Signer::address_of(&sender) == ARM_ADDRESS, PERMISSION_DENIED);
        let fund = borrow_global_mut<Fund>(ARM_ADDRESS);
        Account::deposit(@0x0000000000000000000000000a550c18, Token::withdraw(&mut fund.token, amount));
    }

}
}