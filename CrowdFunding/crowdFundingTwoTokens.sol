// SPDX-License-Identifier: MIT

pragma solidity >= 0.6.0 < 0.9.0;

interface Token {
    function transfer(address to, uint tokens) external returns (bool success);

    function transferFrom(address from, address to, uint tokens) external returns (bool success);
}

contract crowdFunding{
    address public  manager;
    uint    public  minContribution;
    uint    public  raisedBUSD;
    uint    public  raisedCAKE;
    uint    public  totalBUSDInTheContract;
    uint    public  totalCAKEInTheContract;
    uint    public  numberOfContributers;
    uint    public  numberOfProposals;
    proposals[] arr;

    mapping(address => uint) public BUSDContributers;
    mapping(address => uint) public CAKEContributers;

    struct proposals{
        string  description;
        address sendTo;
        uint    amount;
        uint    tokenKey;
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

    Token busd = Token(0x8516Fc284AEEaa0374E66037BD2309349FF728eA);
    Token cake = Token(0xFa60D973F7642B748046464e165A65B7323b0DEE);

    modifier onlyManger(){
        require(msg.sender == manager, "You are not the manager.");
        _;
    }

    function contribute(uint _key, uint _value) public returns(bool){
        require(_value >= minContribution, "Sorry, your contribution is too low.");
        
        if(BUSDContributers[msg.sender] == 0 && CAKEContributers[msg.sender] == 0){
                numberOfContributers++;
        }

        if(_key == 0){
            busd.transferFrom(msg.sender, address(this), _value);
            raisedBUSD += _value;
            totalBUSDInTheContract += _value;

            BUSDContributers[msg.sender] += _value;
            
            emit Contribute(msg.sender, _value);
            return true;
        }
        else if(_key == 1){
            cake.transferFrom(msg.sender, address(this), _value);
            raisedCAKE += _value;
            totalCAKEInTheContract += _value;

            CAKEContributers[msg.sender] += _value;
            
            emit Contribute(msg.sender, _value);
            return true;
        }
        else{
            return false;
        }
        
    }

    function setAProposal(string memory _description, 
                          address _sendTo, 
                          uint _amount,
                          uint _proposalTime,
                          uint _tokenKey) public returns(bool){
        require(_tokenKey == 0 || _tokenKey == 1, "The token key is not right.");
        proposals storage newRequest = Proposal[numberOfProposals];
        numberOfProposals++;

        newRequest.description = _description;
        newRequest.sendTo      = _sendTo;
        newRequest.amount      = _amount;
        newRequest.tokenKey    = _tokenKey;
        newRequest.numberOfVotes = 0;
        newRequest.proposalTime  = block.timestamp + (_proposalTime * 1 seconds);
        newRequest.fundReleased  = false;

        return true;
    }

    function Vote(uint _proposalNumber) public returns(bool){
        require(BUSDContributers[msg.sender] > 0 || CAKEContributers[msg.sender] > 0, 
                "You can't vote because you are not a Contributer.");

        proposals storage thisProposal = Proposal[_proposalNumber];

        require(vote[_proposalNumber][msg.sender] == false, "You have already voted.");
        require(block.timestamp < thisProposal.proposalTime, "Voting time has ended.");

        vote[_proposalNumber][msg.sender] = true;
        thisProposal.numberOfVotes++;

        return true;
    }

    function approve(uint _proposalNumber) public onlyManger returns(bool){
        proposals storage thisProposal = Proposal[_proposalNumber];

        if(thisProposal.tokenKey == 0){
            require(totalBUSDInTheContract >= thisProposal.amount, 
                    "The amount in the contract is lower then the asked amount.");
            require(block.timestamp > thisProposal.proposalTime, 
                    "The voting on this proposal is not ended.");
            require(thisProposal.numberOfVotes > (numberOfContributers / 2), 
                    "Majority doesn't support this proposal.");
            require(thisProposal.fundReleased == false, 
                    "This proposal's funds are already released.");

            busd.transfer(thisProposal.sendTo, thisProposal.amount);

            thisProposal.fundReleased = true;
            totalBUSDInTheContract -= thisProposal.amount;

            emit Approve(thisProposal.sendTo, thisProposal.amount);
            return true;
        }
        else if(thisProposal.tokenKey == 1){
            require(totalCAKEInTheContract >= thisProposal.amount, 
                    "The amount in the contract is lower then the asked amount.");
            require(block.timestamp > thisProposal.proposalTime, 
                    "The voting on this proposal is not ended.");
            require(thisProposal.numberOfVotes > (numberOfContributers / 2), 
                    "Majority doesn't support this proposal.");
            require(thisProposal.fundReleased == false, 
                    "This proposal's funds are already released.");

            cake.transfer(thisProposal.sendTo, thisProposal.amount);

            thisProposal.fundReleased = true;
            totalCAKEInTheContract -= thisProposal.amount;

            emit Approve(thisProposal.sendTo, thisProposal.amount);
            return true;
        }
        else{
            return false;
        }

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