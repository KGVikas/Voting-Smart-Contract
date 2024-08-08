// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract Vote {
    // First Entity
    struct Voter {
        string name;
        uint256 age;
        uint256 voterId;
        Gender gender;
        uint256 voteCandidateId;
        address voterAddress;
    }

    // Second Entity
    struct Candidate {
        string name;
        string party;
        uint256 age;
        Gender gender;
        uint256 candidateId;
        address candidateAddress;
        uint256 votes;
    }

    // Third Entity
    address public electionCommission;
    address public winner;
    uint256 public nextVoterId = 1;
    uint256 public nextCandidateId = 1;
    uint256 public startTime;
    uint256 public endTime;
    bool public stopVoting;

    mapping(uint256 => Voter) public voterDetails;
    mapping(uint256 => Candidate) public candidateDetails;
    mapping(address => bool) public isRegisteredVoter;
    mapping(address => bool) public isRegisteredCandidate;

    enum VotingStatus {
        NotStarted,
        InProgress,
        Ended
    }

    enum Gender {
        NotSpecified,
        Male,
        Female,
        Other
    }

    event CandidateRegistered(string name, string party, uint256 age, Gender gender, uint256 candidateId, address candidateAddress);
    event VoterRegistered(string name, uint256 age, Gender gender, uint256 voterId, address voterAddress);
    event VoteCast(uint256 voterId, uint256 candidateId);
    event VotingPeriodSet(uint256 startTime, uint256 endTime);
    event VotingResultAnnounced(address winner);
    event VotingEmergencyStopped();

    constructor() {
        electionCommission = msg.sender;
    }

    modifier isVotingOver() {
        require(block.timestamp <= endTime && !stopVoting, "Voting time is Over");
        _;
    }

    modifier above18(uint256 age) {
        require(age >= 18, "You are below 18");
        _;
    }

    modifier onlyCommissioner() {
        require(msg.sender == electionCommission, "You are not authorized");
        _;
    }

    function registerCandidate(
        string calldata _name,
        string calldata _party,
        uint256 _age,
        Gender _gender
    ) external above18(_age) {
        require(!isRegisteredCandidate[msg.sender], "You have already registered");
        require(nextCandidateId < 3, "Candidate registration full");
        require(msg.sender != electionCommission, "Election Commission not allowed to register");

        candidateDetails[nextCandidateId] = Candidate({
            name: _name,
            party: _party,
            age: _age,
            gender: _gender,
            candidateId: nextCandidateId,
            candidateAddress: msg.sender,
            votes: 0
        });
        isRegisteredCandidate[msg.sender] = true;
        emit CandidateRegistered(_name, _party, _age, _gender, nextCandidateId, msg.sender);
        nextCandidateId++;
    }

    function getCandidateList() public view returns (Candidate[] memory) {
        Candidate[] memory candidates = new Candidate[](nextCandidateId - 1);
        for (uint256 i = 0; i < candidates.length; i++) {
            candidates[i] = candidateDetails[i + 1];
        }
        return candidates;
    }

    function registerVoter(
        string calldata _name,
        uint256 _age,
        Gender _gender
    ) external above18(_age) {
        require(!isRegisteredVoter[msg.sender], "You have already registered");

        voterDetails[nextVoterId] = Voter({
            name: _name,
            age: _age,
            voterId: nextVoterId,
            gender: _gender,
            voteCandidateId: 0,
            voterAddress: msg.sender
        });
        isRegisteredVoter[msg.sender] = true;
        emit VoterRegistered(_name, _age, _gender, nextVoterId, msg.sender);
        nextVoterId++;
    }

    function getVoterList() public view returns (Voter[] memory) {
        Voter[] memory voters = new Voter[](nextVoterId - 1);
        for (uint256 i = 0; i < voters.length; i++) {
            voters[i] = voterDetails[i + 1];
        }
        return voters;
    }

    function castVote(uint256 _voterId, uint256 _candidateId) external isVotingOver() {
        require(block.timestamp>=startTime,"The voting has not yet started");
        require(_voterId > 0 && _voterId < nextVoterId, "Invalid Voter ID");
        require(voterDetails[_voterId].voterAddress == msg.sender, "You are not authorized");
        require(voterDetails[_voterId].voteCandidateId == 0, "You have already voted");
        require(_candidateId > 0 && _candidateId < nextCandidateId, "Invalid Candidate ID");

        voterDetails[_voterId].voteCandidateId = _candidateId;
        candidateDetails[_candidateId].votes += 1;
        emit VoteCast(_voterId, _candidateId);
    }

    function setVotingPeriod(uint256 _startTime, uint256 _endTime) external onlyCommissioner {
        require(_startTime < _endTime, "Invalid time period");
        startTime = block.timestamp + _startTime;
        endTime = startTime + _endTime;
        emit VotingPeriodSet(startTime, endTime);
    }

    function getVotingStatus() public view returns (VotingStatus) {
        if (startTime == 0) {
            return VotingStatus.NotStarted;
        } else if (block.timestamp < endTime && !stopVoting) {
            return VotingStatus.InProgress;
        } else {
            return VotingStatus.Ended;
        }
    }

    function announceVotingResult() external onlyCommissioner {
        uint256 maxVotes = 0;
        address winningCandidate;

        for (uint256 i = 1; i < nextCandidateId; i++) {
            if (candidateDetails[i].votes > maxVotes) {
                maxVotes = candidateDetails[i].votes;
                winningCandidate = candidateDetails[i].candidateAddress;
            }
        }

        winner = winningCandidate;
        emit VotingResultAnnounced(winner);
    }

    function emergencyStopVoting() external onlyCommissioner {
        stopVoting = true;
        emit VotingEmergencyStopped();
    }
}
