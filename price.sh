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
closeToHighOrLowPercent=0.5

priceColor=
volumeFlag=
highFlag=
lowFlag=


round() {
  printf "%.${2}f" "${1}"
}

determinePriceColor() {
  kline=$(curl "https://api.binance.com/api/v3/klines?symbol=$1&interval=1m&limit=2" -s | jq '.')
  priceTwoMinsAgo=$(round $(echo $kline | jq .[0][1] | tr -d '"') 5)
  currentPrice=$(round $(echo $kline | jq .[1][4] | tr -d '"') 5)
  diff=$(round $(jq -n $currentPrice-$priceTwoMinsAgo) 5)
  diffAbs=$(echo ${diff#-})
  diffPercent=$(round $(jq -n $diffAbs/$currentPrice*100) 5)
  diffPositive=$(echo "$diff > 0" | bc )
  diffNegative=$(echo "$diff < 0" | bc )

  priceColor=$gray
  if [ $(echo "$diffPercent >= $diffAlertPercent" | bc) -gt 0 ]; then
    if [ $diffPositive -eq 1 ]; then
      priceColor=$red
    elif [ $diffNegative -eq 1 ]; then
      priceColor=$green
    fi
  fi
}

determineFireFlag() {
  quoteVolume=$(round $(echo $1 | jq '.quoteVolume'| tr -d '"') $precision)
  isQuoteVolumeAmple=$(echo "$quoteVolume >= $fireVolume" | bc )
  volumeFlag=
  if [ $isQuoteVolumeAmple -eq 1 ]; then
    volumeFlag=$fireFlag
  fi
}

determineHighAndLowColor() {
  high=$(round $(echo $1 | jq '.highPrice'| tr -d '"') 5)
  low=$(round $(echo $1 | jq '.lowPrice'| tr -d '"') 5)
  last=$(round $(echo $1 | jq '.lastPrice'| tr -d '"') 5)

  highDiff=$(round $(jq -n $high-$last) 5)
  highDiffPercent=$(round $(jq -n $highDiff/$high*100) 5)
  isCloseToHigh=$(echo "$highDiffPercent <= $closeToHighOrLowPercent" | bc )

  lowDiff=$(round $(jq -n $last-$low) 5)
  lowDiffPercent=$(round $(jq -n $lowDiff/$low*100) 5)
  isCloseToLow=$(echo "$lowDiffPercent <= $closeToHighOrLowPercent" | bc )

  highFlag=$gray
  if [ $isCloseToHigh -eq 1 ]; then
    highFlag=$red
  fi
  
  lowFlag=$gray
  if [ $isCloseToLow -eq 1 ]; then
    lowFlag=$green
  fi
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
    determinePriceColor $pair
    determineHighAndLowColor $cryptoData

    echo "${cyan}${crypto}/${pairBase}${nc}${volumeFlag} "\\t" ${priceColor}${lastPrice} / ${priceChangePercent}%${nc} "\\t" ${highFlag}high=${highPrice}${nc} $gray/$nc ${lowFlag}low=${lowPrice}${nc}"
done

echo "\ndata generated: $(date +%Y-%m-%d,%T)"
