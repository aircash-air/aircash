// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./UserStorage.sol";
contract tool{
    UserStorage private us;
    function init(address addr)public{
        us = UserStorage(addr);
        // UserStorage us = UserStorage(0x148f5542b9be744bbD423ceaDd7723E65c4C673B);
    }
   

    function getUsersLever(address[] memory addr) public view returns(uint[] memory uintP ){
        uintP = new uint[](addr.length);
        for(uint i;i<addr.length;i++){
           uintP[i] =  us.searchUser(addr[i]).lever;
        }

    }


}