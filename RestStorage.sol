// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./RecordInterface.sol";
import "./UserStorage.sol";
import "./RecordStorage.sol";

abstract contract ReentrancyGuardRest {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    constructor() {
        _status = _NOT_ENTERED;
    }
    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}
library Counters {
    
        struct Counter {
            uint256 _value; 
        }
        function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
        }
    function increment(Counter storage counter) internal {
        {
            if (counter._value == 0) {
				counter._value = 10000;
			}
            counter._value += 1;
        }
    }
    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        {
            counter._value = value - 1;
        }
    }
}
library RestUtils {
    struct RestDetail {
        uint finishCount; 
        uint remainderCount; 
        uint limitAmountFrom; 
        uint limitAmountTo; 
        uint limitMinCredit; 
        uint limitMinMortgage; 
        string restRemark; 
        uint restTime; 
        uint updateTime; 
        uint restFee;
        string restHash;
    }
  function _checkParam(uint _restType, string memory _coinType, string memory _currencyType, 
                        uint _restCount, uint _price, uint[] memory _payType) pure internal {
        require(_restType != uint(0), "Rest: Type null 1");
        require(bytes(_coinType).length != 0, "Rest: Type null 2");
        require(bytes(_currencyType).length != 0, "Rest: Type null 3");
        require(_restCount != uint(0), "Rest: Count null");
        require(_price != uint(0) && _payType.length != 0, "Rest: price or patType null");
      
	}
    function restDetailToJson(RestDetail memory _restDetail) internal pure returns (string memory) {
        string memory jsonString = '"finishCount": ';
        jsonString = string(abi.encodePacked(jsonString, uint2str(_restDetail.finishCount)));
        jsonString = string(abi.encodePacked(jsonString, ', "remainderCount": ', uint2str(_restDetail.remainderCount)));
        jsonString = string(abi.encodePacked(jsonString, ', "limitAmountFrom": ', uint2str(_restDetail.limitAmountFrom)));
        jsonString = string(abi.encodePacked(jsonString, ', "limitAmountTo": ', uint2str(_restDetail.limitAmountTo)));
        jsonString = string(abi.encodePacked(jsonString, ', "limitMinCredit": ', uint2str(_restDetail.limitMinCredit)));
        jsonString = string(abi.encodePacked(jsonString, ', "limitMinMortgage": ', uint2str(_restDetail.limitMinMortgage)));
        jsonString = string(abi.encodePacked(jsonString, ', "restRemark": "', _restDetail.restRemark, '"'));
        jsonString = string(abi.encodePacked(jsonString, ', "restTime": ', uint2str(_restDetail.restTime)));
        jsonString = string(abi.encodePacked(jsonString, ', "updateTime": ', uint2str(_restDetail.updateTime)));
        jsonString = string(abi.encodePacked(jsonString, ', "restFee": ', uint2str(_restDetail.restFee)));
        jsonString = string(abi.encodePacked(jsonString, ', "restHash": "', _restDetail.restHash, '"'));
        return jsonString;
    }

    function toJson(address _userAddr,uint _restNo, uint _restType, string memory _coinType, string memory _currencyType, 
            uint _restCount, uint _price, uint[] memory _payType) internal pure returns (string memory jsonString) {
            
            string memory result = '';
                result = string(abi.encodePacked(result, '"restNo": ', uint2str(_restNo)));
                result = string(abi.encodePacked(result, ', "restType": ', uint2str(_restType)));
                result = string(abi.encodePacked(result, ', "coinType": "', _coinType, '"'));
                result = string(abi.encodePacked(result, ', "currencyType": "', _currencyType, '"'));
                result = string(abi.encodePacked(result, ', "userAddr": "', addressToJson(_userAddr), '"'));
                result = string(abi.encodePacked(result, ', "restCount": ', uint2str(_restCount)));
                result = string(abi.encodePacked(result, ', "price": ', uint2str(_price)));
                string memory payTypeStr = '';
        for (uint i = 0; i < _payType.length; i++) {
            payTypeStr = string(abi.encodePacked(payTypeStr, uint2str(_payType[i])));
            if (i < _payType.length - 1) {
            payTypeStr = string(abi.encodePacked(payTypeStr, ", "));
            }
        }
            result = string(abi.encodePacked(result, ', "payType": [', payTypeStr, ']'));

        return result;
    }   
   
    function addressToJson(address _userAddr) internal pure returns (string memory) {

        bytes20 addrBytes = bytes20(_userAddr);
        bytes memory hexChars = "0123456789abcdef";
        bytes memory str = new bytes(42);
        str[0] = '0';
        str[1] = 'x';
        for (uint i = 0; i < 20; i++) {
            str[2 + i * 2] = hexChars[uint8(addrBytes[i] >> 4)];
            str[3 + i * 2] = hexChars[uint8(addrBytes[i] & 0x0f)];
        }
        return string(str);
    }
        function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
            if (_i == 0) {
                return "0";
            }
            uint j = _i;
            uint length;

            while (j != 0) {
                length++;
                j /= 10;
            }
            bytes memory bstr = new bytes(length);
            uint k = length;
            while (_i != 0) {
                k = k - 1;
                uint8 temp = (48 + uint8(_i - _i / 10 * 10));
                bytes1 b1 = bytes1(temp);
                bstr[k] = b1;
                _i /= 10;
        }
            return string(bstr);
    }

}

contract RestStorage is Ownable,ReentrancyGuardRest {
    using RestUtils for RestUtils.RestDetail;
    using Counters for Counters.Counter;
    RecordInterface private _recordStorage;
    UserInterface private _userStorage;
    address recordAddress;
    struct Rest {
        address userAddr; 
        uint restNo; 
        uint restType; 
        string coinType; 
        string currencyType; 
        uint restCount; 
        uint price; 
        uint[] payType; 
        uint restStatus; 
        string  diCoinType;
        RestUtils.RestDetail restDetail; 
    }

    Counters.Counter private _restNoCounter;
    mapping(address => mapping(string => mapping(uint256 => uint256))) private userDiya;
    mapping(address => uint) private latestRestNoByUser;
    mapping (uint => Rest) private rests;
    mapping (uint => uint) private restIndex;
    Rest[] private restList; 
	mapping(address=>mapping(uint=>uint)) restFrozenTotal;
    event RestAdd(string MyJosn);
    event RestUpdate(string MyJosn);
    event UpdateRestStatus(uint256 restNo,uint256 restStatus);
    event Diya(address indexed user,uint256 orderNo, string DicoinType, uint256 amount);
	address _orderCAddr;
	modifier onlyAuthFromAddr() {
        require(_orderCAddr == msg.sender, 'Invalid Contract Address');
		_;
	}
	function authFromContract(address _recordAddr, address _userAddr, address _orderAddr) external onlyOwner {
		_orderCAddr = _orderAddr;
        _recordStorage = RecordInterface(_recordAddr);
        _userStorage = UserInterface(_userAddr);
        recordAddress = _recordAddr;
        _restNoCounter.increment();
	}
    modifier onlyRestOwner(uint _restNo) {
		require(rests[_restNo].userAddr == msg.sender, "belong err");
        _;
    }

    function addDiyaR(uint256 _restNo,string memory CoinType, string memory DiCoinType, uint256 amount) 
    internal {
        uint256 NeedDiya;
        if (keccak256(abi.encodePacked(DiCoinType)) == keccak256(abi.encodePacked(CoinType)) ){
            NeedDiya = SafeMath.div(amount,10);
            userDiya[msg.sender][DiCoinType][_restNo] = SafeMath.add(
                userDiya[msg.sender][DiCoinType][_restNo],NeedDiya
            );
        }else{
            // IPancakeRouter01 uniswapV2Router = IPancakeRouter01(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
            IPancakeRouter01 uniswapV2Router = IPancakeRouter01(0x10ED43C718714eb63d5aA57B78B54704E256024E);
            address[] memory path = new address[](2);
            path[0] = _recordStorage.getCoinTypeMapping(CoinType);
            path[1] = _recordStorage.getCoinTypeMapping(DiCoinType);
            require(path[0] != address(0) && path[1] != address(0),"coin err");
            uint256[] memory amountsOut = uniswapV2Router.getAmountsOut(SafeMath.div(amount,10),path);
            require(amountsOut.length > 1, "Invalid path");
            NeedDiya =amountsOut[1];
            userDiya[msg.sender][DiCoinType][_restNo] = SafeMath.add(
                userDiya[msg.sender][DiCoinType][_restNo],NeedDiya
            );
        }
        require(userDiya[msg.sender][DiCoinType][_restNo] > 0, "count err");
        TokenTransfer _tokenTransferD = _recordStorage.getERC20Address(DiCoinType);
        _tokenTransferD.transferFrom(msg.sender, recordAddress, NeedDiya);
        emit Diya(msg.sender,_restNo, DiCoinType,NeedDiya);
    }
    function zeroDiya(uint256 restNo,string memory CoinType,address user)public{
        require(msg.sender == recordAddress,"unauth");
        userDiya[user][CoinType][restNo] =0;
    }
    function subDiya(uint256 restNo,string memory CoinType,address user,uint256 _amt)public{
        require(msg.sender == recordAddress,"unauth");
         userDiya[user][CoinType][restNo] = SafeMath.sub(userDiya[user][CoinType][restNo],_amt);
    }
    function getDy(uint256 restNo,string memory CoinType,address user) public  view  returns (uint256) {
        return userDiya[user][CoinType][restNo];
    }

    function _insert(
        uint _restType,
        string memory _coinType,
        string memory _currencyType,
        uint _restCount,
        uint _price,
        uint256 _restFee,
        uint[] memory _payType,
        string memory _diyaType,
        RestUtils.RestDetail memory _restDetail) internal nonReentrant returns(uint){

		RestUtils._checkParam(_restType, _coinType, _currencyType, _restCount, _price, _payType);
		uint _restNo = _restNoCounter.current();
        require(rests[_restNo].restNo == uint(0), "rest exist");
        require(_restDetail.limitAmountFrom <= _restDetail.limitAmountTo,"form > to");
		_restDetail.finishCount = 0;
		_restDetail.remainderCount = _restCount;
		_restDetail.restTime = block.timestamp;
		_restDetail.updateTime = 0;
        _restDetail.restFee = _restFee;
        if(_restDetail.limitAmountTo > SafeMath.mul(SafeMath.div(_restCount,10000),_price) || _restDetail.limitAmountTo == 0) {
            _restDetail.limitAmountTo = SafeMath.mul(SafeMath.div(_restCount,10000),_price);
        }
 		Rest memory r = Rest({
            userAddr: msg.sender,
            restNo: _restNo, 
            restType:_restType,
            coinType:_coinType,
            currencyType:_currencyType,
            restCount:_restCount,
            price:_price,
            payType:_payType,
            restStatus:1,
            diCoinType:_diyaType, 
            restDetail: _restDetail
        });
        rests[_restNo] = r;
		restList.push(r);
		restIndex[_restNo] = restList.length-1;
        _restNoCounter.increment();
        string memory combinedJson = string(abi.encodePacked('{',RestUtils.toJson(msg.sender,_restNo,_restType,_coinType,_currencyType,_restCount,_price,_payType), 
        ',',_restDetail.restDetailToJson(),'}'));
        latestRestNoByUser[msg.sender] = _restNo;
		emit RestAdd(combinedJson);
		return _restNo;
	}
    function _updateInfo(uint _restNo, string memory _coinType, string memory _currencyType, 
        uint _addCount, uint _price, uint[] memory _payType, RestUtils.RestDetail memory _restDetail,string memory _dicoinType) internal {
        Rest storage r = rests[_restNo];
        require(r.restNo != 0, 'Invalid restNo');
        UserStorage.User memory _user = _userStorage.searchUser(msg.sender);
        require(SafeMath.add(r.restCount,_addCount) <= _user.TradeLimit,"trade limit");
        r.restStatus = 1;
        r.coinType = bytes(_coinType).length > 0 ? _coinType : r.coinType;
        r.currencyType = bytes(_currencyType).length > 0 ? _currencyType : r.currencyType;
        r.price = _price > 0 ? _price : r.price;
        
        if(_addCount > 0){
            r.restCount += _addCount;
            r.restDetail.remainderCount += _addCount;
            r.restDetail.limitAmountTo = SafeMath.mul(SafeMath.div(r.restDetail.remainderCount, 10000),_price);
            _restDetail.limitAmountTo = r.restDetail.limitAmountTo;
            _userStorage.updateTradeLimit(msg.sender,_addCount,1);
        }else{
            r.restDetail.limitAmountTo = _restDetail.limitAmountTo;
        }
        r.diCoinType = bytes(_dicoinType).length > 0 ? _dicoinType : r.diCoinType;
        r.payType = _payType.length > 0 ? _payType : r.payType;
        r.restDetail.limitAmountFrom = _restDetail.limitAmountFrom > 0 
            ? (_restDetail.limitAmountFrom > r.restDetail.limitAmountTo ? r.restDetail.limitAmountTo : _restDetail.limitAmountFrom)
            : r.restDetail.limitAmountFrom;
        
        r.restDetail.limitMinCredit = _restDetail.limitMinCredit > 0 ? _restDetail.limitMinCredit : r.restDetail.limitMinCredit;
        r.restDetail.limitMinMortgage = _restDetail.limitMinMortgage > 0 ? _restDetail.limitMinMortgage : r.restDetail.limitMinMortgage;
        r.restDetail.restRemark = bytes(_restDetail.restRemark).length > 0 ? _restDetail.restRemark : r.restDetail.restRemark;
        r.restDetail.restFee = _restDetail.restFee > 0 ? _restDetail.restFee : r.restDetail.restFee;
        
        r.restDetail.updateTime = block.timestamp;
        restList[restIndex[_restNo]] = r; 
        string memory combinedJson = string(abi.encodePacked('{',RestUtils.toJson(msg.sender,_restNo,r.restType,_coinType,_currencyType,r.restCount,_price,_payType),
             ',',_restDetail.restDetailToJson(),'}'));
            emit RestUpdate(combinedJson);
    }
    function _checkAddrest(uint _restCount)internal view{
        require(_restCount >0,"count should > 0");
        UserStorage.User memory _user = _userStorage.searchUser(msg.sender);
        require(_user.userFlag == 3, "invalid user");
        require(_restCount <= _user.TradeLimit, "trade limit");
    }
	function addBuyRest(uint _restType, string memory _coinType, string memory _currencyType, 
    uint _restCount, uint _price, uint[] memory _payType,string memory _dicoinType, RestUtils.RestDetail memory _restDetail) external {
        require(_restType == 1,"must buy type");
        _checkAddrest(_restCount);
        uint256 _restNo  =_insert(_restType, _coinType, _currencyType, _restCount, _price,0, _payType,_dicoinType, _restDetail);
        _userStorage.updateTradeLimit(msg.sender,_restCount,1);
        addDiyaR(_restNo,_coinType,_dicoinType, _restCount);
	}
	function _addSell(uint _restType, string memory _coinType, string memory _currencyType, 
    uint _restCount, uint _restFee, uint _price, uint[] memory _payType,string memory _dicoinType, RestUtils.RestDetail memory _restDetail) internal {
	    require(_restType == 2, "must sell type");
        _checkAddrest(_restCount);
        _recordStorage.addRecord(msg.sender, '', _coinType, _restCount, 2, 1, 2);
        uint _needSub = SafeMath.add(_restCount, _restFee);
        TokenTransfer _tokenTransfer = _recordStorage.getERC20Address(_coinType);
		_tokenTransfer.transferFrom(msg.sender, recordAddress, _needSub);
        uint _newRestNo = _insert(_restType, _coinType, _currencyType, _restCount, _price,_restFee,_payType,_dicoinType, _restDetail);
        restFrozenTotal[msg.sender][_newRestNo] = _restCount;
        _userStorage.updateTradeLimit(msg.sender,_restCount,1);
        addDiyaR(_newRestNo,_coinType, _dicoinType, _restCount);
        
	}
	function addSellRest(uint _restType, string memory _coinType, string memory _currencyType, 
    uint _restCount, uint _price, uint[] memory _payType,string memory _dicoinType,RestUtils.RestDetail memory _restDetail) external {
        uint256 _restFee = SafeMath.div(SafeMath.mul(_restCount,12),1000);
        _addSell(_restType, _coinType, _currencyType, _restCount,_restFee,_price, _payType,_dicoinType,_restDetail);
	}
	function getRestFrozenTotal(address _addr, uint _restNo) public view returns(uint) {
	    return restFrozenTotal[_addr][_restNo];
	}

    function cancelRest(uint _restNo) external onlyRestOwner(_restNo) {
        Rest storage r = rests[_restNo];
        require(r.restStatus == 1, "status err");
        require(r.restDetail.finishCount < r.restCount, "it done");
        if (r.restType == 1) {
            r.restStatus = 4;
        } else if (r.restType == 2) {
            uint _frozenTotal = _recordStorage.getFrozenTotal(msg.sender, r.coinType);
            require(_frozenTotal >= restFrozenTotal[msg.sender][_restNo], "can't cancel");
           
            uint remainHoldCoin = restFrozenTotal[msg.sender][_restNo];
            r.restStatus = remainHoldCoin < r.restCount ? 5 : 4; 
            
            _recordStorage.addAvailableTotal(msg.sender, r.coinType, remainHoldCoin);
            _recordStorage.done(
                r.coinType,
                SafeMath.div(SafeMath.mul(r.restDetail.remainderCount,12),1000),
                msg.sender
                );

            r.restDetail.remainderCount = 0;
            restFrozenTotal[msg.sender][_restNo] = 0;
        } 
        updateRestStorage(_restNo, r);
        _userStorage.updateTradeLimit(msg.sender,r.restCount,2);
        _recordStorage.backDiya(_restNo,getDy(_restNo,r.diCoinType,r.userAddr),1);
        emit UpdateRestStatus(_restNo,r.restStatus);
    }
    function startOrStop(uint _restNo, uint _restStatus) external onlyRestOwner(_restNo){
        require(_restStatus == 1 || _restStatus == 3, "err status");
        Rest memory r = rests[_restNo];
        require(r.restStatus == 1 || r.restStatus == 3, "opt err");
        r.restStatus = _restStatus;
        r.restDetail.updateTime = block.timestamp;
        rests[_restNo] = r;
        restList[restIndex[_restNo]] = r;
        emit UpdateRestStatus(_restNo,_restStatus);
    }
	function updateInfo(uint _restNo, string memory _coinType, string memory _currencyType, 
    uint _addCount,  uint _price,uint[] memory _payType, RestUtils.RestDetail memory _restDetail,
    string memory _dicoinType) external onlyRestOwner(_restNo){
		Rest memory _rest = rests[_restNo];
        require(_restNo != uint(0) && _rest.restNo != uint(0), 'Invalid restNo');
		if (_rest.restType == 2) {
            _recordStorage.addRecord(msg.sender, '', _coinType, _addCount, 2, 1, 2);
            uint _restFee = SafeMath.div(SafeMath.mul(_addCount,12),1000);
            uint _needSub = SafeMath.add(_addCount, _restFee);
            TokenTransfer _tokenTransfer = _recordStorage.getERC20Address(_coinType);
            _tokenTransfer.transferFrom(msg.sender, recordAddress, _needSub);
            restFrozenTotal[msg.sender][_restNo] += _addCount;
		}
        if (_addCount >0){
            addDiyaR(_restNo,_coinType,_dicoinType,_addCount);
        }
        _updateInfo(_restNo, _coinType, _currencyType, _addCount, _price, _payType, _restDetail,_dicoinType);
	}
   function updateRestFinishCount(uint _restNo, uint _finishCount) onlyAuthFromAddr external {
        require(msg.sender == _orderCAddr,"only contract");
        Rest storage _rest = rests[_restNo];
        require(_rest.restDetail.remainderCount >= _finishCount, "RestStorage:finish count err");
        if (_rest.restType == 2) {
            restFrozenTotal[_rest.userAddr][_restNo] = 
            SafeMath.sub(restFrozenTotal[_rest.userAddr][_restNo], _finishCount);
        }
        _rest.restDetail.finishCount = SafeMath.add(_rest.restDetail.finishCount, _finishCount);
        _rest.restDetail.remainderCount = SafeMath.sub(_rest.restDetail.remainderCount, _finishCount);
        _rest.restDetail.limitAmountTo = SafeMath.div(SafeMath.mul(_rest.price, _rest.restDetail.remainderCount),10000);
        _rest.restDetail.limitAmountFrom = _rest.restDetail.limitAmountFrom > _rest.restDetail.limitAmountTo ? _rest.restDetail.limitAmountTo : _rest.restDetail.limitAmountFrom;
        if (_rest.restDetail.remainderCount == 0) {
            _rest.restStatus = 2;
        }
	    updateRestStorage(_restNo, _rest);
    }
    function addRestRemainCount(uint _restNo, uint _remainCount) onlyAuthFromAddr public {
        require(msg.sender == _orderCAddr,"only contract");
        Rest storage _rest = rests[_restNo];
        require(_remainCount > 0 && _rest.restDetail.finishCount >= _remainCount, "count err");
        if (_rest.restType == 2) {
            restFrozenTotal[_rest.userAddr][_restNo] = SafeMath.add(restFrozenTotal[_rest.userAddr][_restNo], _remainCount);
        }
        _rest.restDetail.finishCount = SafeMath.sub(_rest.restDetail.finishCount, _remainCount);
        _rest.restDetail.remainderCount = SafeMath.add(_rest.restDetail.remainderCount, _remainCount);
        _rest.restDetail.limitAmountTo = SafeMath.div(SafeMath.mul(_rest.price, _rest.restDetail.remainderCount),10000);
        _rest.restDetail.limitAmountFrom = _rest.restDetail.limitAmountFrom > _rest.restDetail.limitAmountTo ? _rest.restDetail.limitAmountTo : _rest.restDetail.limitAmountFrom;
        _rest.restStatus = 1;
		updateRestStorage(_restNo, _rest);
    }
    function updateRestStorage(uint _restNo, Rest storage _rest) private {
        _rest.restDetail.updateTime = block.timestamp;
        rests[_restNo] = _rest;
        restList[restIndex[_restNo]] = _rest;
    }
	function searchRest(uint _restNo) external view returns(Rest memory rest) {
		Rest memory r = rests[_restNo];
		return r;
	}
	function searchRestList() external view returns(Rest[] memory) {
        return restList;
	}
     function getLatestRestNo(address userAddr) public view returns (uint256) {
        return latestRestNoByUser[userAddr];
    }
}