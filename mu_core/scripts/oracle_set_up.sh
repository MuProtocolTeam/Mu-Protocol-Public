#!/bin/bash

echo "Please enter ID of mu_core package:"
read mu_core

echo "Please enter ID of FactoryOwnerCap (oracle):"
read factory_owner_cap

echo "Creating oracle..."

sui client call --package $mu_core --module oracle --function create_oracle --gas-budget 3000 --args 0 0 100 $factory_owner_cap

echo "Please enter ID of the newly created oracle:"
read new_oralce

echo "Please enter ID of OracleOwnerCap (oracle):"
read oralce_owner_cap

validator=$(sui client active-address)
echo "validator: $validator"

echo "Adding validator..."

sui client call --package $mu_core --module oracle --function list_validator --gas-budget 3000 --args $new_oralce $validator $oralce_owner_cap




