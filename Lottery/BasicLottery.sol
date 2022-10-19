// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract lottery{
    address     public  manager;
    address[]   public  participants;
    uint        public  price;
    uint        public  prizeMoney;
    uint        private minimumParticipants;

    constructor(uint _price, uint _prizeMoney, uint _mimimumParticipants) {
        manager             = msg.sender;
        price               = _price * 10 ** 18;
        prizeMoney          = _prizeMoney * 10 ** 18;
        minimumParticipants = _mimimumParticipants;
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
        require(participants.length > minimumParticipants, 
                "Number of current Participants are lower then minimum participants.");

        uint winningIndex = _randomNumber() % participants.length;

        payable(participants[winningIndex]).transfer(prizeMoney);
        payable(manager).transfer(_tokensLeftInContract());

        return participants[winningIndex];
    }

    function _randomNumber() private view returns(uint){
        return uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, participants.length)));
    }

    function _tokensLeftInContract() private view returns(uint){
        return address(this).balance;
    }
}