const ExchangeRates = artifacts.require('./ExchangeRates.sol')

module.exports = deployer => {
  deployer.deploy(ExchangeRates, { value: 5e17 })
}
