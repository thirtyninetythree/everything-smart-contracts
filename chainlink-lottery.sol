// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract Lottery is VRFConsumerBase {
    
    bytes32 internal keyHash;
    uint256 internal fee;
    uint256 public linkBalance;
    string public name;

    uint256 public randomResult;
    address public manager;
    address[] public players;
    uint public fees;
    uint public winnings;
    address public lotteryWinner;
    event Winner(address winner);

      constructor(address vrfCoordinator, 
      address link, bytes32 keyHash, uint256 fee, string memory name) 
      VRFConsumerBase(
               vrfCoordinator, // VRF Coordinator
                link  // LINK Token
            )
        {
        keyHash = keyHash;
        fee = fee; // 0.1 LINK (Varies by network){
        name = name;
        manager = msg.sender;
      }
      
    
      function enter() public payable {
        require(msg.value > .01 ether);
    
        players.push(msg.sender);
      }
        
        function getRandomNumber() private returns (bytes32 requestId) {
            require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
            return requestRandomness(keyHash, fee);
        }
    
        /**
         * Callback function used by VRF Coordinator
         */
        function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
            randomResult = randomness;
            _pickWinner();
        }
        function pickWinner() public onlyOwner {
            getRandomNumber();
        }
    
      function _pickWinner() private onlyOwner {
        uint index = randomResult % players.length;
        winnings = address(this).balance*997/1000;
        payable(players[index]).transfer(winnings);
        
        fees = address(this).balance;
        
        lotteryWinner = players[index];
    
        players = new address[](0);
        emit Winner(lotteryWinner);
      }
      
      function withdrawTo(address _to) public onlyOwner {
        payable(_to).transfer(address(this).balance);
      }
      function LINKBalance() public onlyOwner {
           linkBalance = LINK.balanceOf(address(this));
      }
      function withdrawLink(address _to) public onlyOwner {
         LINK.transfer(_to, LINK.balanceOf(address(this)));
      }
    
      function getPlayers() public view returns (address[] memory) {
        return players;
      }
      
      function kill() onlyOwner public{
            selfdestruct(payable(manager));
        }
    
      modifier onlyOwner() {
        require(msg.sender == manager);
        _;
      }
    }
