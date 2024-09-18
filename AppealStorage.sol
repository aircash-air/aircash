// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

import "./RecordInterface.sol";
import "./UserStorage.sol";
contract AppealStorage is Ownable{
    OrderInterface private _oSt;
    RecordInterface private _rSt;
    UserInterface private _uSt;
    RestInterface private _reSt;
    address recAddr;
    struct Appeal {
        address user;
        uint256 appealNo;
        uint256 orderNo;
        address witness;
        address buyer;
        address seller;
        uint256 status;
        uint256 appealTime;
        uint256 witTakeTime;
        uint256 obTakeTime;
        AppealDetail detail;
    }
    struct AppealDetail {
        address finalAppealAddr;
        uint256 updateTime;
        string witnessReason;
        uint256 witnessAppealStatus;
        string observerReason;
        uint256 witnessHandleTime;
        uint256 observerHandleTime;
        address observerAddr;
        uint256 observerHandleReward;
        uint256 witReward;
        uint256 RewardNo;
        string RewardType;
        uint256 RewardFlag;
    }
    mapping(uint256 => Appeal) public appeals;
    mapping(uint256 => uint256) public appealIndex;
    Appeal[] public appealList;
    event addAppeal(uint256 _appealNo, uint256 _orderNo,address buyer,address seller,address user);
    event addFinal(uint256 _appeal, uint256 _orderNo,uint256 status);
    event takeWitness(uint256 _appealNo,uint256 _orderNo,address witness);
    event takeobserver(uint256 _appealNo,uint256 _orderNo,address observer);
    event judgeOpt(uint256 _appealNo,uint256 _orderNo,uint256 status);

    function authFromContract(
        address _r,
        address _o,
        address _u,
        address _re) external onlyOwner {
		_rSt = RecordInterface(_r);
        _oSt = OrderInterface(_o);
        _uSt = UserInterface(_u);
        _reSt = RestInterface(_re);
        recAddr = _r;
	}
    modifier onlyWit(uint256 _o) {
        Appeal memory _al = appeals[_o];
        require(_al.witness == msg.sender);
        require(_al.buyer != msg.sender && _al.seller != msg.sender);
        _;
    }
    modifier onlyOb(uint256 _o) {
        Appeal memory _al = appeals[_o];
        require(_al.detail.observerAddr == msg.sender);
        require(_al.buyer != msg.sender && _al.seller != msg.sender);
        _;
    }
    modifier onlyBOS(uint256 _o) {
        OrderStorage.Order memory _r = _oSt.searchOrder(_o);
        require(
            _r.orderDetail.sellerAddr == msg.sender ||
                _r.orderDetail.buyerAddr == msg.sender
        );
        _;
    }
    function _insert(uint256 _o) internal {
        OrderStorage.Order memory _or = _oSt.searchOrder(_o);
        require(appeals[_o].appealNo == uint256(0));
        address _buyer = _or.orderDetail.buyerAddr;
        address _seller = _or.orderDetail.sellerAddr;

        Appeal memory _appeal;
        _appeal.user = msg.sender;
        _appeal.appealNo = block.timestamp;
        _appeal.orderNo = _o;
        _appeal.buyer = _buyer;
        _appeal.seller = _seller;
        _appeal.status = 1;
        _appeal.appealTime = block.timestamp;

        appeals[_o] = _appeal;
        appealList.push(_appeal);
        appealIndex[_o] = appealList.length - 1;
        chanT(_or.orderDetail.sellerAddr, _or.orderDetail.buyerAddr, 1, 0);
        emit addAppeal(block.timestamp, _o,_buyer,_seller,msg.sender);
    }
   
    function chanT(
        address _seller,
        address _buyer,
        uint256 _t,
        uint256 _r
    ) internal {
        uint256 _tc = _rSt.getTradeCredit();
        uint256 _rs = _rSt.getSubTCredit();
        UserStorage.User memory _user = _uSt.searchUser(_seller);
        UserStorage.TradeStats memory _tr = _user.tradeStats;
        UserStorage.User memory _user2 = _uSt.searchUser(_buyer);
        UserStorage.TradeStats memory _tr2 = _user2.tradeStats;
        uint256 _c2 = _user2.credit;
        uint256 _c = _user.credit;
        if (_t == 1) {
            _tr.tradeTotal = _tr.tradeTotal > 0 ? (_tr.tradeTotal - 1) : 0;
            _tr2.tradeTotal = _tr2.tradeTotal > 0 ? (_tr2.tradeTotal - 1) : 0;
            _c = (_c >= _tc) ? (_c - _tc) : 0;
            _c2 = (_c2 >= _tc) ? (_c2 - _tc) : 0;
        } else if (_t == 2) {
            _tr.tradeTotal += 1;
            _tr2.tradeTotal += 1;
            if (_r == 1) {
                _c += _tc;
                _c2 = (_c2 >= _rs) ? (_c2 - _rs) : 0;
            } else if (_r == 2) {
                _c2 += _tc;
                _c = (_c >= _rs) ? (_c - _rs) : 0;
            }
        }
        _uSt.updateTradeStats(_seller, _tr, _c);
        _uSt.updateTradeStats(_buyer, _tr2, _c2);
    }
    function applyAppeal(uint256 _o) external onlyBOS(_o) {
        OrderStorage.Order memory _or = _oSt.searchOrder(_o);
        require(_or.orderStatus <=3,"status err");
        _insert(_o);
    }
    function takeWit(uint256 _o) external {
        Appeal storage _al = appeals[_o];
        require(_al.buyer != msg.sender && _al.seller != msg.sender);
        require(_al.witness == address(0));
        require(_al.status == 1);
        bool _f = witOrOb(1);
        require(_f);
        _al.witness = msg.sender;
        _al.witTakeTime = block.timestamp;
        save(_o,_al);
        emit takeWitness(_al.appealNo,_o,msg.sender);
    }
    function takeOb(uint256 _o) external {
        Appeal storage _al = appeals[_o];
        require(_al.buyer != msg.sender && _al.seller != msg.sender);
        require(_al.status == 4 || _al.status == 5);
        require(_al.detail.observerAddr == address(0));
        bool _f = witOrOb(2);
        require(_f);
        _al.detail.observerAddr = msg.sender;
        _al.obTakeTime = block.timestamp;
        save(_o,_al);
        emit takeobserver(_al.appealNo,_o,msg.sender);
    }
    function changeHandler(uint256 _o, uint256 _type) external onlyBOS(_o) {
        Appeal storage _al = appeals[_o];
        if (_type == 1) {
            require(_al.status == 1);
            require(_al.witness != address(0));
            require(block.timestamp - _al.witTakeTime > 24 hours);
            _al.witness = address(0);
            _al.witTakeTime = 0;
        } else if (_type == 2) {
            require(_al.status == 4 || _al.status == 5);
            require(_al.detail.observerAddr != address(0));
            require(block.timestamp - _al.obTakeTime > 24 hours);
            _al.detail.observerAddr = address(0);
            _al.obTakeTime = 0;
        }
        save(_o,_al);
       
    }
    function witOrOb(uint256 _f) internal view returns (bool) {
        UserStorage.User memory _u = _uSt.searchUser(msg.sender);
        if (_u.userFlag == _f) {
            return true;
        }
        return false;
    }
    function applyFinal(uint256 _o) external onlyBOS(_o) {
        Appeal storage _al = appeals[_o];
        require(_al.status == 2 || _al.status == 3);
        require(block.timestamp - _al.detail.witnessHandleTime <= 24 hours);
        chanT(_al.seller, _al.buyer, 1, 0);
        _al.status = _al.status == 2 ? 4 : 5;
        _al.detail.finalAppealAddr = msg.sender;
        save(_o,_al);
        emit addFinal(_al.appealNo,_o,_al.status);
    }

    function witnessOpt(uint256 _o,string memory _r,uint256 _s) external onlyWit(_o) {
        require(_s == 2 || _s == 3, "Invalid status");
    
        Appeal storage _al = appeals[_o];
        require(_al.status == 1, "Appeal status err");
    
        uint256 currentTime = block.timestamp;
    
        OrderStorage.Order memory _or = _oSt.searchOrder(_o);
        RestStorage.Rest memory _rest = _reSt.searchRest(_or.restNo);
    
        _al.status = _s;
        _al.detail.witnessAppealStatus = _s;
        _al.detail.witnessReason = _r;
        _al.detail.witnessHandleTime = currentTime;

        bool isUser = (_al.user != _rest.userAddr);
    
        if (_s == 2) {
            chanT(_al.seller, _al.buyer, 2, 1);

            if (isUser) {
                _al.detail.witReward = SafeMath.div(
                    SafeMath.mul(
                        _reSt.getDy(_rest.restNo, _rest.diCoinType, _rest.userAddr),_or.coinCount),
                    _rest.restCount
                );
                _al.detail.RewardType = _rest.diCoinType;
                _al.detail.RewardNo = _rest.restNo;
                _al.detail.RewardFlag = 2;
            } else {
                _al.detail.witReward = _oSt.getDy(_or.orderNo, _or.diyaType, _or.userAddr);
                _al.detail.RewardType = _or.diyaType;
                _al.detail.RewardNo = _or.orderNo;
                _al.detail.RewardFlag = 1;
            }
        } else {
            chanT(_al.seller, _al.buyer, 2, 2);

            if (isUser) {
                _al.detail.witReward = _oSt.getDy(_or.orderNo, _or.diyaType, _or.userAddr);
                _al.detail.RewardType = _or.diyaType;
                _al.detail.RewardNo = _or.orderNo;
                _al.detail.RewardFlag = 1;
            } else {
                _al.detail.witReward = SafeMath.div(
                    SafeMath.mul(
                        _reSt.getDy(_rest.restNo, _rest.diCoinType, _rest.userAddr), _or.coinCount),
                    _rest.restCount
                );
                _al.detail.RewardType = _rest.diCoinType;
                _al.detail.RewardNo = _rest.restNo;
                _al.detail.RewardFlag = 2;
            }
        }
        save(_o,_al);
        _rSt.subAvaAppeal(_al, 1);
        emit judgeOpt(_al.appealNo, _o, _s);
    }

    function observerOpt(
        uint256 _o,
        string memory _r,
        uint256 _s
        ) external onlyOb(_o) {
        require(_s == 6 || _s == 7);
        Appeal storage _appeal = appeals[_o];
        require(_appeal.status == 4 || _appeal.status == 5);
        uint256 _subWC = _rSt.getSubWitCredit();

        _appeal.status = _s;
        _appeal.detail.observerReason = _r;
        _appeal.detail.observerHandleTime = block.timestamp;
        _appeal.detail.updateTime = block.timestamp;
        address  winer;

        if(_s == 6){
            if (_appeal.user == _appeal.buyer) {
                winer = _appeal.buyer;
                chanT(_appeal.seller, _appeal.buyer, 2, 2);
            } else {
                winer = _appeal.seller;
                chanT(_appeal.seller, _appeal.buyer, 2, 1);
            }
        }else{
            if (_appeal.user == _appeal.buyer) {
                winer = _appeal.seller;
                chanT(_appeal.seller, _appeal.buyer, 2, 1);
            } else {
                winer = _appeal.buyer;
                chanT(_appeal.seller, _appeal.buyer, 2, 2);
            }
        }
    
    _rSt.subAvaAppeal(_appeal, 2);
    _rSt.subFrozenTotal(_o, winer);

    if (_appeal.detail.witnessAppealStatus == 3 && _s == 6 ||
        _appeal.detail.witnessAppealStatus == 2 && _s == 7) {
        OrderStorage.Order memory _or = _oSt.searchOrder(_o);
        RestStorage.Rest memory _rest = _reSt.searchRest(_or.restNo);

        _appeal.detail.observerHandleReward = 
        _appeal.detail.witReward == _oSt.getDy(_or.orderNo, _or.diyaType, _or.userAddr) ?
        SafeMath.div(SafeMath.mul(
            _reSt.getDy(_rest.restNo, _rest.diCoinType, _rest.userAddr), _or.coinCount),_rest.restCount) 
        : _oSt.getDy(_or.orderNo, _or.diyaType, _or.userAddr);
        _appeal.detail.witReward = 0;
        _appeal.detail.RewardNo = _appeal.detail.RewardNo == _or.orderNo ? _rest.restNo : _or.orderNo;
        _appeal.detail.RewardType = keccak256(abi.encodePacked(_appeal.detail.RewardType)) == keccak256(abi.encodePacked(_or.diyaType)) ? _rest.diCoinType : _or.diyaType;
        _appeal.detail.RewardFlag = _appeal.detail.RewardFlag == 1 ? 2 : 1 ;
       
        UserStorage.User memory _user = _uSt.searchUser(_appeal.witness);
        _user.credit = _user.credit >= _subWC ? SafeMath.sub(_user.credit, _subWC) : 0;
        UserStorage.TradeStats memory _tradeStats = _user.tradeStats;
        _uSt.updateTradeStats(_appeal.witness, _tradeStats, _user.credit);
    }
    _oSt.updateOrderStatus(_o,5);
    save(_o,_appeal);
    emit judgeOpt(_appeal.appealNo,_o,_s);

    }
    
    function searchAppeal(uint256 _o) external view returns (Appeal memory appeal){
        return appeals[_o];
    }
    function searchAppealList() external view returns (Appeal[] memory) {
        return appealList;
    }
    function zeroReward(uint256 _no)external{
        require(msg.sender == recAddr);
         Appeal storage _appeal = appeals[_no];
        _appeal.detail.witReward = 0;
        _appeal.detail.observerHandleReward = 0;
        save(_no,_appeal);
    }
    function save(uint256 _no,Appeal storage _appeal)private {
        _appeal.detail.updateTime = block.timestamp;
        appeals[_no] = _appeal;
        appealList[appealIndex[_no]] = _appeal;
    }
    
}
