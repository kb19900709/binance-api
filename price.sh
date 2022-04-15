#!/bin/bash

myCryptoArray=("$@") 

if [ ${#myCryptoArray[@]} -eq 0 ]; then
  echo  "crypto args are empty"
  exit 0
fi

round() {
  printf "%.${2}f" "${1}"
}

pairBase="USDT"
precision=3

echo 

for crypto in "${myCryptoArray[@]}"; do
    pair="${crypto}${pairBase}"
    value=$(round $(curl "https://api.binance.com/api/v3/ticker/price?symbol=$pair" -s | jq '.price' | tr -d '"') ${precision})
    echo $crypto/$pairBase '\t' $value
done

