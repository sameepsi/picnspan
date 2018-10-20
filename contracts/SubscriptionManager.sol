pragma solidity 0.4.24;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

contract SubscriptionManager is Ownable {
    using SafeMath for uint256;

    enum Type {STANDARD, EXTENDED, EDITORIAL, RIGHTS_MANAGED}

    enum Status {ACTIVE, EXPIRED, ENDED, TERMINATED}

    struct  Subscription {
        string customerId;
        Type subscriptionType;
        Status status;
        uint256 createdDate;
        uint256 renewedDate;
        uint256 expiringDate;
        uint256 credits;
    }

    mapping(bytes32=>Subscription[]) customerIdVsSubscription;

    event SubscriptionAdded(
        string customerId,  
        uint256 subscriptionId
    );
    event SubscriptionRenewed(
        string customerId, 
        uint256 indexed subscriptionId
    );

    modifier subscriptionExists(string customerId, uint256 subscriptionId){
    
        bytes32 hashedCustomerId = keccak256(abi.encodePacked(customerId));
        
        require(
            customerIdVsSubscription[hashedCustomerId][subscriptionId].createdDate > 0,
            "Subscription for the customer does not exists"
        );

        _;
        
    }
    function newSubscription(
        string customerId,
        Type subscriptionType,
        uint256 expiringDate,
        uint256 credits
    )
        external
        onlyOwner
        returns (uint256 id)
    {
        require(
            bytes(customerId).length > 0, 
            "Please provide valid customerId"
        );

        require(expiringDate > now, "Please provide valid expiring date");

        require(credits > 0, "Credits must be greater than 0");

        bytes32 hashedCustomerId = keccak256(abi.encodePacked(customerId));

        id = customerIdVsSubscription[hashedCustomerId].length;

        customerIdVsSubscription[hashedCustomerId].push(Subscription({
            customerId:customerId,
            subscriptionType:subscriptionType,
            status:Status.ACTIVE,
            createdDate:now,
            renewedDate:now,
            expiringDate:expiringDate,
            credits:credits
        }));

        emit SubscriptionAdded(customerId, id);
    }

    function renewSubscription(
        string customerId, 
        uint256 subscriptionId, 
        uint256 credits,
        uint256 expiringDate
    )
        external 
        onlyOwner 
        subscriptionExists(customerId, subscriptionId)
    {
        bytes32 hashedCustomerId = keccak256(abi.encodePacked(customerId));
        Subscription storage subscription = customerIdVsSubscription[
            hashedCustomerId
            ][
                subscriptionId
            ];
        require(
            expiringDate > subscription.expiringDate || credits>0, 
            "Invalid request"
        );
        require(
            subscription.status != Status.ENDED || subscription.status != Status.TERMINATED
        );
        if(expiringDate > now){
            subscription.expiringDate = expiringDate;
        }
        
        subscription.status = Status.ACTIVE;
        subscription.renewedDate = now;
        subscription.credits = subscription.credits.add(credits);

        emit SubscriptionRenewed(customerId, subscriptionId);

    }
}