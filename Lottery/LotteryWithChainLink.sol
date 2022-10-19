// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract lottery is VRFConsumerBaseV2{

    address     public  manager;
    address[]   public  participants;
    uint        public  price;
    uint        public  prizeMoney;
    uint        private minimumParticipants;

    VRFCoordinatorV2Interface COORDINATOR;
    
    address vrfCoordinator = 0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D;
    bytes32 keyHash        = 0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15;

    uint32           callbackGasLimit     = 2500000;
    uint16           requestConfirmations = 3;
    uint32           numWords             = 500;
    uint64           s_subscriptionId;
    address          s_owner;
    uint256          s_requestId;
    uint256[] public s_randomWords;

    constructor(uint _price, uint _prizeMoney, uint _mimimumParticipants, uint64 subscriptionId) VRFConsumerBaseV2(vrfCoordinator) {
        manager             = msg.sender;
        price               = _price;
        prizeMoney          = _prizeMoney;
        minimumParticipants = _mimimumParticipants;

        COORDINATOR      = VRFCoordinatorV2Interface(vrfCoordinator);
        s_subscriptionId = subscriptionId;
        s_owner          = msg.sender;
    }

    modifier onlyManger(){
        require(msg.sender == manager, "You are not the manager of the lottery.");
        _;
    }

    function getAllParticipents() public view returns(address[] memory){
        return participants;
    }

    receive() external payable{}

    function participate() public payable returns(bool){
        require(msg.value == price, "The amount you are trying to send is not equal to the price.");

        payable(address(this)).transfer(msg.value);
        participants.push(msg.sender);

        return true;
    }

    function luckyDraw() public payable onlyManger returns(address){
        require(participants.length >= minimumParticipants, 
                "Number of current Participants are lower then minimum participants.");

        uint winningIndex = s_requestId % participants.length;

        payable(participants[winningIndex]).transfer(prizeMoney);
        payable(manager).transfer(address(this).balance);

        return participants[winningIndex];
    }

    function requestRandomWords() external onlyManger{
        s_requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
    }

    function fulfillRandomWords(
    uint256, /* requestId */
    uint256[] memory randomWords
    ) internal override {
        s_randomWords = randomWords;
    }

    function retur() public payable onlyManger {
      payable(manager).transfer(address(this).balance);
    }
}