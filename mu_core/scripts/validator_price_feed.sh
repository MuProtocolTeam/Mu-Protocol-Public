#!/bin/bash

echo "Please enter ID of mu_core package:"
read mu_core

echo "Please enter ID of oracle:"
read target_oracle

echo "Please enter ID of validator cap:"
read validator_cap

# Define an array of elements
prices=(100 105 110 90)
decimal=2

# Initialize a counter variable
counter=0

# Loop through the array and print one element every 10 seconds
while true
do
  echo "updating price: ${prices[counter]}"
  sui client call --package $mu_core --module oracle --function write_data --gas-budget 3000 --args $target_oracle $validator_cap $(date +%s) ${prices[counter]} $decimal
  ((counter++))
  if [ $counter -eq ${#elements[@]} ]; then
    counter=0
  fi
  sleep 10
done