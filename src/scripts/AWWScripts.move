address 0x49142e24bf3b34b323b3bd339e2434e3 {
module AWWScripts {

    use 0x49142e24bf3b34b323b3bd339e2434e3::ARMMarket;
    use 0x49142e24bf3b34b323b3bd339e2434e3::AWWGame;

    // ******************** Config ********************
    // init
    public(script) fun init_config(
        sender: signer,
        creator_fee: u128,
        platform_fee: u128
    ) {
        ARMMarket::init_config(&sender, creator_fee, platform_fee);
    }

    public(script) fun update_config(
        sender: signer,
        creator_fee: u128,
        platform_fee: u128
    ) {
        ARMMarket::update_config(&sender, creator_fee, platform_fee);
    }

    // ******************** Initial Offering ********************
    public(script) fun init_market(
        sender: signer,
    ) {
        ARMMarket::init_market(&sender);
    }

    // ******************** AWW GAME Transaction ********************

    public(script) fun init_game(account: signer) {
        AWWGame::init_game(&account);
    }

    public(script) fun arm_mint(account: signer) {
        AWWGame::arm_mint(&account);
    }

    public(script) fun fight(
        account: signer,
        id: u64,
        level: u8
    ) {
        AWWGame::fight(&account, id, level);
    }

    public(script) fun harvest_reward(
        account: signer
    ) {
        AWWGame::harvest_reward(&account);
    }

    public(script) fun mint_aww_to(account: signer,
                                   amount: u128,
                                   address: address) {
        AWWGame::mint_aww_to(&account, amount, address);
    }

    // ******************** ARM Transaction ********************

    // ARM place order
    public(script) fun arm_place_order(
        account: signer,
        id: u64,
        selling_price: u128
    ) {
        ARMMarket::arm_place_order(&account, id,selling_price);
    }

    // ARM cancel order
    public(script) fun arm_cancel_order(
        account: signer,
        id: u64,
    ) {
        ARMMarket::arm_cancel_order(&account, id);
    }

    // ARM buy
    public(script) fun arm_take_order(
        account: signer,
        id: u64
    ) {
        ARMMarket::arm_take_order(&account, id);
    }

}
}