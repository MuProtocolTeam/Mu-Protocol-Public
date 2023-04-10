// Modified https://github.com/pentagonxyz/move-oracles/blob/master/sources/oracle_factory.move
// Create and share price oracles.
module mu_core::oracle{
    use sui::math;
    use sui::object::{Self, ID, UID};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer::{Self};
    use std::vector;

    ///*///////////////////////////////////////////////////////////////
    //                          MAIN OBJECTS                         //
    /////////////////////////////////////////////////////////////////*/

    // This object represents an oracle. It hold metadata for the oracle along with the data that the oracle is supposed to return.
    struct Oracle has key, store {
        id: UID,
        last_update: u64,           // Timestamp of the last update.
        interval: u64,              // Time between updates.
        min_posts: u64,             // Minimum posts required to update the price.
        new_data: vector<Data>,     // Vector containing posted data.
        data: Data,                 // Most recent updated price (average of all written information since the last update).
        decimal: u8,                // Decimal of price data

    }
    
    // Represents data held by the oracle.
    // Implemented to make it easier to fork the module to return more than just prices.
    struct Data has store, drop {
        // Price Data stored by the oracle.
        price: u64,
    }

    ///*///////////////////////////////////////////////////////////////
    //                          CAPABILITIES                         //
    /////////////////////////////////////////////////////////////////*/
    
    struct FactoryOwnerCap has key, store {
        id: UID
    }

    // Created when a new oracle is generated.
    // Represents ownership, enabling the holder to list/unlist validators.
    struct OracleOwnerCap has key, store {
        id: UID,
        oracle_id: ID,              // The ID of the oracle that is owned by this contract.
    }

    // Created when a validator is listed by the oracle owner, grants the ability to write data to the oracle.
    struct ValidatorCap has key, store {
        id: UID,
        oracle_id: ID,              // The ID of the oracle that the validator can push information to.
    }

    ///*///////////////////////////////////////////////////////////////
    //                     ERROR CODES & CONSTANTS                   //
    /////////////////////////////////////////////////////////////////*/

    const EOwnerOnly: u64 = 0;      // Attempt to perform an operation only allowed by the owner.
    const EValidatorOnly: u64 = 1;  // Attempt to perform an operation only allowed by a validator.
    const BASE_TEN: u64 = 10;

    ///*///////////////////////////////////////////////////////////////
    //                     ORACLE CREATION LOGIC                     //
    /////////////////////////////////////////////////////////////////*/
    
    fun init (ctx: &mut TxContext) {
        let factoryOwnerCap = FactoryOwnerCap {
            id: object::new(ctx)
        };
        transfer::transfer(factoryOwnerCap, tx_context::sender(ctx));
    }

    // Initialize a new oracle and send the owner capability directly to the function caller.
    public fun new_oracle(interval: u64, min_posts: u64, decimal: u8, ctx: &mut TxContext
    ): OracleOwnerCap {
        // Create a new Oracle object. Make it shared so that it can be accessed by anyone.
        let oracle = Oracle {
            id: object::new(ctx),
            last_update: 0,
            interval,
            min_posts,
            new_data: vector<Data>[],
            data: Data {
                price: 0,
            },
            decimal,
        };
        let oracle_id = object::uid_to_inner(&oracle.id);
        transfer::share_object(oracle);
    
        // Create a new OwnerCap object and return it to the caller.
        OracleOwnerCap {
            id: object::new(ctx),
            oracle_id,
        }
    }

    // Create a new oracle and send the owner capability to the sender of the tx origin.
    public entry fun create_oracle(interval: u64, min_posts: u64, decimal: u8, _: &FactoryOwnerCap, ctx: &mut TxContext) {
        transfer::transfer(new_oracle(interval, min_posts, decimal, ctx), tx_context::sender(ctx));
    }

    ///*///////////////////////////////////////////////////////////////
    //                   VALIDATOR LISTING FUNCTIONS                 //
    /////////////////////////////////////////////////////////////////*/

    // List a new validator (can only be called by the owner).
    public entry fun list_validator(self: &mut Oracle, validator: address, oracle_owner_cap: &OracleOwnerCap, ctx: &mut TxContext) {
        // Check if the caller is the owner of the referenced oracle.
        check_owner(self, oracle_owner_cap);

        // Create a new ValidatorCap object.
        let oracle_id = object::uid_to_inner(&self.id);
        let validator_cap = ValidatorCap {
            id: object::new(ctx),
            oracle_id,
        };

        // Transfer the validator capability to the validator.
        transfer::transfer(validator_cap, validator);
    }


    ///*///////////////////////////////////////////////////////////////
    //                    PRICE POSTS + UPDATE LOGIC                 //
    /////////////////////////////////////////////////////////////////*/

    // Force the oracle to update its pricing data (can only be called by the owner of the oracle).
    public fun force_update(self: &mut Oracle, oracle_owner_cap: & OracleOwnerCap, timestamp: u64
    ): u64 {
        // Check if the caller is the owner of the referenced oracle.
        check_owner(self, oracle_owner_cap);

        // Update the pricing data.
        update_data(self, timestamp)
    }

    // TODO: fix this function
    // current error: ExecutionError { inner: ExecutionErrorInner { kind: SuiMoveVerificationError, source: Some("Invalid entry point parameter type. Expected primitive or object type. Got: 0x1::price_oracle_factory::Data") } }

    // Write data to the oracle (can only be called by a validator).
    public entry fun write_data(self: &mut Oracle, validator_cap: & ValidatorCap, timestamp: u64, price: u64, price_decimal: u8) {
        // Ensure the caller is a verified validator.
        check_validator(self, validator_cap);

        // Convert data precision and push the data to the Oracle object's `new_data` vector 
        let converted_price = price * decimal_to_prec(self.decimal) / decimal_to_prec(price_decimal);
        vector::push_back(&mut self.new_data, Data { price: converted_price });

        // If the oracle has enough posts or has not been updated within its interval, update the data.
        if(vector::length(&self.new_data) >= self.min_posts || timestamp - self.last_update > self.interval) {
            // Update the data.
            update_data(self, timestamp);
        }
    }

    // Update the oracle's data by calculating the averages of the supplied information. Return the new price.
    fun update_data(self: &mut Oracle, timestamp: u64): u64 {
        // Calculate the average of all data in the `new_data` vector.
        let total = 0;
        let data_vector = &mut self.new_data;
        let size = vector::length(data_vector);
        
        let i = 0;
        while(size>i) {
            let data = vector::borrow(data_vector, i);
            total = total + data.price;
            i = i + 1;
        };

        // Calculate the average price.
        let average = total / size;

        // Update the new price, clear the `new_data` vector, and update the `last_update` timestamp.
        self.data.price = *&average;
        self.new_data = vector<Data>[];
        self.last_update = timestamp;

        average
    }

    ///*///////////////////////////////////////////////////////////////
    //                           VIEW METHODS                        //
    /////////////////////////////////////////////////////////////////*/

    // This function can be called by anyone to read an oracle's data.
    public fun read_data_prec(self: &Oracle,
    ): (u64, u64) {
        (self.data.price, decimal_to_prec(self.decimal))
    }

    ///*///////////////////////////////////////////////////////////////
    //                  INTERNAL UTILITY FUNCTIONS                   //
    /////////////////////////////////////////////////////////////////*/

    // Ensure that an OracleOwnerCap object matches the oracle object.
    fun check_owner(self: &Oracle, admin_cap: &OracleOwnerCap) {
        // Ensure the caller is the owner of the Oracle object.
        assert!(&object::uid_to_inner(&self.id) == &admin_cap.oracle_id, EOwnerOnly);
    }

    // Ensure that an ValidatorCap object matches the oracle object.
    fun check_validator(self: &Oracle, validator_cap: &ValidatorCap) {
        // Ensure the caller is a verified validator of the Oracle object.
        assert!(&object::uid_to_inner(&self.id) == &validator_cap.oracle_id, EValidatorOnly);
    }

    // return its precision given a decimal
    fun decimal_to_prec(decimal: u8
    ): u64 {
        math::pow(BASE_TEN, decimal)
    }

    #[test_only]
   /// Wrapper of module initializer for testing
   public fun test_init(ctx: &mut TxContext) {
      init(ctx)
   }
}