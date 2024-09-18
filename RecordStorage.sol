// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./RecordInterface.sol";
import "./UserStorage.sol";
import "./OrderStorage.sol";
import "./RestStorage.sol";

abstract contract ReentrancyGuardRecord {
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
library CountersRecord {
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
interface TokenTransfer {
    function transfer(address recipient, uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external;
    function allowance(address _owner, address _spender)
        external
        view
        returns (uint256 remaining);
}
contract RecordStorage is Ownable, ReentrancyGuardRecord {
    using CountersRecord for CountersRecord.Counter;
    mapping(string =>address) coinTypeMaping;
    uint256 merchantNeedCount = 100000000 * (10**18);
    uint256 witnessNeedCount  = 600000000 * (10**18);
    uint256 canWithdrawToTime = 7;
    uint256 canTakeRewardTime = 24;
    uint256 tradeCredit = 1;
    uint256 subTCredit = 10;
    uint256 subWitCredit = 10;
    address congress;
    address rewardHander = 0xCFDf20672f08Affd81987Cf1b963AEE80b514F72;
    address M = 0x1cb03301937b7388fe4F1C019f8Cc8358158Bb9B;
    address T = 0x9e8AEc7444C9CE3b5b5B66103E22300d971b4048;

    function setCoinTypeMapping(string memory _coinType, address _coinTypeAddr)external onlyOwner{
        coinTypeMaping[_coinType] = _coinTypeAddr;
    }
    function getCoinTypeMapping(string memory _coinType) external view  returns (address) {
        return coinTypeMaping[_coinType];
    }
    function setCongress(address _congress)external onlyOwner{
        congress = _congress;
        if (!_userStorage.isMemberOfOne(_congress)){
            _userStorage.registerOne(_congress);
        }
        _userStorage.updateUserRole(_congress, 2);
    }
    function getCongress()public view returns(address){
       return congress;
    }
    function setrewardHander(address addr) external onlyOwner {
        rewardHander = addr;
    }

    function getrewardHander() public view returns (address) {
        return rewardHander;
    }
    function setM(address addr) external onlyOwner {
        M = addr;
    }

    function getM() public view returns (address) {
        return M;
    }

    function setT(address addr) external onlyOwner {
        T = addr;
    }

    function getT() public view returns (address) {
        return T;
    }
    function setNeedCount(uint256 _merchantNeedCount,uint256 _WitnessNeedCount) external onlyOwner {
        merchantNeedCount = _merchantNeedCount * (10**18);
        witnessNeedCount = _WitnessNeedCount * (10**18);
    }

    function getMerchantNeedCount() public view returns (uint256) {
        return merchantNeedCount;
    }
   
    function getWitnessNeedCount() public view returns (uint256) {
        return witnessNeedCount;
    }

    function setCanToTime(uint256 _canWithdrawTodays,uint256 _canTakeRewardTotime) external onlyOwner {
        canWithdrawToTime = _canWithdrawTodays;
        canTakeRewardTime = _canTakeRewardTotime;
    }

    function getCanWithdrawToTime() public view returns (uint256) {
        return canWithdrawToTime;
    }
    
    function getCanTakeRewardTime() public view returns (uint256) {
        return canTakeRewardTime;
    }

    function setCredit(uint256 _SubWitCredit,uint256 _SubTCredit,uint256 _TradeCredit) external onlyOwner {
        subWitCredit = _SubWitCredit;
        subTCredit = _SubTCredit;
        tradeCredit = _TradeCredit;
    }
    function getSubWitCredit() public view returns (uint256) {
        return subWitCredit;
    }
    function getTradeCredit() public view returns (uint256) {
        return tradeCredit;
    }
    function getSubTCredit() public view  returns (uint256) {
        return subTCredit;
    }
    function punishPerson(address _from, address _to, uint256 _count) external onlyOwner {
        require(_from != address(0) && _to != address(0), "err from or to");
        // UserStorage.User memory _user = _userStorage.searchUser(_from);
        // require(_user.userFlag == 1 || _user.userFlag == 2,"can't punish one");
        
        uint256 _ava = availableTotal[_from]["AIR"];
        uint256 _toavailab = availableTotal[_to]["AIR"];
        if (_ava >= _count) {
            availableTotal[_from]["AIR"] = SafeMath.sub(_ava, _count);
            availableTotal[_to]["AIR"] = SafeMath.add(_toavailab, _count);
        } else {
            availableTotal[_from]["AIR"] = 0;
            uint256 _draing = withdrawingTotal[_from]["AIR"];
            if (SafeMath.add(_ava, _draing) >= _count) {
                withdrawingTotal[_from]["AIR"] = SafeMath.sub(
                    _draing,
                    SafeMath.sub(_count, _ava)
                );
                availableTotal[_to]["AIR"] = SafeMath.add(_toavailab, _count);
            } else {
                withdrawingTotal[_from]["AIR"] = 0;
                availableTotal[_to]["AIR"] = SafeMath.add(
                    _toavailab,
                    SafeMath.add(_ava, _draing)
                );
            }
        }
        chanRole(_from);
        chanRole(_to);
    }
    UserInterface private _userStorage;
    OrderInterface private _orderStorage;
    RestInterface private _restStorage;
    AppealInterface private _appealStorage;
    struct Record {
        uint256 recordNo;
        address userAddr;
        string tradeHash;
        string coinType;
        uint256 hostCount;
        uint256 hostStatus;
        uint256 hostType;
        uint256 hostDirection;
        uint256 hostTime;
        uint256 updateTime;
    }
    CountersRecord.Counter private _recordNoCounter;
    mapping(uint256 => Record) public records;
    mapping(uint256 => uint256) public recordIndex;
    Record[] public recordList;
    mapping(address => mapping(string => uint256)) public availableTotal;
    mapping(address => mapping(string => uint256))  frozenTotal;
    mapping(address => mapping(string => uint256))  unfrozenTotal;
    mapping(address => uint256) lastWithdrawTime;
    mapping(address => mapping(uint256 => uint256)) lastWithdrawAmount;
    mapping(address => mapping(string => uint256)) public withdrawingTotal;
    mapping(address => mapping(uint256 => uint256)) orderSubFrozenList;
    constructor(
        address _usdtAddress,
        address _airAddress
    ) {
        coinTypeMaping["USDT"] = _usdtAddress;
        coinTypeMaping["AIR"] = _airAddress;
        _recordNoCounter.increment();
    }
    function getERC20Address(string memory _coinType)public view returns (TokenTransfer){
        require(bytes(_coinType).length != 0, "err coinType");
        address _remoteAddr = coinTypeMaping[_coinType];
        require(_remoteAddr != address(0), "err coinType");
        TokenTransfer _tokenTransfer = TokenTransfer(_remoteAddr);
        return _tokenTransfer;
    }
    event RecordAdd(
        uint256 _recordNo,
        address _addr,
        string _tradeHash,
        string _coinType,
        uint256 _hostCount,
        uint256 _hostStatus,
        uint256 _hostType,
        uint256 _hostDirection,
        uint256 _hostTime
    );
    event RecordApplyUnfrozen(address _addr, uint256 _amt);
    event UnfrozenTotalTransfer(
        address _addr,
        string _coinType,
        uint256 _lastAmount
    );
    event RecordUpdate(
        address _addr,
        uint256 _recordNo,
        string _hash,
        uint256 _hostStatus
    );
    address _userAddr;
    address _restCAddr;
    address _orderCAddr;
    address _appealCAddr;
    modifier onlyAuthFromAddr() {
        require(_userAddr != address(0), "nil Uaddr");
        require(_restCAddr != address(0), "nil Raddr");
        require(_orderCAddr != address(0), "nil Oaddr");
        require(_appealCAddr != address(0), "nil Aaddr");
        _;
    }
   
    function authFromContract(
        address _fromUser,
        address _fromRest,
        address _fromOrder,
        address _fromAppeal
    ) external onlyOwner {
        _userAddr = _fromUser;
        _restCAddr = _fromRest;
        _orderCAddr = _fromOrder;
        _appealCAddr = _fromAppeal;
        _userStorage = UserInterface(_userAddr);
        _orderStorage = OrderInterface(_orderCAddr);
        _restStorage = RestInterface(_restCAddr);
        _appealStorage = AppealInterface(_appealCAddr);
    }
    function _insert(
        address _addr,
        string memory _tradeHash,
        string memory _coinType,
        uint256 _hostCount,
        uint256 _hostStatus,
        uint256 _hostType,
        uint256 _hostDirection
    ) internal nonReentrant returns (uint256 recordNo) {
        require(_addr != address(0), "addr null");
        require(bytes(_coinType).length != 0 && _hostDirection != uint256(0), "hostDirect/coinType null");
        require(_hostCount != uint256(0) && _hostType != uint256(0), "host: count/type null");
        uint256 _recordNo = _recordNoCounter.current();
        require(records[_recordNo].recordNo == uint256(0), "order exist");
        Record memory _record = Record({
            recordNo: _recordNo,
            userAddr: _addr,
            tradeHash: _tradeHash,
            coinType: _coinType,
            hostCount: _hostCount,
            hostStatus: _hostStatus,
            hostType: _hostType,
            hostDirection: _hostDirection,
            hostTime: block.timestamp,
            updateTime: 0
        });
        records[_recordNo] = _record;
        recordList.push(_record);
        recordIndex[_recordNo] = recordList.length - 1;
        _recordNoCounter.increment();
        emit RecordAdd(
            _recordNo,
            _addr,
            _tradeHash,
            _coinType,
            _hostCount,
            _hostStatus,
            _hostType,
            _hostDirection,
            block.timestamp
        );
        return _recordNo;
    }
    function leverNeed(uint256 _lever)private view returns(uint256 need){
        require(_lever >= 1 && _lever <=5);
        return merchantNeedCount + ( (_lever - 1) * (100000000 * 10**18) );
    }
 
    function tokenEscrow(uint256 _roleType,uint256 _amt,uint256 _lever) external {
        uint256 _hostType = 2;
        string memory airType = "AIR";
        require(_roleType == 1 || _roleType == 3, "err role");
        uint256 requiredAmount;
        uint256 hadEscorw = availableTotal[msg.sender][airType];
        UserStorage.User memory _user = _userStorage.searchUser(msg.sender);
        if (_roleType == 3) {
            requiredAmount = SafeMath.sub( leverNeed(_lever),hadEscorw) >0 ?
             SafeMath.sub(leverNeed(_lever),hadEscorw) : 0; 
            
        } else if (_roleType == 1) {
            require(hadEscorw + _amt >= witnessNeedCount,"less");
            requiredAmount = _amt;
        } 
        availableTotal[msg.sender][airType] = SafeMath.add(hadEscorw, requiredAmount);
        if (_user.userFlag == 0 && _roleType == 3) {
            _userStorage.updateMerLever(msg.sender);   
        }
        if(_roleType == 3){
            _userStorage.updateMerLever(_user.userAddr);
            _changeUserMorgageStats(msg.sender,availableTotal[msg.sender][airType]);
        }else{
            chanRole(msg.sender);
            _userStorage.zeroMerLever(msg.sender);
        }
       
        if (requiredAmount > 0){
            _insert(msg.sender, "", airType, requiredAmount, 2, _hostType, 1);
            TokenTransfer _tokenTransfer = getERC20Address(airType);
            _tokenTransfer.transferFrom(msg.sender, address(this), requiredAmount);
        }

    }
    
    function addRecord(
        address _addr,
        string memory _tradeHash,
        string memory _coinType,
        uint256 _hostCount,
        uint256 _hostStatus,
        uint256 _hostType,
        uint256 _hostDirection
    ) public onlyAuthFromAddr {
        require(
            msg.sender == _restCAddr || msg.sender == _orderCAddr,
            "RedocrdStorage:Invalid from contract address"
        );
        frozenTotal[_addr][_coinType] = SafeMath.add(
            frozenTotal[_addr][_coinType],
            _hostCount
        );
        _insert(
            _addr,
            _tradeHash,
            _coinType,
            _hostCount,
            _hostStatus,
            _hostType,
            _hostDirection
        );
    }
   
    function addAvailableTotal(
        address _addr,
        string memory _coinType,
        uint256 _amt
    ) public onlyAuthFromAddr {
        require(msg.sender == _restCAddr || msg.sender == _orderCAddr,"address err");
        require(_amt > 0, "transfer amount err");
        uint256 _aBalance = getErcBalance(_coinType, address(this));
        require(_aBalance >= _amt, "balance err");
        require(frozenTotal[_addr][_coinType] >= _amt, "amount err");
        require(SafeMath.sub(frozenTotal[_addr][_coinType], _amt)<=frozenTotal[_addr][_coinType],
            "amount err"
        );
        frozenTotal[_addr][_coinType] = SafeMath.sub(
            frozenTotal[_addr][_coinType],
            _amt
        );
        TokenTransfer _tokenTransfer = getERC20Address(_coinType);
        _tokenTransfer.transfer(_addr, _amt);
    }
    function getAvailableTotal(address _addr, string memory _coinType)public view returns(uint256){
        return availableTotal[_addr][_coinType];
    }
    function backDiya(uint256 _No,uint256 _amt,uint256 _type)public onlyAuthFromAddr{
    require(msg.sender == _restCAddr || msg.sender == _orderCAddr || msg.sender == address(this),"err CA");
        if (_type == 1){
        RestStorage.Rest memory _rest = _restStorage.searchRest(_No);
        require(_restStorage.getDy(_No,_rest.diCoinType,_rest.userAddr) != 0);
        TokenTransfer  _tokenTransferD = getERC20Address(_rest.diCoinType);
        _tokenTransferD.transfer(_rest.userAddr,_amt);
        _restStorage.zeroDiya(_No,_rest.diCoinType,_rest.userAddr);
        }
        if (_type == 2){
        OrderStorage.Order memory _order = _orderStorage.searchOrder(_No);
        require(_orderStorage.getDy(_No,_order.diyaType,_order.userAddr) != 0);
        TokenTransfer  _tokenTransferD = getERC20Address(_order.diyaType);
        _tokenTransferD.transfer(_order.userAddr,_amt);
        _orderStorage.zeroDiya(_No,_order.diyaType,_order.userAddr);
        }
    }
     
    function subFrozenTotal(uint256 _orderNo, address _addr)public onlyAuthFromAddr{
        require(msg.sender == _orderCAddr || msg.sender == _appealCAddr,
            "Invalid from contract address"
        );
        OrderStorage.Order memory _order = _orderStorage.searchOrder(_orderNo);
        require(_order.orderNo != uint256(0), "order not exist");
        address _seller = _order.orderDetail.sellerAddr;
        string memory _coinType = _order.orderDetail.coinType;
        uint256 _subAmount = orderSubFrozenList[_seller][_orderNo];
        require(_subAmount == 0, "order not exist");
        uint256 _frozen = frozenTotal[_seller][_coinType];
        uint256 _orderCount = _order.coinCount;
        require(_frozen >= _orderCount, "err amount");
        require(SafeMath.sub(_frozen, _orderCount) <= _frozen,"Invalid amount");

        frozenTotal[_seller][_coinType] = SafeMath.sub(_frozen, _orderCount);
        orderSubFrozenList[_seller][_orderNo] = _orderCount;
        TokenTransfer _tokenTransfer = getERC20Address(_coinType);
        _tokenTransfer.transfer(_addr, _orderCount);
    }
    function subAvaAppeal(AppealStorage.Appeal memory _al,uint256 _t) public onlyAuthFromAddr {
        require(msg.sender == _appealCAddr,"RedocrdStorage:Invalid from contract address");

        address _opt = _t == 1 ? _al.witness : _al.detail.observerAddr;
      
        UserStorage.User memory _user = _userStorage.searchUser(_opt);
        _user.credit =  _user.credit + tradeCredit;
       
        UserStorage.TradeStats memory _tradeStats = _user.tradeStats;
        _userStorage.updateTradeStats(_opt, _tradeStats, _user.credit);
    }
   function takeReward(uint256 _orderNo,address taker) public {
        require(msg.sender == _orderCAddr);
        AppealStorage.Appeal memory _appeal = _appealStorage.searchAppeal(_orderNo);
        uint256 earliestTimeToTakeReward = _appeal.detail.observerHandleTime != 0 
        ? _appeal.detail.observerHandleTime : _appeal.detail.witnessHandleTime;
        require(earliestTimeToTakeReward != 0, "not handel"); 
        require(block.timestamp >= (earliestTimeToTakeReward + canTakeRewardTime * 1 hours) , "not time");
        TokenTransfer  _tokenTransfer = getERC20Address(_appeal.detail.RewardType);

        uint256 rewardToTransfer = _appeal.detail.witReward;
        address recipient = _appeal.witness;

        if (_appeal.detail.observerHandleReward != 0) {
            require(_appeal.detail.observerAddr == taker, "no power");
            rewardToTransfer = _appeal.detail.observerHandleReward;
            recipient = _appeal.detail.observerAddr;
        }else{
            require(_appeal.witness == taker, "no power");
        }
        require(rewardToTransfer > 0,"no reward");
        _tokenTransfer.transfer(recipient, rewardToTransfer/2);
        _tokenTransfer.transfer(rewardHander, rewardToTransfer/2);
        _appealStorage.zeroReward(_orderNo);
     
        address _lose;
        if (_appeal.user == _appeal.buyer) {
            _lose = (_appeal.status == 2 || _appeal.status == 6) ? _appeal.seller : _appeal.buyer;
        } else {
            _lose = (_appeal.status == 2 || _appeal.status == 6) ? _appeal.buyer : _appeal.seller;
        }

        OrderStorage.Order memory _order = _orderStorage.searchOrder(_orderNo);
        if (_appeal.detail.RewardFlag == 1) {
            _orderStorage.zeroDiya(_appeal.detail.RewardNo, _appeal.detail.RewardType, _lose);
        } else if (_appeal.detail.RewardFlag == 2) {
            _restStorage.subDiya(_appeal.detail.RewardNo,_appeal.detail.RewardType,_lose,rewardToTransfer);
            backDiya(_order.orderNo,_orderStorage.getDy(_orderNo, _order.diyaType, _order.userAddr),2);
        }
    RestStorage.Rest memory _rest = _restStorage.searchRest(_order.restNo);
    done(_rest.coinType,SafeMath.div(SafeMath.mul(_order.coinCount,12),1000),address(0));
    }

    function _changeUserMorgageStats(address _addr, uint256 _amt) internal {
        UserStorage.User memory _user = _userStorage.searchUser(_addr);
        UserStorage.MorgageStats memory _morgageStats = _user.morgageStats;
        _morgageStats.mortgage = _amt;
        _userStorage.updateMorgageStats(_addr, _morgageStats);
    }

    function getFrozenTotal(address _addr, string memory _coinType) public view returns (uint256){
        return frozenTotal[_addr][_coinType];
    }

    function applyUnfrozen(uint256 _amt) external returns (uint256) {
        require(_amt > 0, "amount err");
        string memory airType = "AIR";
        require(availableTotal[msg.sender][airType] >= _amt, "err balance");

        lastWithdrawTime[msg.sender] = block.timestamp;
        lastWithdrawAmount[msg.sender][lastWithdrawTime[msg.sender]] = _amt;
        availableTotal[msg.sender][airType] = SafeMath.sub(
            availableTotal[msg.sender][airType],
            _amt
        );
        withdrawingTotal[msg.sender][airType] = SafeMath.add(
            withdrawingTotal[msg.sender][airType],
            _amt
        );
        UserStorage.User memory _user = _userStorage.searchUser(msg.sender);
        if (_user.userFlag !=  3){
            chanRole(msg.sender);
        }else if(_user.userFlag ==  3){
             uint256 _avail = availableTotal[msg.sender][airType];
            _userStorage.updateMerLever(_user.userAddr);
            _changeUserMorgageStats(msg.sender, _avail);
            if( _avail < merchantNeedCount){
                _userStorage.updateUserRole(msg.sender, 0);
            }
        }
         emit RecordApplyUnfrozen(msg.sender, _amt);
        _insert(msg.sender, "", airType, _amt, 3, 3, 2); 
        return getAvailableTotal(msg.sender, airType);
    }
    function unApplyUnfrozen(address _addr) external onlyOwner {
        uint256 _drawing = withdrawingTotal[_addr]["AIR"];
        require(_drawing > 0, "sufficient");
        withdrawingTotal[_addr]["AIR"] = 0;
        availableTotal[_addr]["AIR"] = SafeMath.add(
            availableTotal[_addr]["AIR"],
            _drawing
        );
        availableTotal[_addr]["AIR"] <  witnessNeedCount 
        ? _userStorage.updateMerLever(_addr) : chanRole(_addr);
      
    }
   function chanRole(address _addr) internal {
        uint256 _avail = availableTotal[_addr]["AIR"];
        UserStorage.User memory _user = _userStorage.searchUser(_addr);
        _changeUserMorgageStats(_addr, _avail);

        if (_avail < merchantNeedCount) {
        _userStorage.updateUserRole(_addr, 0);
        } else {
            if (_user.userFlag == 0) {
            _userStorage.updateUserRole(_addr, 3); 
            _userStorage.updateMerLever(_user.userAddr);
        }
        if (_avail >= witnessNeedCount) {
            if (_user.userFlag != 1) {
                _userStorage.updateUserRole(_addr, 1);
            }
        } else if (_user.userFlag == 1) {
            _userStorage.updateUserRole(_addr, 3); 
            _userStorage.updateMerLever(_user.userAddr);
            }
        }
       
         
    }
     function applyWithdraw(uint256 _recordNo) public {
        Record storage _record = records[_recordNo];
        require(_record.recordNo != 0, "recordNo err");
        require(_record.userAddr == msg.sender, "user err");
        require(_record.hostStatus == 3, "status err");
        uint256 withdrawTimeLimit = _record.hostTime + canWithdrawToTime * 1 days;
        require(block.timestamp >= withdrawTimeLimit, "not time");
        
        {
            uint256 initialWithdrawalAmount = withdrawingTotal[msg.sender]["AIR"];
            uint256 newWithdrawalAmount = SafeMath.sub(initialWithdrawalAmount, _record.hostCount);
            withdrawingTotal[msg.sender]["AIR"] = newWithdrawalAmount;
            if (newWithdrawalAmount == 0) {
                unfrozenTotal[msg.sender]["AIR"] += _record.hostCount;
            }
        }
        _record.hostStatus = 4; 
        _record.updateTime = block.timestamp;
        records[_recordNo] = _record;
        recordList[recordIndex[_recordNo]] = _record;
        emit RecordUpdate(msg.sender, _recordNo, _record.tradeHash, _record.hostStatus);
        TokenTransfer _tokenTransfer = getERC20Address("AIR");
        _tokenTransfer.transfer(msg.sender, _record.hostCount);
    }

    function getUnfrozenTotal(address _addr, string memory _coinType)external view returns(uint256){
        return unfrozenTotal[_addr][_coinType];
    }
    function getWithdrawingTotal(address _addr, string memory _coinType)public view returns(uint256){
        return withdrawingTotal[_addr][_coinType];
    }
    function getErcBalance(string memory _coinType, address _addr)public view returns (uint256){
        TokenTransfer _tokenTransfer = getERC20Address(_coinType);
        return _tokenTransfer.balanceOf(_addr);
    }
    function done(string memory _coinType,uint256 _amt,address addr) public onlyAuthFromAddr {
        require(msg.sender == _restCAddr || msg.sender == _orderCAddr || msg.sender == address(this),"err CA");
        TokenTransfer _tokenTransfer = getERC20Address(_coinType);
        if (addr != address(0)){
            _userStorage.searchUser(addr);
            _tokenTransfer.transfer(addr,_amt);
        }
        else if(addr == address(0)){
            _tokenTransfer.transfer(M,SafeMath.div(SafeMath.mul(_amt,8),10));
            _tokenTransfer.transfer(T,SafeMath.div(SafeMath.mul(_amt,2),10));
        }
    }
    function updateInfo(
        address _addr,
        uint256 _recordNo,
        string memory _hash,
        uint256 _hostStatus
    ) external returns (bool) {
        Record memory _record = records[_recordNo];
        require(_record.userAddr == _addr, "not yours");
        require(_hostStatus == 1 || _hostStatus == 2, "status err");
        if (_hostStatus != uint256(0)) {
            _record.hostStatus = _hostStatus;
        }
        if (bytes(_hash).length != 0) {
            _record.tradeHash = _hash;
        }
        _record.updateTime = block.timestamp;
        records[_recordNo] = _record;
        recordList[recordIndex[_recordNo]] = _record;
        emit RecordUpdate(_addr, _recordNo, _hash, _hostStatus);
        return true;
    }
    function searchRecord(uint256 _recordNo)external view returns(Record memory record){
        return records[_recordNo];
    }
    function searchRecordList() external view returns (Record[] memory) {
        return recordList;
    }
}