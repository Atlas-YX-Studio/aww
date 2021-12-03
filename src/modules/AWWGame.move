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

    public fun arm_mint(
        account: signer
    ) {

    }

    public fun fight(
        account: signer,
        id: u64,
        level: u8
    ) {

    }

    public fun harvest_reward(
        account: signer
    ) {

    }
}
}
