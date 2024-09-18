// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./RecordStorage.sol";
import "./OrderStorage.sol";
import "./RecordInterface.sol";
import "./UserStorage.sol";
import "./AppealStorage.sol";

abstract contract ReentrancyGuardInvite {
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

library CountersInvite {
    struct Counter {
        uint256 _value;
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        if (counter._value == 0) {
            counter._value = 10000;
        }
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        counter._value = value - 1;
    }
}

contract InvitationStorage is Ownable, ReentrancyGuardInvite {
    using CountersInvite for CountersInvite.Counter;

    CountersInvite.Counter private _inviteNoCounter;

    RecordInterface private _recordStorage;
    UserInterface private _userStorage;
    OrderInterface private _orderStorage;

    address recordAddress;
    address _userAddr;
    address _orderAddr;

    uint256 public TradeRewardCount = 1 * 10**17; 
    uint256 public withdrawalFee = 5 * 10**17;
    uint256 public ContractBalance;
    mapping(address => address) public inviterOf;
    mapping(address => uint256) public userBalances;
    mapping(address => uint256) public TotaluserReward;
    mapping(address => bool) public isInvited;
    mapping(address => address[]) private _invitedUsers;

    struct WithdrawalRecord {
        uint256 amount;
        uint256 timestamp;
    }

    mapping(address => WithdrawalRecord[]) private _withdrawalRecords;

    event Invite(address indexed inviter, address indexed invitee);
    event TradeReward(address indexed trader);
    event Withdraw(address indexed user, uint256 amount, uint256 fee);

    function authFromContract(
        address _FormUser,
        address _FormRecord,
        address _ForomOrder
    ) external onlyOwner {
        _userAddr = _FormUser;
        _orderAddr = _ForomOrder;
        _userStorage = UserInterface(_FormUser);
        _recordStorage = RecordInterface(_FormRecord);
        _inviteNoCounter.increment();
    }

    function invite(address _inviter) public {
        verifyInvitationLink(_inviter, msg.sender);
        _userStorage.registerOne(msg.sender);
        require(_userStorage.isMemberOfOne(msg.sender) == true, "regist err");

        inviterOf[msg.sender] = _inviter;
        isInvited[msg.sender] = true;
        _invitedUsers[_inviter].push(msg.sender); 

        emit Invite(_inviter, msg.sender);
    }

    function RewardInvite(address _trader) public {
   
        require(msg.sender == _orderAddr, "Call Addr err");
        address inviter = inviterOf[_trader];
        if (inviter != address(0)) {
            uint256 totalreward = TradeRewardCount * 2;
            userBalances[_trader] = SafeMath.add(userBalances[_trader], TradeRewardCount);
            userBalances[inviter] = SafeMath.add(userBalances[inviter], TradeRewardCount);
            ContractBalance = SafeMath.sub(ContractBalance, totalreward);
            TotaluserReward[_trader] = SafeMath.add(userBalances[_trader], TradeRewardCount);
            TotaluserReward[inviter] = SafeMath.add(userBalances[inviter], TradeRewardCount);
        }

        emit TradeReward(_trader);
    }

    function withdraw(uint256 _amount) public {
        require(userBalances[msg.sender] >= _amount, "Insufficient balance for withdrawal.");
        require(_amount >= 1 * 10**18, "Withdrawal amount must be more than 1 USDT.");
        
        TokenTransfer _tokenTransfer = _recordStorage.getERC20Address("USDT");
        require(ContractBalance >= _amount, "Insufficient balance for trade reward.");
        uint256 realAmount = SafeMath.sub(_amount, withdrawalFee);
        _tokenTransfer.transfer(msg.sender, realAmount);

        ContractBalance = SafeMath.sub(ContractBalance, realAmount);
        userBalances[msg.sender] = SafeMath.sub(userBalances[msg.sender], _amount);
        _withdrawalRecords[msg.sender].push(WithdrawalRecord({
            amount: _amount,
            timestamp: block.timestamp
        }));

        emit Withdraw(msg.sender, _amount, withdrawalFee);
    }

    function verifyInvitationLink(address _inviter, address _invitee) internal view returns (bool) {
        require(_inviter != address(0));
        require(_invitee != address(0));
        require(_inviter != _invitee, "can't invite self");
        require(_userStorage.isMemberOfOne(_invitee) == false, "already User");
        require(!isInvited[_invitee], "one already invited.");
        return true;
    }

    function fundContract(uint256 amount) public onlyOwner {
        TokenTransfer _tokenTransfer = _recordStorage.getERC20Address("USDT");
        _tokenTransfer.transferFrom(msg.sender, address(this), amount);
        ContractBalance = SafeMath.add(amount, ContractBalance);
    }

    function withdrawBalance(uint256 amount) public onlyOwner {
        TokenTransfer _tokenTransfer = _recordStorage.getERC20Address("USDT");
        uint256 balance = _tokenTransfer.balanceOf(msg.sender);
        require(balance > amount, "balance err");
        _tokenTransfer.transfer(msg.sender, amount);
        ContractBalance = SafeMath.sub(ContractBalance, amount);
    }

    function getInvitedUsers(address _inviter) public view returns (address[] memory, uint256) {
        return (_invitedUsers[_inviter], _invitedUsers[_inviter].length);
    }

    function getWithdrawalRecords(address _user) public view returns (WithdrawalRecord[] memory) {
        return _withdrawalRecords[_user];
    }
}
