// SPDX-License-Identifier: MIT

pragma solidity >= 0.6.0 < 0.9.0;

interface Token {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function transfer(address to, uint tokens) external returns (bool success);
    
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract crowdFunding{
    address public  manager;
    uint    public  minContribution;
    uint    public  raisedAmount;
    uint    public  totalAmountInTheContract;
    uint    public  numberOfContributers;
    uint    public  numberOfProposals;
    proposals[] arr;

    mapping(address => uint) public contributers;

    struct proposals{
        string  description;
        address sendTo;
        uint    amount;
        uint    numberOfVotes;
        uint    proposalTime;
        bool    fundReleased;
    }

    mapping(uint => mapping (address => bool)) vote;

    mapping(uint => proposals) public Proposal;
    mapping(address => bool)   private _approval;

    event Contribute(address indexed from, uint value);
    event Approve(address indexed to, uint value);

    constructor(){
        manager = msg.sender;
        minContribution = 10;
    }

    Token obj = Token(0xd9145CCE52D386f254917e481eB44e9943F39138);

    modifier onlyManger(){
        require(msg.sender == manager, "You are not the manager.");
        _;
    }

    function contribute(uint _value) public returns(bool){
        require(_value >= minContribution, "Sorry, your contribution is too low.");

        //_approval[msg.sender] = true;
        obj.transferFrom(msg.sender, address(this), _value);
        raisedAmount += _value;
        totalAmountInTheContract += _value;

        if(contributers[msg.sender] == 0){
            numberOfContributers++;
        }
        contributers[msg.sender] += _value;
        
        emit Contribute(msg.sender, _value);
        return true;
    }

    function setAProposal(string memory _description, 
                          address _sendTo, 
                          uint _amount,
                          uint _proposalTime) public returns(bool){
        proposals storage newRequest = Proposal[numberOfProposals];
        numberOfProposals++;

        newRequest.description = _description;
        newRequest.sendTo      = _sendTo;
        newRequest.amount      = _amount;
        newRequest.numberOfVotes = 0;
        newRequest.proposalTime  = block.timestamp + (_proposalTime * 1 seconds);
        newRequest.fundReleased  = false;

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

        obj.transfer(thisProposal.sendTo, thisProposal.amount);

        thisProposal.fundReleased = true;
        totalAmountInTheContract -= thisProposal.amount;

        emit Approve(thisProposal.sendTo, thisProposal.amount);
        return true;
    }

    function allProposals() public view returns (proposals[] memory){

        proposals[] memory thisProposalArray = new proposals[](numberOfProposals);
        
        for(uint i = 0; i < numberOfProposals; i++){
            proposals storage thisProposal = Proposal[i];
            thisProposalArray[i] = thisProposal;
        }

        return thisProposalArray;
    }
}