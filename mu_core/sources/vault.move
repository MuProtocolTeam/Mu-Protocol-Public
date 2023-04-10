// Copyright (c) Joey Yu (yuzhou87@g.ucla.edu)
// SPDX-License-Identifier: MIT

//TODO:
// 1. remove the assumption that collateral and musd have the same precision [DONE]
// 2. change liquidation_ratio_prec from precision into decimals; differentiate "value" and "monetary value" in function name etc
// 3. change mul and div from plain arithmetics into library calls
// 4. add decimal info into vault
// 5. change the oracle reference from user's input into registry's field or some authroized sources
// 6. make debt a balance rather a number


// This module defines the vault of the Mu protocol
module mu_core::vault {
    // import modules
    use mu_core::collateral::{COLLATERAL};
    use mu_core::musd::{Self, MUSD};
    use mu_core::oracle::{Self, Oracle};

    use sui::transfer;
    use sui::balance::{Self, Balance};
    use sui::object::{Self, UID, ID};
    use sui::coin::{Self, Coin, TreasuryCap, CoinMetadata};
    use sui::math;
    use sui::tx_context::{Self, TxContext};

    // define structs
    struct Registry has key {
        id: UID,
        global_debt: u64,
        global_collateral: u64,
        liquidation_ratio: u64, 
        ratio_prec: u64,
    }

    struct Vault has key {
        id: UID,
        vault_debt: u64,                        // in musd amount
        vault_collateral: Balance<COLLATERAL>,  // in collateral amount
        owner: address,
    }

    struct VaultKey has key {
        id: UID,
        vault_id: ID,   // the UID value of its corresponding vault
    }

    // define constants
    const RATIO_PRECISION: u64 = 10000;
    const BASE_TEN: u64 = 10;
    const ZERO: u64 = 0;


    const EBadDepositRatio: u64 = 1;
    const EAmountOrRecipientMismatch: u64 = 2;
    const ENotVaultOwner: u64 = 3;
    const EWrongKey: u64 = 4;
    const EZeroCollateral: u64 = 5;
    const EWrongCollateralAmount: u64 = 6;
    const EWrongMUSDAmount: u64 = 7;
    const EWrongBurntAmount: u64 = 8;
    const EDivideByZero: u64 = 41;


    // init function and one-time function
    fun init(ctx: &mut TxContext) {
        transfer::share_object(Registry {   //TODO check security concerns
            id: object::new(ctx),
            global_debt: 0,                 
            global_collateral: 0,           
            liquidation_ratio: 11000,       // i.e., 110%
            ratio_prec: RATIO_PRECISION,
        })
    }

    ////////////////////////
    // ACCESSORS
    ////////////////////////
    public fun get_global_debt(registry: & Registry): u64 {
        registry.global_debt
    }
    public fun get_global_collateral(registry: & Registry): u64 {
        registry.global_collateral
    }
    public fun get_liquidation_ratio_prec(registry: & Registry): (u64, u64) {
        (registry.liquidation_ratio, registry.ratio_prec)
    }
    public fun get_vault_id(vault: & Vault): ID {
        object::uid_to_inner(& vault.id)
    }
    public fun get_vault_debt(vault: & Vault): u64 {
        vault.vault_debt
    }
    public fun get_vault_balance(vault: & Vault): u64 {
        balance::value(& vault.vault_collateral)
    }
    public fun get_vault_owner(vault: & Vault): address {
        vault.owner
    }
    public fun get_key_info(key: & VaultKey): ID {
        key.vault_id
    }

    ///////////////////////
    // PURE FUNCTIONS
    ///////////////////////
    
    // calculate the value of collateral given its amount
    // Note: precision of the value depends on the choice of oracle
    public fun get_col_value_prec(col_amount: u64, col_metadata: & CoinMetadata<COLLATERAL>, price_oracle: & Oracle
    ): (u64, u64) {
        let (col_price, col_price_prec) = oracle::read_data_prec(price_oracle);
        let col_prec = decimal_to_prec(coin::get_decimals<COLLATERAL>(col_metadata));
        
        (col_amount * col_price / col_prec, col_price_prec)
    }

    // calculate the value of musd given its amount
    // Note: in Mu protocol, one musd is always viewed as one US Dolalr
    // Note: precision of the value depends on the choice of oracle
    public fun get_musd_value_prec(musd_amount: u64, musd_metadata: & CoinMetadata<MUSD>, price_oracle: & Oracle
    ): (u64, u64) {
        let musd_prec = decimal_to_prec(coin::get_decimals<MUSD>(musd_metadata));
        let (_, price_prec) = oracle::read_data_prec(price_oracle);
        (musd_amount * price_prec / musd_prec, price_prec)
    }

    // calculate the expected collateral ratio and its precision with given expected collateral amount and debt amount
    public fun get_expected_vault_ratio_prec(registry: & Registry,
                                    expected_col_amount: u64, col_metadata: & CoinMetadata<COLLATERAL>,
                                    expected_debt_amount: u64, musd_metadata: & CoinMetadata<MUSD>,
                                    price_oracle: & Oracle)
    : (u64, u64) {
        let (col_value, _) = get_col_value_prec(expected_col_amount, col_metadata, price_oracle);
        let (debt_value, _) = get_musd_value_prec(expected_debt_amount, musd_metadata, price_oracle);
        assert!(debt_value != ZERO, EDivideByZero);
        let (_, ratio_prec) = get_liquidation_ratio_prec(registry);
        (col_value * ratio_prec / debt_value, ratio_prec)
    }

    // calculate the current collateral ratio and its precision of a given vault
    public fun get_vault_ratio_prec(registry: & Registry, vault: & Vault, 
                                    col_metadata: & CoinMetadata<COLLATERAL>, musd_metadata: & CoinMetadata<MUSD>,
                                    price_oracle: & Oracle
    ): (u64, u64) {
        get_expected_vault_ratio_prec(registry,
                                    get_vault_balance(vault), col_metadata,
                                    get_vault_debt(vault), musd_metadata,
                                    price_oracle)
    }

    ///////////////////////
    // FUNCTIONS
    ///////////////////////

    // Open a vault
    entry public fun open_vault(ctx: &mut TxContext) {
        //TODO: check if the user has already opened an identical vault
        let vault_id = object::new(ctx);
        let vault_id_value = object::uid_to_inner(& vault_id);
        let owner = tx_context::sender(ctx);

        // create a vault
        transfer::share_object(Vault {
            id: vault_id,
            vault_debt: ZERO,
            vault_collateral: balance::zero<COLLATERAL>(),
            owner,
        });
        // create the vault's cap and transfer to the sender
        transfer::transfer(VaultKey {
            id: object::new(ctx),
            vault_id: vault_id_value,
        }, owner)

    }

    // Mint function TODO: (i). mint without collateral
    // Note: if musd_amount == 0, this function is essentially an addCollateral() function
    entry public fun mint(registry: &mut Registry, vault: &mut Vault, key: & VaultKey,
                        collateral: Coin<COLLATERAL>, col_metadata: & CoinMetadata<COLLATERAL>, price_oracle: & Oracle,
                        musd_cap: &mut TreasuryCap<MUSD>, musd_metadata: & CoinMetadata<MUSD>, musd_amount: u64, ctx: &mut TxContext) {
        
        // check if the key matches the vault (at same time, check if the caller is the owner of the vault)
        assert!(get_key_info(key) == get_vault_id(vault), EWrongKey);
        // check if collateral coin is empty
        let col_amount = coin::value(&collateral);
        assert!(col_amount > ZERO, EWrongCollateralAmount);                                                             
 
        // if user requests to mint new mUSD, check if collateral ratio meets the minimum requirement
        if (musd_amount != ZERO) {
            let expected_new_vault_col_amount = get_vault_balance(vault) + col_amount;
            let expected_new_vault_debt_amount = get_vault_debt(vault) + musd_amount;
            let (expected_new_ratio, _) = get_expected_vault_ratio_prec(registry,
                                            expected_new_vault_col_amount, col_metadata,
                                            expected_new_vault_debt_amount, musd_metadata,
                                            price_oracle);
            let (min_ratio, _) = get_liquidation_ratio_prec(registry);
            assert!(expected_new_ratio >= min_ratio, EBadDepositRatio);                                                 // the new collateral ratio should meet minimum ratio requirement
        };

        // deposit collateral into sender's vault and update the global registry
        coin::put(&mut vault.vault_collateral, collateral);
        registry.global_collateral = registry.global_collateral + col_amount;

        // if user requests to mint new mUSD, mint mUSD and send it to user and udpate the global registry and vault
        if (musd_amount != ZERO) {
            let (minted_amount, recipient) = musd::mint(musd_cap, musd_amount, tx_context::sender(ctx), ctx);
            assert!(minted_amount == musd_amount && recipient == tx_context::sender(ctx), EAmountOrRecipientMismatch);  // check if minted musd_amount and recipient address match
            registry.global_debt = registry.global_debt + musd_amount; 
            vault.vault_debt = vault.vault_debt + minted_amount;
        };
    }

    // mint musd without depositing collateral
    // Note: this action will decrease collateral ratio of the vault
    entry public fun free_mint(registry: &mut Registry, vault: &mut Vault, key: & VaultKey,
                            col_metadata: & CoinMetadata<COLLATERAL>, price_oracle: & Oracle,
                            musd_cap: &mut TreasuryCap<MUSD>, musd_metadata: & CoinMetadata<MUSD>, musd_amount: u64, ctx: &mut TxContext) {
        
        // check if the key matches the vault (at same time, check if the caller is the owner of the vault)
        assert!(get_key_info(key) == get_vault_id(vault), EWrongKey);
        // check if musd_amount if non-zero
        assert!(musd_amount > ZERO, EWrongMUSDAmount);

        // check request's legitimacy
        let vault_col_amount = get_vault_balance(vault);
        let expected_new_vault_debt_amount = get_vault_debt(vault) + musd_amount;
        let (expected_new_ratio, _) = get_expected_vault_ratio_prec(registry,
                                        vault_col_amount, col_metadata,
                                        expected_new_vault_debt_amount, musd_metadata,
                                        price_oracle);
        let (min_ratio, _) = get_liquidation_ratio_prec(registry);
        assert!(expected_new_ratio >= min_ratio, EBadDepositRatio);                                                 // the new collateral ratio should meet minimum ratio requirement

        // mint mUSD and update registry's and vault's records
        let (minted_amount, recipient) = musd::mint(musd_cap, musd_amount, tx_context::sender(ctx), ctx);
        assert!(minted_amount == musd_amount && recipient == tx_context::sender(ctx), EAmountOrRecipientMismatch);  // check if minted musd_amount and recipient address match
        registry.global_debt = registry.global_debt + musd_amount; 
        vault.vault_debt = vault.vault_debt + minted_amount;
    }

    // TODO: 1. accomodate (i) complete redeem, i.e., clear vault
    // Redeem function
    // Note: if collateral withdrawl amount == 0, this funciton is essentially payDebt()
    entry public fun redeem(registry: &mut Registry, vault: &mut Vault, key: & VaultKey,
            musd_cap: &mut TreasuryCap<MUSD>, musd_metadata: & CoinMetadata<MUSD>, musd_coin: Coin<MUSD>,
            col_amount: u64, col_metadata: & CoinMetadata<COLLATERAL>, price_oracle: & Oracle, ctx: &mut TxContext) {
        
        // check if the key matches the vault (at same time, check if the caller is the owner of the vault)
        assert!(get_key_info(key) == get_vault_id(vault), EWrongKey);
        // check if musd coin is empty
        let musd_to_burn_amount = coin::value(& musd_coin);
        assert!(musd_to_burn_amount > ZERO, EWrongMUSDAmount);
        
        // check request's legitimacy
        let vault_debt_amount = get_vault_debt(vault);
        assert!(musd_to_burn_amount <= vault_debt_amount, EWrongMUSDAmount);                   // users should not over-pay their debts
        let expected_new_vault_debt_amount = vault_debt_amount - musd_to_burn_amount;
        if (col_amount != ZERO) {
            let vault_col_amount = get_vault_balance(vault);
            assert!(col_amount <= vault_col_amount, EWrongCollateralAmount);                  // users should not withdraw more than they have in their vaults 
            if (expected_new_vault_debt_amount != ZERO) {
                let expected_new_vault_col_amount = vault_col_amount - col_amount;
                let (expected_new_ratio, _) = get_expected_vault_ratio_prec(registry,
                                            expected_new_vault_col_amount, col_metadata,
                                            expected_new_vault_debt_amount, musd_metadata,
                                            price_oracle);
                let (min_ratio, _) = get_liquidation_ratio_prec(registry);
                assert!(expected_new_ratio >= min_ratio, EBadDepositRatio);                   // the new collateral ratio should meet minimum ratio requirement
            }
        };

        // burn musd coin and update registry's and vault' record
        let burnt_amount = musd::redeem(musd_cap, musd_coin);
        assert!(burnt_amount == musd_to_burn_amount, EWrongBurntAmount);
        vault.vault_debt = expected_new_vault_debt_amount;
        registry.global_debt = registry.global_debt - musd_to_burn_amount;

        // transfer collateral amount and update registry's and vault's record
        if (col_amount != ZERO) {
            let col_transfer_coin = coin::from_balance<COLLATERAL>(balance::split<COLLATERAL>(&mut vault.vault_collateral, col_amount), ctx);
            assert!(coin::value<COLLATERAL>(& col_transfer_coin) == col_amount, EAmountOrRecipientMismatch);
            transfer::public_transfer<Coin<COLLATERAL>>(col_transfer_coin, tx_context::sender(ctx));
            registry.global_collateral = registry.global_collateral - col_amount;
        };
    }

    // take out some collateral without paying back any debt musd
    // Note: this action will decrease collateral ratio of the vault
    entry public fun pure_withdraw(registry: &mut Registry, vault: &mut Vault, key: & VaultKey, musd_metadata: & CoinMetadata<MUSD>,
             col_amount: u64, col_metadata: & CoinMetadata<COLLATERAL>, price_oracle: & Oracle, ctx: &mut TxContext) {
        
        // check if the key matches the vault (at same time, check if the caller is the owner of the vault)
        assert!(get_key_info(key) == get_vault_id(vault), EWrongKey);
        // check if col_amount is non-zero
        assert!(col_amount > ZERO, EWrongCollateralAmount);

        // check request's legitimacy
        let vault_col_amount = get_vault_balance(vault);
        assert!(col_amount <= vault_col_amount, EWrongCollateralAmount);                 // users should not withdraw more than they have in their vaults 
        let vault_debt_amount = get_vault_debt(vault);
        if (vault_debt_amount != ZERO) {
            let expected_new_vault_col_amount = vault_col_amount - col_amount;
            let (expected_new_ratio, _) = get_expected_vault_ratio_prec(registry,
                                            expected_new_vault_col_amount, col_metadata,
                                            vault_debt_amount, musd_metadata,
                                            price_oracle);
            let (min_ratio, _) = get_liquidation_ratio_prec(registry);
            assert!(expected_new_ratio >= min_ratio, EBadDepositRatio);                  // the new collateral ratio should meet minimum ratio requirement
        };

        // transfer collateral amount and update registry's and vault's record
        let col_transfer_coin = coin::from_balance<COLLATERAL>(balance::split<COLLATERAL>(&mut vault.vault_collateral, col_amount), ctx);
        assert!(coin::value<COLLATERAL>(& col_transfer_coin) == col_amount, EAmountOrRecipientMismatch);
        transfer::public_transfer<Coin<COLLATERAL>>(col_transfer_coin, tx_context::sender(ctx));
        registry.global_collateral = registry.global_collateral - col_amount;
    }

    ///////////////////////////////////////////////////////////////////
    //                  INTERNAL UTILITY FUNCTIONS                   //
    ///////////////////////////////////////////////////////////////////
    
    // return its precision given a decimal
    fun decimal_to_prec(decimal: u8
    ): u64 {
        math::pow(BASE_TEN, decimal)
    }

    ///////////////////////////////////////////////////////////////////
    //                  TEST_ONLY FUNCTIONS                          //
    ///////////////////////////////////////////////////////////////////

    #[test_only]
   /// Wrapper of module initializer for testing
   public fun test_init(ctx: &mut TxContext) {
      init(ctx)
   }
    
}