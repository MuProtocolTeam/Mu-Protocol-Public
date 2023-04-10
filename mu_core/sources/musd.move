// Copyright (c) Joey Yu (yuzhou87@g.ucla.edu)
// SPDX-License-Identifier: MIT

// TODO:
//    1. fix the bug that anyone can call coin::mint_and_transfer<MUSD>() to mint and coin::burn() to burn

// This module defines the mUSD coin and its functionalities 
module mu_core::musd {
   // import modules
   use std::option;
   use sui::transfer;
   use sui::coin::{Self, TreasuryCap, Coin};
   use sui::tx_context::{TxContext};

   // define friends
   friend mu_core::vault;

   // define structs
   struct MUSD has drop {}

   // init function
   fun init (witness: MUSD, ctx: &mut TxContext) {
    // register the new coin and share the treasury_cap object to the public
    let (treasury_cap, metadata) = coin::create_currency<MUSD>(witness, 6, b"mUSD", b"Mu Dollar", b"The CDP stablecoin of the Mu Protocol", option::none(), ctx);
    transfer::public_freeze_object(metadata);
    transfer::public_share_object(treasury_cap) //TODO check for security concerns
   }

   // accessors
   public fun get_total_supply(cap: & TreasuryCap<MUSD>
   ): u64 {
      coin::total_supply(cap)
   }
   public fun get_value(c: & Coin<MUSD>) : u64 {
      coin::value(c)
   }

   // Mint function //TODO overflow concern
   public(friend) fun mint(t_cap: &mut TreasuryCap<MUSD>, amount: u64, recipient: address, ctx: &mut TxContext
   ): (u64, address) {
      coin::mint_and_transfer<MUSD>(t_cap, amount, recipient, ctx);

      (amount, recipient)
   } 

   // Redeem function
   // Note: return the burnted amount of musd
   public(friend) fun redeem(t_cap: &mut TreasuryCap<MUSD>, c: Coin<MUSD>
   ): u64 {
      coin::burn<MUSD>(t_cap, c)
   }




   #[test_only]
   /// Wrapper of module initializer for testing
   public fun test_init(ctx: &mut TxContext) {
      init(MUSD {}, ctx)
   }


}