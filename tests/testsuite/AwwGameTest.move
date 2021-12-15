//! new-transaction
//! account: bob
//! sender: bob
address bob = {{bob}};
script {
    use 0x16a8bf4d0c3718518d81f132801e4aaa::ARM::{ARMMeta, ARMBody};
    use 0x1::NFTGallery;

    fun acceptArm(sender: signer) {
        NFTGallery::accept<ARMMeta, ARMBody>(&sender);
    }
}

//! new-transaction
//! account: aww, 0x16a8bf4d0c3718518d81f132801e4aaa
//! sender: aww
address aww = {{aww}};
address bob = {{bob}};
script {
    use 0x16a8bf4d0c3718518d81f132801e4aaa::ARM;
    use 0x16a8bf4d0c3718518d81f132801e4aaa::AWWGame;
    use 0x1::Signer;
    use 0x1::NFTGallery;

    fun mint_arm(sender: signer) {
        ARM::f_init_with_image(&sender, b"aww arm", b"www.baidu.com", b"this is a arm");
        ARM::f_mint_with_image(&sender, b"aww arm", b"www.baidu.com", b"this is a arm", 1u8, 3u8, 20u8);
        assert(ARM::count_of(Signer::address_of(&sender))==1, 10001);
        AWWGame::init_game(&sender);
        assert(NFTGallery::is_accept<ARM::ARMMeta, ARM::ARMBody>(@bob), 10002);
        ARM::airdrop_arm(&sender, @bob);
    }
}

//! new-transaction
//! sender: bob
address bob = {{bob}};
script {
    use 0x16a8bf4d0c3718518d81f132801e4aaa::AWWGame;

    fun fight(sender: signer) {
        AWWGame::fight(&sender, 1u64, 2u8);
        AWWGame::fight(&sender, 1u64, 2u8);
        AWWGame::fight(&sender, 1u64, 2u8);
    }
}
// check: EXECUTED

//! new-transaction
//! sender: bob
address bob = {{bob}};
address aww = {{aww}};
script {
    use 0x16a8bf4d0c3718518d81f132801e4aaa::AWWGame;
    use 0x16a8bf4d0c3718518d81f132801e4aaa::AWW::AWW;
    use 0x1::Account;
    use 0x1::Signer;
    use 0x1::Debug;

    fun harvest_reward(sender: signer) {
        AWWGame::harvest_reward(&sender);
        let balance = Account::balance<AWW>(Signer::address_of(&sender));
        Debug::print<u128>(&balance);
        balance = Account::balance<AWW>(@aww);
        Debug::print<u128>(&balance);
    }
}
// check: EXECUTED

//! new-transaction
//! sender: bob
address bob = {{bob}};
script {
    use 0x16a8bf4d0c3718518d81f132801e4aaa::AWWGame;

    fun fight(sender: signer) {
        AWWGame::fight(&sender, 1u64, 0u8);
    }
}
// check: ABORTED
