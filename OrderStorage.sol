// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./RecordInterface.sol";
import "./RestStorage.sol";
import "./UserStorage.sol";
import "./RecordStorage.sol";
import "./AppealStorage.sol";
import "./InviteStorage.sol";

pragma solidity >=0.6.2;


abstract contract ReentrancyGuardOrder {
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
library CountersOrder {
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
contract OrderStorage is Ownable, ReentrancyGuardOrder {
        using CountersOrder for CountersOrder.Counter;
        RestStorage private _restStorage;
        RecordInterface private _recordStorage;
        UserInterface private _userStorage;
        AppealInterface private _appealS;
        InviteInterface private _inviteStorage;
        address recordAddress;
        address appealAddress;
    struct Order {
        address userAddr;
        uint256 orderNo;
        uint256 restNo;
        uint256 coinCount;
        uint256 orderAmount;
        uint256 payType;
        string currencyType;
        uint256 orderType;
        uint256 orderStatus;
        string diyaType;
        OrderDetail orderDetail;
    }
    struct OrderDetail {
        address buyerAddr;
        address sellerAddr;
        string coinType;
        uint256 price;
        uint256 tradeTime;
        uint256 updateTime;
        string tradeHash;
        uint256 tradeFee;
    }
    mapping(uint256 => bool) public buyerApproval;
    mapping(uint256 => bool) public sellerApproval;
    mapping(address => mapping(string => mapping(uint256 => uint256))) private OuserDiya;
    CountersOrder.Counter private _orderNoCounter;
    mapping(uint256 => Order) private orders;
    mapping(uint256 => uint256) private orderIndex;
    Order[] private orderList;
    mapping(address => mapping(uint256 => uint256)) orderFrozenTotal;
    uint256 cancelOrderTime = 1;
    function addDiya(uint256 _orderNo,string memory CoinType, string memory DiCoinType, uint256 amount) 
    internal {
         uint256 NeedDiya;
        if (keccak256(abi.encodePacked(DiCoinType)) == keccak256(abi.encodePacked(CoinType)) ){
            NeedDiya = SafeMath.div(amount,10);
            OuserDiya[msg.sender][DiCoinType][_orderNo] = SafeMath.add(
                OuserDiya[msg.sender][DiCoinType][_orderNo],NeedDiya
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
            OuserDiya[msg.sender][DiCoinType][_orderNo] = SafeMath.add(
                OuserDiya[msg.sender][DiCoinType][_orderNo],NeedDiya
            );
        }
        require(OuserDiya[msg.sender][DiCoinType][_orderNo] > 0, "count err");
        TokenTransfer _tokenTransferD = _recordStorage.getERC20Address(DiCoinType);
        _tokenTransferD.transferFrom(msg.sender, recordAddress, NeedDiya);
         emit Diya(msg.sender,_orderNo, DiCoinType, NeedDiya);
    }
    function zeroDiya(uint256 orderNo,string memory CoinType,address user)public{
        require(msg.sender == recordAddress ,"unauth");
        OuserDiya[user][CoinType][orderNo] =0;
    }
    function getDy(uint256 orderNo,string memory CoinType,address user) public  view  returns (uint256) {
        return OuserDiya[user][CoinType][orderNo];
    }
    function setCancelOrderTime(uint256 _count) public onlyOwner {
        cancelOrderTime = _count;
    }
    function getCancelOrderTime() public view returns (uint256) {
        return cancelOrderTime;
    }
    uint256 canWithdrawHours = 24;
    function setCanWithdrawHours(uint256 _count) public onlyOwner {
        canWithdrawHours = _count;
    }
    function getCanWithdrawHours() public view returns (uint256) {
        return canWithdrawHours;
    }
    event OrderAdd(
        uint256 _orderNo,
        uint256 _restNo,
        uint256 _coinCount,
        uint256 _tradeFee,
        uint256 _orderAmount,
        uint256 _payType,
        uint256 _orderType,
        address _buyerAddr,
        address _sellerAddr,
        uint256 tradeTime,
        uint256 orderStatus
    );
    event OrderPaidMoney(uint256 _orderNo);
    event OrderConfirmCollect(uint256 _orderNo);
    event OrderCancel(uint256 _orderNo);
    event OrderUpdateStatus(uint256 _orderNo, uint256 _orderStatus);
    event Diya(address indexed user,uint256 orderNo, string DicoinType, uint256 amount);
    function authFromContract(
        address _recordAddr,
        address _restAddr,
        address _userAddr,
        address _appealAddr,
        address _inviteAddr
    ) external onlyOwner {
        _recordStorage = RecordInterface(_recordAddr);
        _restStorage = RestStorage(_restAddr);
        _userStorage = UserInterface(_userAddr);
        recordAddress = _recordAddr;
        appealAddress = _appealAddr;
        _appealS = AppealInterface(_appealAddr);
        _inviteStorage = InviteInterface(_inviteAddr);
        _orderNoCounter.increment();
    }
    modifier onlyBuyer(uint256 _orderNo) {
        require(_orderNo != uint256(0), "orderNo null");
        require(
            orders[_orderNo].orderDetail.buyerAddr == msg.sender,
            "only buyer"
        );
        _;
    }
    modifier onlySeller(uint256 _orderNo) {
        require(_orderNo != uint256(0), "orderNo null");
        require(
            orders[_orderNo].orderDetail.sellerAddr == msg.sender,
            "only seller"
        );
        _;
    }
    modifier onlyBuyerOrSeller(uint256 _orderNo) {
        require(_orderNo != uint256(0), "orderNo null");
        require(
            orders[_orderNo].orderDetail.sellerAddr == msg.sender ||
                orders[_orderNo].orderDetail.buyerAddr == msg.sender,
            "Only buyer or seller"
        );
        _;
    }
     modifier onlyBOSOA(uint256 _orderNo) {
        require(_orderNo != uint256(0), "orderNo null");
        require(
            orders[_orderNo].orderDetail.sellerAddr == msg.sender ||
            orders[_orderNo].orderDetail.buyerAddr == msg.sender || appealAddress == msg.sender,
            "Only buyer or seller"
        );
        _;
    }
    function _checkParam(
        uint256 _restNo,
        uint256 _coinCount,
        uint256 _orderAmount,
        uint256 _payType
    ) internal pure {
        require(_restNo != uint256(0), "restNo null");
        require(_coinCount > 0, "coinCount null");
        require(_orderAmount > 0, "orderAmount null");
        require(_payType != uint256(0), "payType null");
    }
    function _insert(
        uint256 _restNo,
        uint256 _coinCount,
        uint256 _tradeFee,
        uint256 _orderAmount,
        uint256 _payType,
        uint256 _orderType,
        address _buyerAddr,
        address _sellerAddr,
        string memory _diyaType
    ) internal nonReentrant returns (uint256 restNo) {
        _checkParam(_restNo, _coinCount, _orderAmount, _payType);
        RestStorage.Rest memory _rest = _restStorage.searchRest(_restNo);
        require(_rest.userAddr != address(0), "rest not exist");
        OrderDetail memory _orderDetail = OrderDetail({
            buyerAddr: _buyerAddr,
            sellerAddr: _sellerAddr,
            coinType: _rest.coinType,
            price: _rest.price,
            tradeTime: block.timestamp,
            updateTime: 0,
            tradeHash: "",
            tradeFee: _tradeFee
    
        });
        uint256 _orderNo = _orderNoCounter.current();
        require(orders[_orderNo].orderNo == uint256(0), "order exist");
        Order memory order = Order({
            userAddr: msg.sender,
            orderNo: _orderNo,
            restNo: _restNo,
            coinCount: _coinCount,
            orderAmount: _orderAmount,
            payType: _payType,
            currencyType: _rest.currencyType,
            orderType: _orderType,
            orderStatus: 1,
            diyaType : _diyaType,
            orderDetail: _orderDetail
        });
        orders[_orderNo] = order;
        orderList.push(order);
        orderIndex[_orderNo] = orderList.length - 1;
        if (_orderType == 2) {
            orderFrozenTotal[msg.sender][_orderNo] = _coinCount;
        } else if (_orderType == 1) {
            orderFrozenTotal[_rest.userAddr][_orderNo] = _coinCount;
        }
        _orderNoCounter.increment();
        emit OrderAdd(
            _orderNo,
            _restNo,
            _coinCount,
            _tradeFee,
            _orderAmount,
            _payType,
            _orderType,
            _buyerAddr,
            _sellerAddr,
            _orderDetail.tradeTime,
            order.orderStatus
        );
        return _orderNo;
    }

    function addBuyOrder(
        uint256 _restNo,
        uint256 _coinCount,
        uint256 _orderAmount,
        uint256 _payType,
        string memory _dicoinType
    ) external returns (uint256){
        RestStorage.Rest memory _rest = _restStorage.searchRest(_restNo);
        require(_rest.restType == 2, "sell rest not exist");
        _preValidate(_restNo, _coinCount, _orderAmount);
        uint256 _orderNo = _insert(
            _restNo,
            _coinCount,
            0,
            _orderAmount,
            _payType,
            1,
            msg.sender,
            _rest.userAddr,
            _dicoinType
        );
        _restStorage.updateRestFinishCount(_restNo, _coinCount);
        addDiya(_orderNo,_rest.coinType, _dicoinType, _coinCount);  
       return _orderNo;

    }
    function addSellOrder(
        uint256 _restNo,
        uint256 _coinCount,
        uint256 _orderAmount,
        uint256 _payType,
        string memory _dicoinType
        ) external returns (uint256){
        RestStorage.Rest memory _rest = _restStorage.searchRest(_restNo);
        uint256 _tradeFee = SafeMath.div(SafeMath.mul(_coinCount,12),1000);
        require(_rest.restType == 1, "buy rest not exist");
        _preValidate(_restNo, _coinCount, _orderAmount);
        uint256 _orderNo = 
        _executeTrade(_restNo, _coinCount, _tradeFee, _orderAmount, _payType, _dicoinType);
        return _orderNo;
    }

    function _preValidate(
        uint256 _restNo,
        uint256 _coinCount,
        uint256 _orderAmount
        ) internal view{
        RestStorage.Rest memory _rest = _restStorage.searchRest(_restNo);
        require(_rest.userAddr != msg.sender, "rest not exist");
        require(_coinCount > 0, "coin count error");
        require(_orderAmount > 0, "orderAmount error");
        require(_rest.restStatus == 1, "rest status error");
        uint256 _amo = SafeMath.mul(_rest.price,SafeMath.div(_coinCount,10000));
        require(_amo >= _rest.restDetail.limitAmountFrom &&
            _amo <= _rest.restDetail.limitAmountTo, "amount error");
        UserStorage.User memory _currentUser = _userStorage.searchUser(msg.sender);
        require(_currentUser.userFlag != 1 && _currentUser.userFlag != 2, "invalid user");
        require(_currentUser.credit >= _rest.restDetail.limitMinCredit, "credit error");
        require(_currentUser.morgageStats.mortgage >= _rest.restDetail.limitMinMortgage, "mortgage error");
    }

    function _executeTrade(
        uint256 _restNo,
        uint256 _coinCount,
        uint256 _tradeFee,
        uint256 _orderAmount,
        uint256 _payType,
        string memory _dicoinType
        ) internal returns (uint256) {
        RestStorage.Rest memory _rest = _restStorage.searchRest(_restNo);
        TokenTransfer _tokenTransfer = _recordStorage.getERC20Address(_rest.coinType);
        uint256 _needSub = SafeMath.add(_coinCount, _tradeFee);
        _tokenTransfer.transferFrom(msg.sender, recordAddress, _needSub);
        _restStorage.updateRestFinishCount(_restNo, _coinCount);
        _recordStorage.addRecord(
            msg.sender,
            "",
            _rest.coinType,
            _coinCount,
            2,
            1, 
            2  
        );
        uint256 _orderNo = _insert(
            _restNo,
            _coinCount,
            _tradeFee,
            _orderAmount,
            _payType,
            2, 
            _rest.userAddr,
            msg.sender,
            _dicoinType
        );

        addDiya(_orderNo,_rest.coinType, _dicoinType, _coinCount);
    

        return _orderNo;
    }
    function setPaidMoney(uint256 _orderNo)
        external
        onlyBuyer(_orderNo)
        returns (bool)
    {
        Order memory _order = orders[_orderNo];
        require(_order.orderStatus == 1, "Invalid order status");
        require(buyerApproval[_orderNo] == false && sellerApproval[_orderNo] == false,"one cancel");
        _updateOrderStatus(_orderNo, 2);
        emit OrderPaidMoney(_orderNo);
        return true;
    }
    function confirmCollect(uint256 _orderNo) external onlySeller(_orderNo) {
        require(_orderNo != uint256(0), "orderNo null");
        Order memory _order = orders[_orderNo];
        require(_order.orderStatus == 2, "Invalid order status");
        require(buyerApproval[_orderNo] == false && sellerApproval[_orderNo] == false,"one cancel");
        require(_order.orderDetail.buyerAddr != address(0),"Invalid buyer address");
        require(orderFrozenTotal[msg.sender][_orderNo] >= _order.coinCount,"coin not enough");

        _updateOrderStatus(_orderNo, 3);
        orderFrozenTotal[msg.sender][_orderNo] = 0;

        uint256 _rc = _recordStorage.getTradeCredit();
        UserStorage.User memory _user = _userStorage.searchUser(msg.sender);
        uint256 _credit = _user.credit + _rc;
        UserStorage.TradeStats memory _tradeStats = _user.tradeStats;
        _tradeStats.tradeTotal += 1;
        _userStorage.updateTradeStats(msg.sender, _tradeStats, _credit);
        UserStorage.User memory _user2 = _userStorage.searchUser(
            _order.orderDetail.buyerAddr
        );
        uint256 _credit2 = _user2.credit + _rc;
        UserStorage.TradeStats memory _tradeStats2 = _user2.tradeStats;
        _tradeStats2.tradeTotal += 1;
        
        _userStorage.updateTradeStats(
            _order.orderDetail.buyerAddr,
            _tradeStats2,
            _credit2
        );
        _recordStorage.backDiya(_order.orderNo,getDy(_orderNo,_order.diyaType,_order.userAddr),2);
        
        _recordStorage.subFrozenTotal(_orderNo, _order.orderDetail.buyerAddr);

        RestStorage.Rest memory _rest = _restStorage.searchRest(_order.restNo);
        if (_rest.restDetail.remainderCount == 0) {
            _recordStorage.backDiya(_order.restNo,_restStorage.getDy(_order.restNo,_rest.diCoinType,_rest.userAddr),1); 
        }
        _userStorage.updateTradeLimit(_rest.userAddr,_order.coinCount,2);

        _inviteStorage.RewardInvite(_order.userAddr);

        uint256 needFee = SafeMath.div(SafeMath.mul(_order.coinCount,12),1000);
        _recordStorage.done(_rest.coinType,needFee,address(0));

        emit OrderConfirmCollect(_orderNo);
    }

    function cancelOrder(uint256 _orderNo) external onlyBuyerOrSeller(_orderNo) returns (bool r) {
        Order memory _order = orders[_orderNo];
        require(_order.orderStatus == 1,"status err");
        require(_order.orderNo != uint256(0), "Order does not exist");

        if (msg.sender == orders[_orderNo].orderDetail.buyerAddr) {
            require(buyerApproval[_orderNo] == false,"you had cancle,wit");
            buyerApproval[_orderNo] = true;
        } else if (msg.sender == orders[_orderNo].orderDetail.sellerAddr) {
            require(sellerApproval[_orderNo] == false,"you had cancle,wit");
            sellerApproval[_orderNo] = true;
        }

        if( 
           (sellerApproval[_orderNo] && buyerApproval[_orderNo]) || 
           (_order.orderDetail.tradeTime + cancelOrderTime * 1 hours >= block.timestamp && sellerApproval[_orderNo]) 
          ){
            RestStorage.Rest memory _rest = _restStorage.searchRest(_order.restNo);
            if (_rest.restStatus == 4 || _rest.restStatus == 5) {
                orderFrozenTotal[_order.orderDetail.sellerAddr][_orderNo] = 0;
                _recordStorage.addAvailableTotal(
                    _order.orderDetail.sellerAddr,
                    _order.orderDetail.coinType,
                    _order.coinCount
                );
            }
            else {
                    if (_order.orderType == 2) {
                        orderFrozenTotal[_order.orderDetail.sellerAddr][_orderNo] = 0;
                        _recordStorage.addAvailableTotal(
                        _order.orderDetail.sellerAddr,
                        _order.orderDetail.coinType,
                        _order.coinCount);
                    }
            _restStorage.addRestRemainCount(_order.restNo, _order.coinCount);
            }
            _recordStorage.backDiya(_order.orderNo, getDy(_orderNo, _order.diyaType, _order.userAddr), 2);

            _updateOrderStatus(_orderNo, 4);
            emit OrderCancel(_orderNo);
            buyerApproval[_orderNo] = false;
            sellerApproval[_orderNo] = false;
            return true;
        }  
    }
    function takeAppealReward(uint256 _orderNo)external {
        AppealStorage.Appeal memory _al = _appealS.searchAppeal(_orderNo);
        require(_al.detail.observerAddr == msg.sender || _al.witness == msg.sender);
        require(_al.buyer != msg.sender && _al.seller != msg.sender);
        require(_al.status != 4 || _al.status != 5,"wait top");
        _recordStorage.takeReward(_orderNo,msg.sender);
    }
    function takeCoin(uint256 _o) external onlyBuyerOrSeller(_o) {
        AppealStorage.Appeal memory _appeal = _appealS.searchAppeal(_o);
        if (_appeal.detail.observerHandleTime != 0){
            require(block.timestamp - _appeal.detail.observerHandleTime > canWithdrawHours * 1 hours,
            "time error"
        );
        }
        require(block.timestamp - _appeal.detail.witnessHandleTime > canWithdrawHours * 1 hours,
            "time error"
        );
        address _win;
        if (_appeal.user == _appeal.buyer) {
            if (_appeal.status == 2 ) {
                _win = _appeal.buyer;
            } else if (_appeal.status == 3 ) {
                _win = _appeal.seller;
            }
        } else {
            if (_appeal.status == 2 ) {
                _win = _appeal.seller;
            } else if (_appeal.status == 3) {
                _win = _appeal.buyer;
            }
        }
        require(_win == msg.sender, "opt error");
        _updateOrderStatus(_o, 5);
        orderFrozenTotal[_appeal.seller][_o] = 0;
        _recordStorage.subFrozenTotal(_o, msg.sender);
    }
    function updateOrderStatus(uint256 _orderNo, uint256 _orderStatus) public{
        _updateOrderStatus(_orderNo,_orderStatus);
    }
    function _updateOrderStatus(uint256 _orderNo, uint256 _orderStatus)internal 
    onlyBOSOA(_orderNo){
        Order memory order = orders[_orderNo];
        require(order.orderNo != uint256(0), "current Order not exist");
        require(_orderStatus >= 1 && _orderStatus <= 5, "Invalid order status");
        if (_orderStatus == 2 && order.orderStatus != 1) {
            revert("Invalid order status 2");
        }
        if (_orderStatus == 3 && order.orderStatus != 2) {
            revert("Invalid order status 3");
        }
        if (_orderStatus == 4 && order.orderStatus != 1) {
            revert("Invalid order status 4");
        }
        if ( _orderStatus == 5 && order.orderStatus != 1 && order.orderStatus != 2) {
            revert("Invalid order status 5");
        }
        if (_orderStatus == 2) {
            require( order.orderDetail.buyerAddr == msg.sender,"only buyer call");
        }
        if (_orderStatus == 3) {
            require( order.orderDetail.sellerAddr == msg.sender,"only seller call");
        }
        order.orderStatus = _orderStatus;
        order.orderDetail.updateTime = block.timestamp;
        orders[_orderNo] = order;
        orderList[orderIndex[_orderNo]] = order;
        emit OrderUpdateStatus(_orderNo, _orderStatus);
    }
    function searchOrder(uint256 _orderNo)external view returns (Order memory order){
        require( _orderNo != uint256(0), "orderNo null");
        require( orders[_orderNo].orderNo != uint256(0),"current Order not exist");
        Order memory o = orders[_orderNo];
        return o;
    }
    function searchOrderList() external view returns (Order[] memory) {
        return orderList;
    }
    function searchListByRest(uint256 _restNo)external view returns (Order[] memory){
        Order[] memory resultList = new Order[](orderList.length);
        for (uint256 i = 0; i < orderList.length; i++) {
            Order memory _order = orderList[i];
            if (_order.restNo == _restNo) {
                resultList[i] = _order;
            }
        }
        return resultList;
    }
}
