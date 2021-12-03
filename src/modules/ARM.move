address 0x111 {
module ARM {
    use 0x1::Signer;
    use 0x1::Event;
    use 0x1::Block;
    use 0x1::Vector;
    use 0x1::Token;
    use 0x1::Account;
    use 0x1::NFT::{Self, NFT};
    use 0x1::NFTGallery;

    const ARM_ADDRESS: address = @0x111;

    const PERMISSION_DENIED: u64 = 100001;

    // ******************** ARM ********************
    // ARM extra meta
    struct ARMMeta has copy, store, drop {
        rarity: u8,
        stamina: u8,
        win_rate_bonus: u8
    }

    // ARM body
    struct ARMBody has copy, store, drop {}

    // ARM extra type info
    struct ARMTypeInfo has copy, store, drop {}

    struct ARMNFTCapability has key {
        mint: NFT::MintCapability<ARMMeta>,
    }

    // init nft with image data
    fun init_arm(
        sender: &signer,
        metadata: NFT::Metadata,
    ) {
        NFT::register<ARMMeta, ARMTypeInfo>(sender, ARMTypeInfo {}, metadata);
        let mint = NFT::remove_mint_capability<ARMMeta>(sender);
        move_to(sender, ARMNFTCapability { mint });
    }

    // mint nft
    fun mint_arm(
        sender: &signer,
        metadata: NFT::Metadata,
        rarity: u8,
        stamina: u8,
        win_rate_bonus: u8,
    ) acquires ARMNFTCapability, ARMGallery {
        let sender_address = Signer::address_of(sender);
        let cap = borrow_global_mut<ARMNFTCapability>(sender_address);
        let nft = NFT::mint_with_cap<ARMMeta, ARMBody, ARMTypeInfo>(
            sender_address,
            &mut cap.mint,
            metadata,
            ARMMeta {
                rarity,
                stamina,
                win_rate_bonus
            },
            ARMBody {}
        );
        let gallery = borrow_global_mut<ARMGallery>(sender_address);
        let id = NFT::get_id<ARMMeta, ARMBody>(&nft);
        Vector::push_back(&mut gallery.items, nft);
        Event::emit_event<ARMMintEvent>(&mut gallery.arm_mint_events,
            ARMMintEvent {
                creator: sender_address,
                id: id,
            },
        );
    }

    // ******************** NFT Gallery ********************
    // arm gallery
    struct ARMGallery has key, store {
        items: vector<NFT<ARMMeta, ARMBody>>,
        arm_mint_events: Event::EventHandle<ARMMintEvent>,
    }

    // arm mint event
    struct ARMMintEvent has drop, store {
        creator: address,
        id: u64,
    }

    // init arm gallery
    fun init_gallery(sender: &signer) {
        if (!exists<ARMGallery>(Signer::address_of(sender))) {
            let gallery = ARMGallery {
                items: Vector::empty<NFT<ARMMeta, ARMBody>>(),
                arm_mint_events: Event::new_event_handle<ARMMintEvent>(sender),
            };
            move_to(sender, gallery);
        }
    }

    // Count all NFTs assigned to an owner
    public fun count_of(owner: address): u64
    acquires ARMGallery {
        let gallery = borrow_global_mut<ARMGallery>(owner);
        Vector::length(&gallery.items)
    }

    // ******************** NFT public function ********************

    // init nft and box with image
    public fun f_init_with_image(
        sender: &signer,
        name: vector<u8>,
        image: vector<u8>,
        description: vector<u8>,
    ) {
        assert(Signer::address_of(sender) == NFT_ADDRESS, PERMISSION_DENIED);
        let metadata = NFT::new_meta_with_image(name, image, description);
        init_arm(sender, metadata);
        init_gallery(sender);
        NFTGallery::accept<ARMMeta, ARMBody>(sender);
    }

    // init nft and box with image data
    public fun f_init_with_image_data(
        sender: &signer,
        name: vector<u8>,
        image_data: vector<u8>,
        description: vector<u8>,
    ) {
        assert(Signer::address_of(sender) == NFT_ADDRESS, PERMISSION_DENIED);
        let metadata = NFT::new_meta_with_image_data(name, image_data, description);
        init_arm(sender, metadata);
        init_gallery(sender);
        NFTGallery::accept<ARMMeta, ARMBody>(sender);
    }

    // mint ARM
    public fun f_mint_with_image(
        sender: &signer,
        name: vector<u8>,
        image: vector<u8>,
        description: vector<u8>,
        rarity: u8,
        stamina: u8,
        win_rate_bonus: u8,
    ) acquires ARMNFTCapability, ARMBoxCapability, ARMGallery {
        let sender_address = Signer::address_of(sender);
        assert(sender_address == NFT_ADDRESS, PERMISSION_DENIED);
        let metadata = NFT::new_meta_with_image(name, image, description);
        mint_arm(sender, metadata, rarity, stamina, win_rate_bonus);
    }

    // mint ARM
    public fun f_mint_with_image_data(
        sender: &signer,
        name: vector<u8>,
        image_data: vector<u8>,
        description: vector<u8>,
        rarity: u8,
        stamina: u8,
        win_rate_bonus: u8,
    ) acquires ARMNFTCapability, ARMBoxCapability, ARMGallery {
        let sender_address = Signer::address_of(sender);
        assert(sender_address == NFT_ADDRESS, PERMISSION_DENIED);
        let metadata = NFT::new_meta_with_image_data(name, image_data, description);
        mint_arm(sender, metadata, rarity, stamina, win_rate_bonus);
    }

    // get a random ARM
    public fun f_get_arm(sender: &signer)
    acquires ARMBoxCapability, ARMGallery {
        plat_address = @0x12323;
        let aww_amount = f_get_aww_amount(20000000000u128);
        let aww_token = Account::pay_from<AWW>(sender, plat_address, aww_amount);
        let stc_token = Account::pay_from<STC>(sender, plat_address, 100000000000u128);

        // get hash last 64 bit and mod nft_size
        let hash = Block::get_parent_hash();
        let k = 0u64;
        let i = 0;
        while (i < 8) {
            let tmp = (Vector::pop_back<u8>(&mut hash) as u128);
            k = (tmp << (i * 8) as u64) + k;
            i = i + 1;
        };
        let idx = k % count_of(NFT_ADDRESS);
        // get a nft by idx
        let sender_address = Signer::address_of(sender);
        let gallery = borrow_global_mut<ARMGallery>(NFT_ADDRESS);
        let nft = Vector::remove<NFT<ARMMeta, ARMBody>>(&mut gallery.items, idx);
        let id = NFT::get_id<ARMMeta, ARMBody>(&nft);
        NFTGallery::accept<ARMMeta, ARMBody>(sender);
        NFTGallery::deposit<ARMMeta, ARMBody>(sender, nft);
        // emit event
        Event::emit_event<BoxOpenEvent<ARMMeta, ARMBody>>(&mut gallery.box_open_events,
            BoxOpenEvent {
                owner: sender_address,
                id: id,
            },
        );
    }

    fun f_get_aww_amount(usdt_amount: u128): u128 {
        // order x and y to avoid duplicates
        let order = SwapLibrary::get_token_order<USDT, AWW>();
        let (reserve_usdt, reserve_aww);
        if (order == 1) {
            (reserve_usdt, reserve_aww) = SwapPair::get_reserves<USDT, AWW>();
        } else {
            (reserve_aww, reserve_usdt) = SwapPair::get_reserves<AWW, USDT>();
        };

        mul_div(usdt_amount, reserve_aww, reserve_usdt)
    }

    fun f_get_reserves<X: store, Y: store>(): (u128, u128) {
        let pair_exists = SwapPair::pair_exists<X, Y>(PAIR_ADDRESS);
        assert(pair_exists, SWAP_PAIR_NOT_EXISTS);
        let (reserve_x, reserve_y) = SwapPair::get_reserves<X, Y>();
        (reserve_x, reserve_y)
    }

    // ******************** NFT script function ********************

    public(script) fun init_with_image(
        sender: signer,
        name: vector<u8>,
        image: vector<u8>,
        description: vector<u8>,
    ) {
        f_init_with_image(&sender, name, image, description);
    }

    public(script) fun init_with_image_data(
        sender: signer,
        name: vector<u8>,
        image_data: vector<u8>,
        description: vector<u8>,
    ) {
        f_init_with_image_data(&sender, name, image_data, description);
    }

    public(script) fun mint_with_image(
        sender: signer,
        name: vector<u8>,
        image: vector<u8>,
        description: vector<u8>,
        rarity: u8,
        stamina: u8,
        win_rate_bonus: u8,
    ) acquires ARMNFTCapability, ARMBoxCapability, ARMGallery {
        f_mint_with_image(&sender, name, image, description, rarity, stamina, win_rate_bonus);
    }

    public(script) fun mint_with_image_data(
        sender: signer,
        name: vector<u8>,
        image_data: vector<u8>,
        description: vector<u8>,
        rarity: u8,
        stamina: u8,
        win_rate_bonus: u8,
    ) acquires ARMNFTCapability, ARMBoxCapability, ARMGallery {
        f_mint_with_image_data(&sender, name, image_data, description, rarity, stamina, win_rate_bonus);
    }
}
}
