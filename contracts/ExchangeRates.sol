pragma solidity 0.4.19;

import "./OraclizeAPI.sol";
import "zeppelin-solidity/contracts/ownership/Ownable.sol";


contract ExchangeRates is usingOraclize, Ownable {
  uint256 public usdRate;
  uint256 public eurRate;
  bool public ratesActive;
  // keep track of queries for reorg protection and track types
  // 1 for usd 2 for eur
  mapping (bytes32 => uint256) queryTypes;

  event RateUpdated(bytes32 indexed currency, uint256 rate);
  event QueryNoMinBalance();
  event QuerySent();
  event Debug(bytes32 queryId, uint256 queryType, string result);

  function ExchangeRates()
    public
    payable
  {
    require(msg.value >= 5e17);
    oraclize_setProof(proofType_TLSNotary | proofStorage_IPFS);
  }

  // callback function to get results of oraclize call
  function __callback(bytes32 _queryId, string _result, bytes _proof)
    public
  {
    require(msg.sender == oraclize_cbAddress());
    uint256 _queryType = queryTypes[_queryId];
    require(_queryType > 0);
    queryTypes[_queryId] = 0;
    Debug(_queryId, _queryType, _result);

    if (_queryType == 1) {
      usdRate = parseInt(_result);
      RateUpdated(bytes32("usd"), usdRate);
      fetchUsdRate();
    } else {
      eurRate = parseInt(_result);
      RateUpdated(bytes32("eur"), usdRate);
      fetchEurRate();
    }
  }

  function fetchUsdRate()
    public
    payable
    onlyOwner
    returns (bool)
  {
    if (ratesActive) {
      if (oraclize_getPrice("URL") > this.balance) {
        QueryNoMinBalance();
        return false;
      } else {
        bytes32 _queryId = oraclize_query(
          60,
          "URL",
          "json(https://min-api.cryptocompare.com/data/price?fsym=ETH&tsyms=USD).USD"
        );
        queryTypes[_queryId] = 1;
        QuerySent();
      }
      return true;
    } else {
      return false;
    }
  }

  function fetchEurRate()
    public
    payable
    onlyOwner
    returns (bool)
  {
    if (ratesActive) {
      if (oraclize_getPrice("URL") > this.balance) {
        QueryNoMinBalance();
        return false;
      } else {
        bytes32 _queryId = oraclize_query(
          60,
          "URL",
          "json(https://min-api.cryptocompare.com/data/price?fsym=ETH&tsyms=EUR).EUR"
        );
        queryTypes[_queryId] = 2;
        QuerySent();
      }
      return true;
    } else {
      return false;
    }
  }

  function stopRates()
    public
    onlyOwner
  {
    ratesActive = false;
  }

  function startRates()
    public
    onlyOwner
  {
    ratesActive = true;
    fetchUsdRate();
    fetchEurRate();
  }

  function selfDestruct()
    public
    onlyOwner
  {
    selfdestruct(owner);
  }
}
