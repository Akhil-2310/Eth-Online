// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DelegatedDAO {
    address public manager; // The address of the DAO manager.
    uint public totalShares; // Total shares issued by the DAO.
    uint public proposalCount; // Number of proposals submitted.

    struct Member {
        bool isMember;
        uint shares;
        uint delegateWeight;
        address delegate;
    }

    struct Proposal {
        address creator;
        string description;
        uint votesFor;
        uint votesAgainst;
        bool passed;
        bool executed;
        mapping(address => bool) voted;
    }

    mapping(address => Member) public members;
    mapping(uint => Proposal) public proposals;

    constructor() {
        manager = msg.sender;
    }

    modifier onlyMember() {
        require(members[msg.sender].isMember, "Only members can call this function");
        _;
    }

    function addMember(address _member, uint _shares) public {
        require(msg.sender == manager, "Only the manager can add members");
        require(!members[_member].isMember, "Member already exists");
        members[_member] = Member(true, _shares, 0, address(0));
        totalShares += _shares;
    }

    function delegateVotingPower(address _delegate) public onlyMember {
        require(_delegate != msg.sender, "You cannot delegate to yourself");
        require(members[_delegate].isMember, "Invalid delegate address");

        Member storage sender = members[msg.sender];
        Member storage delegate = members[_delegate];

        sender.delegate = _delegate;

        if (delegate.delegate == msg.sender) {
            // Remove delegate's current delegateWeight if they have already delegated
            delegate.delegateWeight -= sender.shares;
        } else {
            // First time delegation
            sender.delegateWeight += sender.shares;
        }
    }

    function vote(uint _proposalId, bool _support) public onlyMember {
        require(_proposalId <= proposalCount, "Invalid proposal ID");

        Member storage sender = members[msg.sender];
        require(sender.delegate != address(0), "You must delegate your voting power first");

        Proposal storage proposal = proposals[_proposalId];

        require(!proposal.voted[msg.sender], "Member has already voted");

        // Update the voted flag to prevent multiple votes by the same member
        proposal.voted[msg.sender] = true;

        Member storage delegate = members[sender.delegate];

        if (_support) {
            proposal.votesFor += sender.delegateWeight;
        } else {
            proposal.votesAgainst += sender.delegateWeight;
        }
    }

    function executeProposal(uint _proposalId) public {
        require(_proposalId <= proposalCount, "Invalid proposal ID");
        Proposal storage proposal = proposals[_proposalId];
        require(!proposal.executed, "Proposal has already been executed");
        require(!proposal.passed, "Proposal has not passed");

        if (proposal.votesFor > proposal.votesAgainst) {
            proposal.passed = true;

            // Implement the action to be executed if the proposal passes here.
            // You'll need to define the specific action details in your use case.

            proposal.executed = true;
        }
    }
}
