pragma solidity 0.4.19;

import "./OraclizeAPI.sol";


contract ExchangeRates is usingOraclize {
  address public owner;
  uint256 public usdRate;
  uint256 public eurRate;
  uint256 public callbackGasLimit;
  uint256 public callbackGasPrice;
  uint256 public callInterval;
  string public usdQueryString;
  string public eurQueryString;
  bool public ratesActive;
  mapping (bytes32 => uint256) queryTypes;

  event RateUpdated(string currency, uint256 rate);
  event QueryNoMinBalance();
  event QuerySent();

  modifier onlyAllowed() {
    require(msg.sender == owner || msg.sender == oraclize_cbAddress());
    _;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function ExchangeRates(
    uint256 _gasLimit,
    uint256 _gasPrice,
    uint256 _callInterval,
    string _usdQueryString,
    string _eurQueryString
  )
    public
    payable
  {
    require(msg.value >= 5e17);
    require(_gasLimit >= 2e5);
    require(_gasPrice >= 1e9);
    require(_callInterval >= 60);
    require(!stringIsEmpty(_usdQueryString));
    require(!stringIsEmpty(_eurQueryString));
    oraclize_setProof(proofType_TLSNotary | proofStorage_IPFS);
    owner = msg.sender;
    callbackGasLimit = _gasLimit;
    callbackGasPrice = _gasPrice;
    callInterval = _callInterval;
    usdQueryString = _usdQueryString;
    eurQueryString = _eurQueryString;
    oraclize_setCustomGasPrice(callbackGasPrice);
  }

  function stringIsEmpty(string _string)
    internal
    pure
    returns (bool)
  {
    bytes memory _stringTest = bytes(_string);
    return _stringTest.length == 0;
  }

  // callback function to get results of oraclize call
  function __callback(bytes32 _queryId, string _result, bytes _proof)
    public
  {
    require(msg.sender == oraclize_cbAddress());
    uint256 _queryType = queryTypes[_queryId];
    require(_queryType > 0);
    queryTypes[_queryId] = 0;
    if (_queryType == 1) {
      usdRate = parseInt(_result);
      RateUpdated("usd", usdRate);
      if (ratesActive) {
        fetchUsdRate(callInterval);
      }
    } else if(_queryType == 2){
      eurRate = parseInt(_result);
      RateUpdated("eur", eurRate);
      if (ratesActive) {
        fetchEurRate(callInterval);
      }
    } else {
      revert();
    }
  }

  function fetchUsdRate(uint256 _callDelay)
    public
    payable
    returns (bool)
  {
    if (msg.sender == owner) {
      require(!ratesActive);
    }

    if (oraclize_getPrice("URL") > this.balance) {
      QueryNoMinBalance();
      return false;
    } else {
      bytes32 _queryId = oraclize_query(
        _callDelay,
        "URL",
        usdQueryString,
        callbackGasLimit
      );
      queryTypes[_queryId] = 1;
      QuerySent();
    }
    return true;
  }

  function fetchEurRate(uint256 _callDelay)
    public
    payable
    returns (bool)
  {
    if (msg.sender == owner) {
      require(!ratesActive);
    }

    if (oraclize_getPrice("URL") > this.balance) {
      QueryNoMinBalance();
      return false;
    } else {
      bytes32 _queryId = oraclize_query(
        _callDelay,
        "URL",
        eurQueryString,
        callbackGasLimit
      );
      queryTypes[_queryId] = 2;
      QuerySent();
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
    fetchUsdRate(0);
    fetchEurRate(0);
    ratesActive = true;
  }

  function changeOraclizedParams(
    uint256 _gasLimit,
    uint256 _gasPrice,
    uint256 _callInterval,
    string _usdQueryString,
    string _eurQueryString
  )
    public
    onlyOwner
  {
    require(_gasLimit >= 2e5);
    require(_gasPrice >= 1e9);
    require(_callInterval >= 60);
    require(!stringIsEmpty(_usdQueryString));
    require(!stringIsEmpty(_eurQueryString));
    callbackGasLimit = _gasLimit;
    callbackGasPrice = _gasPrice;
    callInterval = _callInterval;
    oraclize_setCustomGasPrice(callbackGasPrice);
  }

  function()
    public
    payable
  {}

  function selfDestruct()
    public
    onlyOwner
  {
    selfdestruct(owner);
  }
}
