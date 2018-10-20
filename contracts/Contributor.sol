pragma solidity 0.4.24;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";


/** 
* @author Sameep Singhania
*/
contract Contributor is Ownable {
    enum Status {PENDING, ACCEPTED, REJECTED}

    struct Contribution{
        address initiator;
        bytes32 contentHash;
        string userId;
        Status status;
        uint256 lastUpdated;
    }

    mapping(bytes32=>bytes32[]) userVscontentHash;

    mapping(bytes32=>Contribution)contentHashVsContribution;

    event ContributionAdded(string userId, bytes32 indexed contentHash);

    event StatusUpdated(bytes32 indexed contentHash, Status status);

    /** 
    * @dev Function to add new contribution
    * 
    */
    function addContribution(string userId, bytes32 contentHash)external {

        require(
            contentHashVsContribution[contentHash].initiator == address(0), 
            "Content hash already exists"
        );
        require(bytes(userId).length>0, "Please pass valid userId");
        require(contentHash != bytes32(0), "Please pass valid content hash");

        contentHashVsContribution[contentHash] = Contribution({
            initiator:msg.sender,
            contentHash:contentHash,
            userId:userId,
            status:Status.PENDING,
            lastUpdated:now
        });

        userVscontentHash[
            keccak256(
                abi.encodePacked(userId)
            )
        ].push(
            contentHash
        );

        emit ContributionAdded(userId, contentHash);
    }

    /** 
    * @dev Change status of the contribution by contentHash
    * Only owner of the contract can do that
    */
    function changeStatus(
        bytes32 contentHash, 
        Status status
    )
        external 
        onlyOwner
    {
        require(
            contentHashVsContribution[contentHash].initiator != address(0), 
            "Content hash does not exists"
        );

        contentHashVsContribution[contentHash].status = status;
        contentHashVsContribution[contentHash].lastUpdated = now;


        emit StatusUpdated(contentHash, status);
    }


    /** 
    * @dev Get all contribution content hash for user
    */
    function getAllContentForUser(
        string userId
    )
        external 
        view 
        returns(bytes32[]contentHashes) 
    {
        contentHashes = userVscontentHash[
            keccak256(abi.encodePacked(userId))
        ]; 
    }

    /**
    * @dev Returns Contribution info for the content hash, if it exists otherwise defaults values will be returned
    */
    function getContributionInfo(
        bytes32 contentHash
    )
        external 
        view 
        returns(
            address initiator, 
            string userId, 
            Status status, 
            uint256 lastUpdated
        )
    {
        initiator = contentHashVsContribution[contentHash].initiator;
        userId = contentHashVsContribution[contentHash].userId;
        status = contentHashVsContribution[contentHash].status;
        lastUpdated = contentHashVsContribution[contentHash].lastUpdated;
    }

}
