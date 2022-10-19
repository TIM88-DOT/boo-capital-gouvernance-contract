// SPDX-License-Identifier: GPL-3.0
import "@openzeppelin/contracts/access/Ownable.sol";

pragma solidity ^0.8.13;

interface IBooCapitalNFT {
    function ownerOf(uint256) external returns (address);

    function walletOfOwner(address) external view returns (uint256[] memory);
}

interface IBooCapitalToken {
    function balanceOf(address _user) external view returns (uint256);
}

contract BooCapitalVotes is Ownable {
    struct Contest {
        Contender[] contenders;
        bool isRunning;
    }
    struct Contender {
        address tokenAddress;
        uint32 votes;
    }

    uint256 public count;

    mapping(uint256 => Contest) public contests;
    mapping(uint256 => uint256[]) public contestUsedNFTs;
    mapping(uint256 => mapping(address => bool)) contestVoters;

    IBooCapitalNFT booCapitalNFT;
    IBooCapitalToken booCapitalToken;

    constructor(address _NFTaddress, address _tokenAddress) {
        booCapitalNFT = IBooCapitalNFT(_NFTaddress);
        booCapitalToken = IBooCapitalToken(_tokenAddress);
    }

    function startContest(address _firstContenderAddress) public onlyOwner {
        require(
            contests[count].isRunning == false,
            "Current contest still running !"
        );
        count += 1;
        Contest storage contest = contests[count];
        Contender memory newContender = Contender({
            tokenAddress: _firstContenderAddress,
            votes: 0
        });
        contest.isRunning = true;
        contest.contenders.push(newContender);
    }

    function addContender(address _tokenAddress) public onlyOwner {
        Contest storage contest = contests[count];
        require(contest.isRunning == true, "Contest hasn't started yet");
        require(contest.contenders.length < 4, "Max contenders amount reached");
        Contender memory newContender = Contender({
            tokenAddress: _tokenAddress,
            votes: 0
        });
        contest.contenders.push(newContender);
    }

    function vote(uint256 _contenderId, uint256[] memory _userNfts) public {
        Contest storage contest = contests[count];
        uint256 votingPower;
        require(
            booCapitalToken.balanceOf(msg.sender) > 100000000000000,
            "Insufficant token balance"
        );
        require(
            checkIfNftHasVoted(_userNfts) == false,
            "NFT(s) already voted with"
        );
        require(contest.isRunning == true, "Contest is over");
        require(
            _userNfts.length > 0 || contestVoters[count][msg.sender] == false,
            "Can't vote with 0 voting power"
        );

        if (contestVoters[count][msg.sender] == false) {
            votingPower = 1;
            contestVoters[count][msg.sender] = true;
        }
        for (uint256 i = 0; i < _userNfts.length; i++) {
            require(
                booCapitalNFT.ownerOf(_userNfts[i]) == msg.sender,
                "You are not owner of the NFT(s) selected"
            );
            contestUsedNFTs[count].push(_userNfts[i]);
            votingPower++;
        }
        contest.contenders[_contenderId].votes += uint32(votingPower);
    }

    function endContest() public onlyOwner {
        Contest storage contest = contests[count];
        contest.isRunning = false;
    }

    function getAllContests() public view returns (Contest[] memory) {
        Contest[] memory allContestsArray = new Contest[](count + 1);
        for (uint256 i = 1; i < count + 1; i++) {
            allContestsArray[i] = contests[i];
        }
        return allContestsArray;
    }

    function getCurrentContest() public view returns (Contest memory) {
        Contest storage currentContest = contests[count];
        return currentContest;
    }

    function getContest(uint256 _id) public view returns (Contest memory) {
        Contest memory contest = contests[_id];
        return contest;
    }

    // DANGER : only call this when you're sure about the contest you're willing to clear
    function deleteContest(uint256 _id) public onlyOwner {
        delete contests[_id];
    }

    function walletOfNFTOwner(address user)
        internal
        view
        returns (uint256[] memory)
    {
        uint256[] memory id = booCapitalNFT.walletOfOwner(user);
        return id;
    }

    function checkIfNftHasVoted(uint256[] memory _userNfts)
        public
        view
        returns (bool)
    {
        uint256[] memory userNFTsUsed = contestUsedNFTs[count];
        bool result;
        for (uint256 ii = 0; ii < _userNfts.length; ii++) {
            for (uint256 jj = 0; jj < userNFTsUsed.length; jj++) {
                if (_userNfts[ii] == userNFTsUsed[jj]) {
                    result = true;
                    break;
                } else {
                    if (jj == userNFTsUsed.length) {
                        result = false;
                        continue;
                    }
                }
            }
        }
        return result;
    }
}
