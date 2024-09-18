// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./RestStorage.sol";
import "./OrderStorage.sol";
import "./UserStorage.sol";
import "./RecordStorage.sol";
import "./AppealStorage.sol";

interface RecordInterface {
    function getErcBalance(string memory _coinType, address _addr)
        external
        returns (uint256);
    function getAvailableTotal(address _addr, string memory _coinType)
        external
        returns (uint256);
    function getFrozenTotal(address _addr, string memory _coinType)
        external
        returns (uint256);
    function addAvailableTotal(
        address _addr,
        string memory _coinType,
        uint256 remainHoldCoin
    ) external;
    function subAvaAppeal(
        AppealStorage.Appeal memory _al,
        uint256 _type

    ) external;
    function subWitnessAvailable(address _addr) external;
    function getERC20Address(string memory _coinType)
        external
        returns (TokenTransfer);
    function getCoinTypeMapping(string memory _coinType) external returns (address);
    function subFrozenTotal(uint256 _orderNo, address _addr) external;
    function backDiya(uint256 _No,uint256 _am,uint256 _type) external;
    function addRecord(
        address _addr,
        string memory _tradeHash,
        string memory _coinType,
        uint256 _hostCount,
        uint256 _hostStatus,
        uint256 _hostType,
        uint256 _hostDirection
    ) external;
    function getWitnessHandleReward() external view returns (uint256);
    function getObserverHandleReward() external view returns (uint256);
    function getWitnessHandleCredit() external view returns (uint256);
    function getObserverHandleCredit() external view returns (uint256);
    function getSubWitCredit() external view returns (uint256);
    function getTradeCredit() external view returns (uint256);
    function getSubTCredit() external view returns (uint256);
    function getSubWitFee() external view returns (uint256);
    function done(string memory _coinType,uint256 _amt,address addr) external;
    function takeReward(uint256 _orderNo,address taker) external;
}
interface RestInterface {
    function searchRest(uint256 _restNo)
        external
        returns (RestStorage.Rest memory rest);
    function getRestFrozenTotal(address _addr, uint256 _restNo)
        external
        returns (uint256);
    function updateRestFinishCount(uint256 _restNo, uint256 _coinCount)
        external
        returns (uint256);
    function addRestRemainCount(uint256 _restNo, uint256 _remainCount)
        external
        returns (uint256);
    function getDy(uint256 restNo, string memory coinType, address user) external view returns (uint256);
    function zeroDiya(uint256 restNo, string memory CoinType, address user) external;
    function subDiya(uint256 restNo, string memory CoinType, address user,uint256 _amt) external;
    function getLatestRestNo(address userAddr) external view returns (uint256);
}
interface OrderInterface {
    function searchOrder(uint256 _orderNo)
        external
        returns (OrderStorage.Order memory order);
    function getDy(uint256 orderNo, string memory coinType, address user) external view returns (uint256);
   function zeroDiya(uint256 orderNo, string memory CoinType, address user) external;
   function updateOrderStatus(uint256 _orderNo, uint256 _orderStatus) external;
   
}
interface UserInterface {
    function searchUser(address _addr)
        external
        view
        returns (UserStorage.User memory user);
    function searchWitnessList(uint256 _userFlag)
        external
        returns (UserStorage.User[] memory userList);
    function updateTradeStats(
        address _addr,
        UserStorage.TradeStats memory _tradeStats,
        uint256 _credit
    ) external;
    function updateMorgageStats(
        address _addr,
        UserStorage.MorgageStats memory _morgageStats
    ) external;
    function updateUserRole(address _addr, uint256 _userFlag) external;
    function isMemberOfOne(address one) external view returns (bool);
    function registerOne(address one) external;
    function updateMerLever(address addr) external;
    function updateTradeLimit(address _addr, uint256 _changeAmount, uint flag) external;
    function zeroMerLever(address addr) external;
}
interface AppealInterface {
    function searchAppeal(uint256 _o)
        external
        view
        returns (AppealStorage.Appeal memory appeal);
    function zeroReward(uint256 _no) external ;
}
interface InviteInterface {
   function RewardInvite(address _trader) external;
}
interface IPancakeRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}
