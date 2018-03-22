# ExchangeRates smart contract

## What does it do?
Fetches ETH/USD and ETH/EUR rates continuously for usage by smart contracts which need USD or EUR rates.

## How does it do it?
It uses oraclize to recursively call for rates.

## overview
Because `ExchangeRates` uses oraclize, callback params can be specified, these params include the gasPrice and the gasLimit of the callback. Query calls can also be delayed. This is useful for recursive functions coming from the callback function. There are two queryStrings that are used to get exchange rate data for each of the USD and EUR exchange rates. These can be changed out in case the API fails or there is some other reason to get data from elsewhere.

These params are initially specified in the constructor. Though they can be changed by calling `changeOraclizedParams` as `owner`.

Rates do not start fetching by default once deployed. Rates are fetched once when the `owner` calls `startRates`. After `startRates` has been called rates will be continuously called using the params given in the constructor.

Rate queries can be stopped by calling `stopRates` by the owner.

If rates need to be queried immediately, the owner can call `fetchUsdRate` or `fetchEurRate`. These can also be called without `ratesActive` being true. This means that you can call for the updated rates ONLY when you want to rather than continuously.

If for some reason the contract needs to be replaced etc... a selfdestruct function callable by owner is available which will kill the contract and give the ether balance back to the owner.
