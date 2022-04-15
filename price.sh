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

red='\033[1;31m'
green='\033[1;32m'
cyan='\033[1;36m'
gray='\033[0;37m'
nc='\033[0m'

echo 

for crypto in "${myCryptoArray[@]}"; do
    pair="${crypto}${pairBase}"
    cryptoData=$(curl "https://api.binance.com/api/v3/ticker/24hr?symbol=$pair" -s | jq '. | {"lastPrice":.lastPrice, "highPrice":.highPrice, "lowPrice":.lowPrice, "priceChangePercent":.priceChangePercent, "quoteVolume":.quoteVolume}')
    lastPrice=$(round $(echo $cryptoData | jq '.lastPrice'| tr -d '"') $precision)
    highPrice=$(round $(echo $cryptoData | jq '.highPrice'| tr -d '"') $precision)
    lowPrice=$(round $(echo $cryptoData | jq '.lowPrice'| tr -d '"') $precision)
    priceChangePercent=$(round $(echo $cryptoData | jq '.priceChangePercent'| tr -d '"') $precision)
    echo "${cyan}${crypto}/${pairBase}${nc} "\\t" ${gray}${lastPrice} / ${priceChangePercent}% "\\t" high=$highPrice / low=$lowPrice ${nc}"
done

