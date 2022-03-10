// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
import "./WishingWell.sol";

contract WishingWellFactory {
    address[] public wishingWells;
    uint _creatorFee = 0 ether; //fee to create a wishing well

    address public admin;
    struct wishingWell{
        uint index;
        address manager;
    }
    mapping(address => wishingWell) wishingWellStructs;
    event WishingWellCreated(address newWishingWell);
    
    constructor() {
        admin = msg.sender;
    }

    function createWishingWell(string memory name, uint value) public payable{
        assert(bytes(name).length > 0);
        require(value >= _creatorFee);
        WishingWell newWishingWell = new WishingWell(name, msg.sender);
        wishingWells.push(address(newWishingWell));
        uint index = wishingWells.length;
        wishingWellStructs[address(newWishingWell)].index = index;
        wishingWellStructs[address(newWishingWell)].manager = msg.sender;

        // event
        emit WishingWellCreated(address(newWishingWell));
    }

    function getWishingWells() public view returns(address[] memory) {
        return wishingWells;
    }
   
    function deleteWishingWell(address lotteryAddress) public{
        require(msg.sender == wishingWellStructs[lotteryAddress].manager);
        uint indexToDelete = wishingWellStructs[lotteryAddress].index;
        address lastAddress = wishingWells[wishingWells.length - 1];
        wishingWells[indexToDelete] = lastAddress;
        wishingWells.pop();
        
    }
    function kill() public onlyAdmin {
        selfdestruct(payable(admin));
    }
    function withdraw() public onlyAdmin {
        payable(admin).transfer(address(this).balance);
    }
    modifier onlyAdmin() {
    require(msg.sender == admin);
    _;
    }

    // Events
    event LotteryCreated(
        address lotteryAddress
    );
}
