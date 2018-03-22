const ExchangeRates = artifacts.require('./ExchangeRates.sol')

module.exports = deployer => {
  deployer.deploy(
    ExchangeRates,
    3e5,
    2e9,
    60,
    'json(https://min-api.cryptocompare.com/data/price?fsym=ETH&tsyms=USD).USD',
    'json(https://min-api.cryptocompare.com/data/price?fsym=ETH&tsyms=EUR).EUR',
    { value: 5e17 }
  )
}
