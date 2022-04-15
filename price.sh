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
precision=2

echo 

for crypto in "${myCryptoArray[@]}"; do
    pair="${crypto}${pairBase}"
    cryptoData=$(curl "https://api.binance.com/api/v3/ticker/24hr?symbol=$pair" -s | jq '. | {"lastPrice":.lastPrice, "highPrice":.highPrice, "lowPrice":.lowPrice, "priceChangePercent":.priceChangePercent}')
    lastPrice=$(round $(echo $cryptoData | jq '.lastPrice'| tr -d '"') ${precision})
    highPrice=$(round $(echo $cryptoData | jq '.highPrice'| tr -d '"') ${precision})
    lowPrice=$(round $(echo $cryptoData | jq '.lowPrice'| tr -d '"') ${precision})
    priceChangePercent=$(round $(echo $cryptoData | jq '.priceChangePercent'| tr -d '"') ${precision})
    echo "${crypto}/${pairBase} "\\t" $lastPrice / $priceChangePercent% "\\t" high=$highPrice / low=$lowPrice"
done

