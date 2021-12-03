address 0x333 {
module AWWScripts {

    use 0x222::NFTMarket;

    // ******************** Config ********************
    // init
    public(script) fun init_config(
        sender: signer,
        creator_fee: u128,
        platform_fee: u128
    ) {
        NFTMarket::init_config(&sender, creator_fee, platform_fee);
    }

    public(script) fun update_config(
        sender: signer,
        creator_fee: u128,
        platform_fee: u128
    ) {
        NFTMarket::update_config(&sender, creator_fee, platform_fee);
    }

    // ******************** Initial Offering ********************
    public(script) fun init_market<NFTMeta: store + drop, NFTBody: store + drop, BoxToken: store, PayToken: store>(
        sender: signer,
        creator: address,
    ) {

    }

    // ******************** AWW GAME Transaction ********************

    public(script) fun arm_mint(
        account: signer
    ) {

    }

    public(script) fun fight(
        account: signer,
        id: u64,
        level: u8
    ) {

    }

    public(script) fun harvest_reward(
        account: signer
    ) {

    }


    // ******************** ARM Transaction ********************

    // ARM sell
    public(script) fun arm_sell(
        account: signer,
        id: u64,
        selling_price: u128
    ) {

    }

    // ARM offline
    public(script) fun arm_offline(
        account: signer,
        id: u64,
    ) {

    }

    // ARM buy
    public(script) fun arm_buy(
        account: signer,
        id: u64
    ) {

    }

}
}