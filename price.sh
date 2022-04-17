#!/bin/bash

# Prerequisite
# 1. must have jq (brew install jq)
# 2. better have watch to continually sh the file (brew install watch)
#
# Usages
# 1. sh price.sh CRYPTO...                        ex: sh price.sh BTC ETH SOL
#    or
# 2. watch -n SECONDS -t -c sh price.sh CRYPTO... ex: watch -n 3 -t -c sh price.sh BTC ETH SOL

myCryptoArray=("$@") 

if [ ${#myCryptoArray[@]} -eq 0 ]; then
  echo  "crypto args are empty"
  exit 0
fi

red='\033[1;31m'
green='\033[1;32m'
cyan='\033[1;36m'
gray='\033[0;37m'
nc='\033[0m'
fireFlag='\xf0\x9f\x94\xa5'

pairBase="USDT"
precision=3
fireVolume=100000000
diffAlertPercent=0.35

pairColor=$cyan
volumeFlag=


round() {
  printf "%.${2}f" "${1}"
}

determinePairColor() {
  kline=$(curl "https://api.binance.com/api/v3/klines?symbol=$1&interval=1m&limit=2" -s | jq '.')
  priceTwoMinsAgo=$(round $(echo $kline | jq .[0][1] | tr -d '"') 5)
  currentPrice=$(round $(echo $kline | jq .[1][4] | tr -d '"') 5)
  diff=$(round $(jq -n $currentPrice-$priceTwoMinsAgo) 5)
  diffAbs=$(echo ${diff#-})
  diffPercent=$(round $(jq -n $diffAbs/$currentPrice * 100) 5)
  diffPositive=$(echo "$diff > 0" | bc )
  diffNegative=$(echo "$diff < 0" | bc )

  if [ $(echo "$diffPercent >= $diffAlertPercent" | bc) -gt 0 ]; then
    if [ $diffPositive -eq 1 ]; then
      pairColor=$red
    elif [ $diffNegative -eq 1 ]; then
      pairColor=$green
    fi
  fi
}

determineFireFlag() {
  quoteVolume=$(round $(echo $1 | jq '.quoteVolume'| tr -d '"') $precision)
  isQuoteVolumeAmple=$(echo "$quoteVolume >= $fireVolume" | bc )
  if [ $isQuoteVolumeAmple -eq 1 ]; then
    volumeFlag=$fireFlag
  fi
}

resetAlert() {
  pairColor=$cyan
  volumeFlag=
}

echo 

for crypto in "${myCryptoArray[@]}"; do
    pair="${crypto}${pairBase}"
    cryptoData=$(curl "https://api.binance.com/api/v3/ticker/24hr?symbol=$pair" -s | jq -c '. | {"lastPrice":.lastPrice, "highPrice":.highPrice, "lowPrice":.lowPrice, "priceChangePercent":.priceChangePercent, "quoteVolume":.quoteVolume}')
    lastPrice=$(round $(echo $cryptoData | jq '.lastPrice'| tr -d '"') $precision)
    highPrice=$(round $(echo $cryptoData | jq '.highPrice'| tr -d '"') $precision)
    lowPrice=$(round $(echo $cryptoData | jq '.lowPrice'| tr -d '"') $precision)
    priceChangePercent=$(round $(echo $cryptoData | jq '.priceChangePercent'| tr -d '"') $precision)

    determineFireFlag $cryptoData
    determinePairColor $pair

    echo "${pairColor}${crypto}/${pairBase}${nc}${volumeFlag} "\\t" ${gray}${lastPrice} / ${priceChangePercent}% "\\t" high=$highPrice / low=$lowPrice ${nc}"

    resetAlert
done

