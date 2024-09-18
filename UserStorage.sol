// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol

// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
import "./RecordInterface.sol";
import "./AppealStorage.sol";
contract UserStorage is Ownable {
    struct User {
        address userAddr; 
        string avatar; 
        string email;  
        uint isOnline; 
        uint userFlag; 
        uint256 credit; 
        uint regTime; 
		uint256 TradeLimit;
		uint isLimit;
		uint lever;
        TradeStats tradeStats; 
        MorgageStats morgageStats; 
    }
    struct TradeStats {
        uint256 tradeTotal;
        uint256 restTotal; 
    }
    struct MorgageStats {
        uint256 mortgage; 
        uint256 freezeMortgage; 
        uint256 relieveMortgage; 
        uint256 inviteUserCount; 
        uint256 inviteUserReward; 
        uint applyRelieveTime; 
        uint handleRelieveTime; 
		 
    }
	RecordInterface private _recordStorage;
    mapping (address => User) public users;
    mapping (address => uint256) public userIndex;
    User[] public userList; 
    event addUser(address _userAddr);
    event updateUser(string _avatar, string _email, uint _isOnline);
	address _restCAddr;
	address _orderCAddr;
	address _recordCAddr;
	address _appealCAddr;
	modifier onlyAuthFromAddr() {
		require(_restCAddr != address(0), 'Invalid address call rest');
		require(_orderCAddr != address(0), 'Invalid address call order');
		require(_recordCAddr != address(0), 'Invalid address call record');
		require(_appealCAddr != address(0), 'Invalid address call appeal');
		_;
	}
	function authFromContract(address _fromRest, address _fromOrder, address _fromRecord, address _fromAppeal) external onlyOwner {
		_restCAddr = _fromRest;
		_orderCAddr = _fromOrder;
		_recordCAddr = _fromRecord;
		_appealCAddr = _fromAppeal;
		 _recordStorage = RecordInterface(_fromRecord);
	}
    modifier onlyMemberOf() {
        require(users[msg.sender].userAddr != address(0), 'has no permission');
        _;
    }
    function _insert(address _addr) internal {
		require(_addr != address(0), "UserStorage: addr null is not allowed");
		require(users[_addr].userAddr == address(0), "UserStorage: current User exist");
		TradeStats memory tradeStats = TradeStats({tradeTotal:0, restTotal:0});
        MorgageStats memory morgageStats = MorgageStats({mortgage:0, freezeMortgage:0, relieveMortgage: 0, inviteUserCount:0, inviteUserReward:0, applyRelieveTime:0, handleRelieveTime:0});
 		User memory u = User({userAddr:_addr, avatar: '', email:'',
        isOnline:1, userFlag:0, credit:0, regTime:block.timestamp,tradeStats:tradeStats,TradeLimit :0, isLimit: 0 ,lever:0,morgageStats:morgageStats});
        users[_addr] = u;
		userList.push(u);
		userIndex[_addr] = userList.length -1;
		emit addUser(_addr);
	}
	function updateTradeLimit(address _addr, uint256 _changeAmount,uint flag) onlyAuthFromAddr public {
	require(
        msg.sender == _restCAddr || 
        msg.sender == _orderCAddr || 
        msg.sender == _appealCAddr || 
        msg.sender == _recordCAddr,
        'UserStorage: Invalid from contract address'
    );
    require(users[_addr].userAddr != address(0), "UserStorage: User does not exist");
    User storage user = users[_addr];
    uint256 oldLimit = user.TradeLimit;
	require(flag == 1 || flag ==2);
    if (flag == 1) {
		user.TradeLimit = SafeMath.sub(oldLimit,_changeAmount);
		require(SafeMath.sub(oldLimit,_changeAmount) <= oldLimit, "UserStorage: overflow");
    } else if (flag == 2 ) {
		user.TradeLimit = SafeMath.add(oldLimit,_changeAmount);
        require(SafeMath.add(oldLimit,_changeAmount) >= oldLimit, "UserStorage: overflow");
	}
    userList[userIndex[_addr]] = user;
	}

	function _updateInfo(address _addr, string memory _avatar, string memory _email, uint _isOnline) internal {
		require(_addr != address(0), "UserStorage: _addr null is not allowed");
		require(users[_addr].userAddr != address(0), "UserStorage: current User not exist");
		User memory u = users[_addr];
		if(bytes(_avatar).length != 0){
			u.avatar = _avatar;
		}
		if(bytes(_email).length != 0){
			u.email = _email;
		}
		if(_isOnline != uint(0)){
			u.isOnline = _isOnline;
		}
		users[_addr] = u;
		userList[userIndex[_addr]] = u;
	}
    function zeroMerLever(address addr) public {
        require(msg.sender == _recordCAddr);
        User memory _user = users[addr];
        _user.isLimit = 0;
        _user.TradeLimit = 0;
        _user.lever = 0;
        users[addr] = _user;
		userList[userIndex[addr]] = _user;
    }
	 function updateMerLever(address addr) public{
        User memory _user = users[addr];
        uint256 used;
        if(_user.lever == 1){
            used = SafeMath.sub(2000 * 10**18, _user.TradeLimit);
        }
        if(_user.lever == 2){
            used = SafeMath.sub(4000 * 10**18, _user.TradeLimit);
        }
        if(_user.lever == 3){
            used = SafeMath.sub(6000 * 10**18,_user.TradeLimit);
        }
        if(_user.lever == 4){
            used = SafeMath.sub(8000 * 10**18,_user.TradeLimit);
        }
		if(_recordStorage.getAvailableTotal(addr,"AIR") >= 100000000 * 10**18){
            _user.isLimit = 0;
            _user.TradeLimit = SafeMath.sub(2000 * 10**18,used) ;
            _user.lever = 1;
        }
        if(_recordStorage.getAvailableTotal(addr,"AIR") >= 200000000 * 10**18){
            _user.isLimit = 0;
           _user.TradeLimit = SafeMath.sub(4000 * 10**18,used) ;
            _user.lever = 2;
        }
        if(_recordStorage.getAvailableTotal(addr,"AIR") >= 300000000 * 10**18){
            _user.isLimit = 0;
            _user.TradeLimit = SafeMath.sub(6000 * 10**18,used) ;
            _user.lever = 3;
        }
        if(_recordStorage.getAvailableTotal(addr,"AIR") >= 400000000 * 10**18){
            _user.isLimit = 0;
            _user.TradeLimit = SafeMath.sub(8000 * 10**18,used) ;
            _user.lever = 4;
        }
        if(_recordStorage.getAvailableTotal(addr,"AIR") >= 500000000 * 10**18){
			_user.TradeLimit = 9999999999999 * 10**18;
            _user.isLimit = 1 ;
            _user.lever = 5;
        }
        _user.userFlag = 3;
        if(_recordStorage.getAvailableTotal(addr,"AIR") == 0){
            _user.isLimit = 0;
            _user.TradeLimit = 0;
            _user.lever = 0;
            _user.userFlag = 0;
        }
		users[addr] = _user;
		userList[userIndex[addr]] = _user;
    }
	function _updateTradeStats(address _addr, TradeStats memory _tradeStats, uint _credit) internal {
		require(_addr != address(0), "UserStorage: _addr null is not allowed");
		require(users[_addr].userAddr != address(0), "UserStorage: current User not exist");
		User memory u = users[_addr];
		u.credit = _credit;
		u.tradeStats.tradeTotal = _tradeStats.tradeTotal;
		u.tradeStats.restTotal = _tradeStats.restTotal;
		users[_addr] = u;
		userList[userIndex[_addr]] = u;
	}
	function _updateMorgageStats(address _addr, MorgageStats memory _morgageStats) internal {
		require(_addr != address(0), "UserStorage: _addr null is not allowed");
		require(users[_addr].userAddr != address(0), "UserStorage: current User not exist");
		User memory u = users[_addr];
		u.morgageStats.mortgage = _morgageStats.mortgage;
		u.morgageStats.freezeMortgage = _morgageStats.freezeMortgage;
		u.morgageStats.relieveMortgage = _morgageStats.relieveMortgage;
		u.morgageStats.inviteUserCount = _morgageStats.inviteUserCount;
		u.morgageStats.inviteUserReward = _morgageStats.inviteUserReward;
		u.morgageStats.applyRelieveTime = _morgageStats.applyRelieveTime;
		u.morgageStats.handleRelieveTime = _morgageStats.handleRelieveTime;
		users[_addr] = u;
		userList[userIndex[_addr]] = u;
	}
    function _search(address _addr) internal view returns(User memory user) {
		require(_addr != address(0), "UserStorage: _addr null is not allowed");
		require(users[_addr].userAddr != address(0), "UserStorage: current User not exist");
		User memory a = users[_addr];
		return a;
	}
	function register() external {
		require(!isMemberOf(), 'has registed');
		_insert(msg.sender);
	}
	function registerOne(address one) external {
		require(!isMemberOfOne(one), 'has registed');
		_insert(one);
	}
    function isMemberOf() public view returns (bool) {
        return (users[msg.sender].userAddr != address(0));
    }
	function isMemberOfOne(address one) public view returns (bool) {
        return (users[one].userAddr != address(0));
    }
	function updateInfo(string memory _avatar, string memory _email, uint _isOnline) onlyMemberOf external {
		_updateInfo(msg.sender, _avatar, _email, _isOnline);
		emit updateUser(_avatar, _email, _isOnline);
	}
	function updateTradeStats(address _addr, TradeStats memory _tradeStats, uint _credit) onlyAuthFromAddr public {
	    require(msg.sender == _restCAddr || msg.sender == _orderCAddr || msg.sender == _appealCAddr || msg.sender == _recordCAddr, 'UserStorage:Invalid from contract address');
		_updateTradeStats(_addr, _tradeStats, _credit);
	}
	function updateMorgageStats(address _addr, MorgageStats memory _morgageStats) onlyAuthFromAddr public {
		require(msg.sender == _recordCAddr, 'UserStorage:Invalid from contract address');
		_updateMorgageStats(_addr, _morgageStats);
	}
	function updateUserRole(address _addr, uint _userFlag) onlyAuthFromAddr public {
	    require(msg.sender == _recordCAddr, 'UserStorage:Invalid from contract address');
	    require(_addr != address(0), "UserStorage: _addr null is not allowed");
		require(users[_addr].userAddr != address(0), "UserStorage: current User not exist");
		require(_userFlag<=3, 'UserStorage: Invalid userFlag 3');
		User memory u = users[_addr];
		u.userFlag = _userFlag;
	    users[_addr] = u;
		userList[userIndex[_addr]] = u;
	}
	function searchUser(address _addr) external view returns(User memory user) {
		return _search(_addr);
	}
	function searchUserList() external view returns(User[] memory) {
		return userList;
	}
}
