import "@openzeppelin/contracts/access/Ownable.sol";

pragma solidity ^0.8.13;

interface IBooCapitalNFT {
    function ownerOf(uint256) external returns (address);

    function totalSupply() external returns (uint256);

    function walletOfOwner(address) external view returns (uint256[] memory);
}

contract BooCapitalVotes {

    struct Proposal {
        address tokenAddress;
        string name;
        string logoUrl;
        uint32 votes;
        bool inRunning;
    }

    uint256 public count;

    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => uint256[])) public userNFTsUsedForVote;

    IBooCapitalNFT booCapitalNFT;

    constructor(address _NFTaddress) {
        booCapitalNFT = IBooCapitalNFT(_NFTaddress);
    }

    function walletOfNFTOwner(address user)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory id = booCapitalNFT.walletOfOwner(user);
        return id;
    }

    function startBomb(address _tokenAddress, string memory _name, string memory _url) private onlyOwner {
        count += 1;
        proposals[count] = Proposal({
            tokenAddress: _tokenAddress,
            name: _name,
            url : _url,
            votes: 0,
            inRunning: true
        });
    }

    function vote() public {
        require(uint(walletOfNFTOwner(msg.sender).length) > 0);
        uint votingPower = uint(walletOfNFTOwner(msg.sender).length);
        proposals[count].votes = votingPower;
    }

    function endBomb() internal {}
}
