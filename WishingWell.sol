// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract WishingWell {
    address wwgAddr;
    // name of the lottery
    string public wishingWellName;
    // Creator of a wishing well contract
    address public manager;
    uint public serviceFee = 3;
    uint public transactionFee; //for the managers to set their fees

    constructor (string memory name, address creator) {
        wishingWellName = name;
        manager = creator;
        transactionFee = 0;
    }
    // variables for players
    struct Player {
        string name;
        uint entryCount;
        uint index;
    }

    function setTransactionFee(uint _amount) public onlyManager{
        require(_amount < 100);
        transactionFee = _amount;
    }
    address[] public addressIndexes;
    mapping(address => Player) players;
    address[] public lotteryBag;

    // Variables for lottery information
    Player public winner;
    bool public isWishingWellLive;
    uint public amountToParticipate;
    
    // Let users participate by sending eth directly to contract address
    fallback () external payable {
        // player name will be unknown
        participate("Unknown");
    }
    receive () external payable {
        // player name will be unknown
        participate("Unknown");
    }
    //read functioons
    function getWishingWellName() public view returns (string memory) {
        return wishingWellName;
    }
    function getIsWishingWellLive() public view returns (bool) {
        return isWishingWellLive;
    }
    function getAmountToParticipate() public view returns (uint) {
        return amountToParticipate;
    }
    function getPlayers() public view returns(address[] memory) {
        return addressIndexes;
    }

    function getPlayer(address playerAddress) public view returns (string memory, uint) {
        if (isNewPlayer(playerAddress)) {
            return ("", 0);
        }
        return (players[playerAddress].name, players[playerAddress].entryCount);
    }

    function getWinningPrice() public view returns (uint) {
        return address(this).balance;
    }

    //write functions
    function participate(string memory playerName) public payable {
        require(bytes(playerName).length > 0);
        require(isWishingWellLive);
        require(msg.value >= amountToParticipate * 1 ether);

        if (isNewPlayer(msg.sender)) {
            players[msg.sender].entryCount = 1;
            players[msg.sender].name = playerName;
        } else {
            players[msg.sender].entryCount += 1;
        }

        lotteryBag.push(msg.sender);
    
        // event
        emit PlayerParticipated(players[msg.sender].name, players[msg.sender].entryCount);
    }

    function activateLottery(uint _amountRequired) public onlyManager {
        require(_amountRequired > 0.001 ether);
        isWishingWellLive = true;
        amountToParticipate = _amountRequired;
    }

    function declareWinner() public onlyManager {
        require(lotteryBag.length > 0);
        require(address(this).balance > 0);

        uint index = generateRandomNumber() % lotteryBag.length;
        transferServiceFee();
        transferTransactionFee();
        payable(lotteryBag[index]).transfer(address(this).balance);
         
        winner.name = players[lotteryBag[index]].name;
        winner.entryCount = players[lotteryBag[index]].entryCount;

        // empty the lottery bag and indexAddresses
        lotteryBag = new address[](0);
        addressIndexes = new address[](0);

        // Mark the lottery inactive
        isWishingWellLive = false;
    
        // event
        emit WinnerDeclared(winner.name, winner.entryCount);
    }

    // Private functions
    function isNewPlayer(address playerAddress) private view returns(bool) {
        if (addressIndexes.length == 0) {
            return true;
        }
        return (addressIndexes[players[playerAddress].index] != playerAddress);
    }

    function generateRandomNumber() private view returns (uint) {
         uint256 seed = uint256(keccak256(abi.encodePacked(
        block.timestamp + block.difficulty +
        ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
        block.gaslimit + 
        ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) +
        block.number
    )));

    return (seed - ((seed / lotteryBag.length) * lotteryBag.length));
    }

    function transferServiceFee() private {
        payable(wwgAddr).transfer(address(this).balance * serviceFee/100);
    }
    function transferTransactionFee() private{
        payable(manager).transfer(address(this).balance * transactionFee/100);
    }

    // Modifiers
    modifier onlyManager() {
        require(msg.sender == manager);
        _;
    }

    // Events
    event WinnerDeclared( string name, uint entryCount );
    event PlayerParticipated( string name, uint entryCount );
}
