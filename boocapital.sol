// SPDX-License-Identifier: GPL-3.0
import "@openzeppelin/contracts/access/Ownable.sol";

pragma solidity ^0.8.13;

interface IBooCapitalNFT {
    function ownerOf(uint256) external returns (address);

    function walletOfOwner(address) external view returns (uint256[] memory);
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
    mapping(uint256 => mapping(address => uint256[]))
        public userNFTsUsedForVote;

    IBooCapitalNFT booCapitalNFT;

    constructor(address _NFTaddress) {
        booCapitalNFT = IBooCapitalNFT(_NFTaddress);
    }

    function startContest(address _firstContenderAddress) public onlyOwner {
        require(contests[count].isRunning == false, "Current contest still running !");
        count += 1;
        Contest storage contest = contests[count];
        Contender memory newContender = Contender({
            tokenAddress: _firstContenderAddress,
            votes: 0
        });
        contest.isRunning = true;
        contest.contenders.push(newContender);
    }

    function addContender(address _tokenAddress)
        public
        onlyOwner
    {
        Contest storage contest = contests[count];
        require(contest.contenders.length < 4, "Max contenders amount reached");
        Contender memory newContender = Contender({
            tokenAddress: _tokenAddress,
            votes: 0
        });
        contest.contenders.push(newContender);
    }

    function vote(
        uint256 _contestId,
        uint256 _contenderId,
        uint256[] memory _userNfts
    ) public {
        Contest storage contest = contests[_contestId];
        uint256 votingPower;
        require(
            checkIfNftHasVoted(_userNfts) == false,
            "NFT(s) already voted with"
        );
        require(contest.isRunning == true, "Voting is over");
        for (uint256 i = 0; i < _userNfts.length; i++) {
            require(
                booCapitalNFT.ownerOf(_userNfts[i]) == msg.sender,
                "You are not owner of the NFT(s) selected"
            );
            votingPower++;
            userNFTsUsedForVote[count][msg.sender].push(_userNfts[i]);
        }
        contest.contenders[_contenderId].votes = uint32(votingPower);
    }

    function endContest() public onlyOwner {
        Contest storage contest = contests[count];
        contest.isRunning = false;
    }

    function getAllContest() public view returns (Contest[] memory) {
        Contest[] memory allContestArray = new Contest[](count+1);
        for(uint i = 1; i < count + 1; i++)
        {
            allContestArray[i] = contests[i];
        }
        return allContestArray;
    }

    function getCurrentContest() public view returns (Contest memory) {
        Contest storage currentContest = contests[count];
        return currentContest;
    }

    function getContest(uint _id) public view returns (Contest memory) {
        Contest memory contest = contests[_id];
        return contest;
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
        uint256[] memory userNFTsUsed = userNFTsUsedForVote[count][msg.sender];
        bool result;
        for (uint256 ii = 0; ii < _userNfts.length; ii++) {
            for (uint256 jj = 0; jj < userNFTsUsed.length; jj++) {
                if (_userNfts[ii] == userNFTsUsed[jj]) {
                    result = true;
                    break;
                } else {
                    if (jj == userNFTsUsed.length - 1) {
                        result = false;
                        continue;
                    }
                }
            }
        }
        return result;
    }
}
