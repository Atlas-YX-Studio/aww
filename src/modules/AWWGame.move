address 0x49142e24bf3b34b323b3bd339e2434e3 {
module AWWGame {
    use 0x1::Signer;
    use 0x1::Event;
    use 0x1::Token;
    use 0x1::Account;
    use 0x1::Timestamp;
    use 0x1::Option;
    use 0x1::Math;
    use 0x1::NFTGallery;
    use 0x49142e24bf3b34b323b3bd339e2434e3::ARM;
    use 0x49142e24bf3b34b323b3bd339e2434e3::AWW::{Self, AWW};

    const ARM_ADDRESS: address = @0x49142e24bf3b34b323b3bd339e2434e3;

    const PERMISSION_DENIED: u64 = 100001;

    const LEVEL_ERROR: u64 = 100002;

    const NO_REWARDS_ERROR: u64 = 100003;

    const ARM_NOT_ON_SALE: u64 = 100004;

    const ARM_SOLD_OUT: u64 = 100005;

    const DAY_FACTOR: u64 = 86400;

    struct FightEvent has drop, store {
        player: address,
        arm_id: u64,
        level: u8,
        victory: bool,
        reward: u128,
    }

    struct HarvestRewardEvent has drop, store {
        player: address,
        taxes_amount: u128,
        reward_amount: u128,
    }

    struct PlayerRewardPool has key, store {
        time: u64,
        reward: Token::Token<AWW>,
        fight_events: Event::EventHandle<FightEvent>,
        harvest_reward_events: Event::EventHandle<HarvestRewardEvent>,
    }

    struct SharedMintCapability has key, store {
        cap: Token::MintCapability<AWW>
    }

    struct GameConfig has key, store {
        arm_selling_end_time: u64
    }

    public fun init_game(account: &signer, arm_selling_end_time: u64) {
        assert(Signer::address_of(account) == ARM_ADDRESS, PERMISSION_DENIED);
        let cap = AWW::remove_mint_capability(account);
        move_to(account, SharedMintCapability{
            cap
        });
        move_to(account, GameConfig{
            arm_selling_end_time
        });
    }

    public fun mint_aww_to(
        account: &signer,
        amount: u128,
        address: address
    ) acquires SharedMintCapability {
        assert(Signer::address_of(account) == ARM_ADDRESS, PERMISSION_DENIED);
        let cap = borrow_global_mut<SharedMintCapability>(ARM_ADDRESS);
        let aww_token = AWW::mint_with_capability(&cap.cap, amount);
        Account::deposit<AWW>(address, aww_token);
    }

    public fun update_game_config(account: &signer, arm_selling_end_time: u64) acquires GameConfig {
        assert(Signer::address_of(account) == ARM_ADDRESS, PERMISSION_DENIED);
        let game_config = borrow_global_mut<GameConfig>(ARM_ADDRESS);
        game_config.arm_selling_end_time = arm_selling_end_time;
    }

    public fun arm_mint(
        account: &signer
    ) acquires GameConfig {
        let game_config = borrow_global<GameConfig>(ARM_ADDRESS);
        assert(Timestamp::now_milliseconds() < game_config.arm_selling_end_time, ARM_NOT_ON_SALE);
        assert(ARM::count_of(ARM_ADDRESS) > 0, ARM_SOLD_OUT);
        ARM::get_arm(account);
    }

    public fun airdrop_arm(sender: &signer, reciver: address) {
        ARM::airdrop_arm(sender, reciver);
    }

    public fun fight(
        account: &signer,
        arm_id: u64,
        level: u8
    ) acquires PlayerRewardPool, SharedMintCapability {
        assert(level < 3, LEVEL_ERROR);

        let player = Signer::address_of(account);
        if (!exists<PlayerRewardPool>(player)) {
            move_to(account, PlayerRewardPool{
                time: Timestamp::now_seconds(),
                reward: Token::zero<AWW>(),
                fight_events: Event::new_event_handle<FightEvent>(account),
                harvest_reward_events: Event::new_event_handle<HarvestRewardEvent>(account),
            })
        };
        let user_reward_pool = borrow_global_mut<PlayerRewardPool>(player);
        let cap = borrow_global_mut<SharedMintCapability>(ARM_ADDRESS);

        // Withdraw one ARM token from your account
        let option_arm = NFTGallery::withdraw<ARM::ARMMeta, ARM::ARMBody>(account, arm_id);
        let arm = Option::destroy_some(option_arm);
        ARM::f_deduction_stamina(&mut arm);

        // fight arguments
        let reward_amount = ARM::get_aww_amount(7000000000u128);
        let win_rate = ARM::f_get_win_rate_bonus(&arm);
        if (level == 0u8) {
            win_rate = win_rate + 80u8;
        } else if (level == 1u8) {
            reward_amount = Math::mul_div(reward_amount, 15u128, 10u128);
            win_rate = win_rate + 40u8;
        } else if (level == 2u8) {
            reward_amount = reward_amount * 2u128;
            win_rate = win_rate + 20u8;
        };
        let result = ARM::random(100u64);

        // victory
        if (result < (win_rate as u64)) {
            let reward = AWW::mint_with_capability(&cap.cap, reward_amount);
            Token::deposit<AWW>(&mut user_reward_pool.reward, reward);
            Event::emit_event(&mut user_reward_pool.fight_events,
                FightEvent {
                    player,
                    arm_id,
                    level,
                    victory: true,
                    reward: reward_amount,
                }
            );
        } else {
            Event::emit_event(&mut user_reward_pool.fight_events,
                FightEvent {
                    player,
                    arm_id,
                    level,
                    victory: false,
                    reward: 0u128,
                }
            );
        };

        NFTGallery::deposit_to<ARM::ARMMeta, ARM::ARMBody>(player, arm);
    }

    public fun harvest_reward(
        account: &signer
    ) acquires PlayerRewardPool {
        let player = Signer::address_of(account);
        assert(exists<PlayerRewardPool>(player), NO_REWARDS_ERROR);
        let user_reward_pool = move_from<PlayerRewardPool>(player);
        let PlayerRewardPool {
        time,
        reward,
        fight_events,
        harvest_reward_events,
        } = user_reward_pool;

        let now = Timestamp::now_seconds();
        let discount = (now - time) / DAY_FACTOR * 2;
        let tax_rate = if (discount > 30) {
            0
        } else {
            30 - discount
        };

        let taxes_amount = Token::value<AWW>(&reward) * (tax_rate as u128) / 100;
        let taxes = Token::withdraw<AWW>(&mut reward, taxes_amount);

        let reward_amount = Token::value<AWW>(&reward);

        let is_accept_token = Account::is_accepts_token<AWW>(player);
        if (!is_accept_token) {
            Account::do_accept_token<AWW>(account);
        };
        Account::deposit<AWW>(player, reward);
        Account::deposit<AWW>(ARM_ADDRESS, taxes);

        Event::emit_event(&mut harvest_reward_events,
            HarvestRewardEvent {
                player,
                taxes_amount,
                reward_amount,
            }
        );
        Event::destroy_handle(harvest_reward_events);
        Event::destroy_handle(fight_events);
    }
}
}
