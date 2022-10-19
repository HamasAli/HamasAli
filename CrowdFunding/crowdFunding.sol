// SPDX-License-Identifier: MIT

pragma solidity >= 0.6.0 < 0.9.0;

contract crowdFunding{
    address public  manager;
    uint    public  minContribution;
    uint    public  raisedAmount;
    uint    public  totalAmountInTheContract;
    uint    public  numberOfContributers;
    uint    public  numberOfProposals;

    mapping(address => uint) public contributers;

    struct proposals{
        string  description;
        address payable sendTo;
        uint    amount;
        uint    numberOfVotes;
        uint    proposalTime;
        bool    fundReleased;
    }

    mapping(uint => mapping (address => bool)) vote;
    mapping(uint => proposals) public Proposal;
    proposals[] private _p;

    event Contribute(address indexed from, uint value);
    event Approve(address indexed to, uint value);

    constructor(){
        manager = msg.sender;
        minContribution = 0.001 ether;
    }

    modifier onlyManger(){
        require(msg.sender == manager, "You are not the manager.");
        _;
    }

    function contribute() public payable returns(bool){
        require(msg.value >= minContribution, "Sorry, your contribution is too low.");

        payable(address(this)).transfer(msg.value);
        raisedAmount += msg.value;
        totalAmountInTheContract += msg.value;

        if(contributers[msg.sender] == 0){
            numberOfContributers++;
        }
        contributers[msg.sender] += msg.value;
        
        emit Contribute(msg.sender, msg.value);
        return true;
    }

    receive () payable external{}

    function setAProposal(string memory _description, 
                          address payable _sendTo, 
                          uint _amount,
                          uint _proposalTime) public returns(bool){
        proposals storage newRequest = Proposal[numberOfProposals];
        numberOfProposals++;

        newRequest.description = _description;
        newRequest.sendTo      = _sendTo;
        newRequest.amount      = _amount;
        newRequest.numberOfVotes = 0;
        newRequest.proposalTime  = block.timestamp + (_proposalTime * 1 seconds);
        newRequest.fundReleased      = false;

        return true;
    }

    function Vote(uint _proposalNumber) public returns(bool){
        require(contributers[msg.sender] > 0, "You can't vote because you are not a Contributer.");

        proposals storage thisProposal = Proposal[_proposalNumber];

        require(vote[_proposalNumber][msg.sender] == false, "You have already voted.");
        require(block.timestamp < thisProposal.proposalTime, "Voting time has ended.");

        vote[_proposalNumber][msg.sender] = true;
        thisProposal.numberOfVotes++;

        return true;
    }

    function approve(uint _proposalNumber) public onlyManger returns(bool){
        proposals storage thisProposal = Proposal[_proposalNumber];

        require(totalAmountInTheContract >= thisProposal.amount, "The amount in the contract is lower then the asked amount.");
        require(block.timestamp > thisProposal.proposalTime, "The voting on this proposal is not ended.");
        require(thisProposal.numberOfVotes > (numberOfContributers / 2), "Majority doesn't support this proposal.");
        require(thisProposal.fundReleased == false, "This proposal's funds are already released.");

        thisProposal.sendTo.transfer(thisProposal.amount);
        thisProposal.fundReleased = true;
        totalAmountInTheContract -= thisProposal.amount;

        emit Approve(thisProposal.sendTo, thisProposal.amount);
        return true;
    }

    function allProposals() public view returns (proposals[] memory){

        proposals[] memory pa = new proposals[](numberOfProposals);
        
        for(uint i = 0; i < numberOfProposals; i++){
            proposals storage thProposal = Proposal[i];
            pa[i] = thProposal;
        }
        return pa;
    }
}

/*
            uint                                string                                                      uint
            1                               ASD@gmail.com                                                  1
                                                                                                           2
            2                               asdfa@fma;sd                                                   1 
*/