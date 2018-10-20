pragma solidity 0.4.24;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";


/** 
* @author Sameep Singhania
*/
contract LicenseManager is Ownable {

    enum Type {STANDARD, EXTENDED, EDITORIAL, RIGHTS_MANAGED}

    enum Status {ACTIVE, EXPIRED, ENDED, TERMINATED}

    struct License {
        string customerId;
        Type licenseType;
        Status status;
        uint256 createdDate;
        uint256 renewedDate;
        uint256 expiringDate;
        uint256 skuCode;
    }

    mapping(bytes32=>License[]) customerIdVsLicense;

    event LicenseAdded(
        string customerId, 
        uint256 indexed skuCode, 
        uint256 licenseId
    );

    event LicenseRenewed(
        string customerId, 
        uint256 indexed licenseId, 
        uint256 expiringDate
    );

    event LicenseExpired(string customerId, uint256 indexed licenseId);

    event LicenseEnded(string customerId, uint256 indexed licenseId);

    event LicenseTerminated(string customerId, uint256 indexed licenseId);

    modifier licenseExists(string customerId, uint256 licenseId){
    
        bytes32 hashedCustomerId = keccak256(abi.encodePacked(customerId));
        
        require(
            customerIdVsLicense[hashedCustomerId][licenseId].createdDate > 0,
            "License for the customer does not exists"
        );

        _;
        
    }

    function newLicense(
        string customerId,
        Type licenseType,
        uint256 expiringDate,
        uint256 skuCode
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

        bytes32 hashedCustomerId = keccak256(abi.encodePacked(customerId));

        id = customerIdVsLicense[hashedCustomerId].length;

        customerIdVsLicense[hashedCustomerId].push(License({
            customerId:customerId,
            licenseType:licenseType,
            status:Status.ACTIVE,
            createdDate:now,
            renewedDate:now,
            expiringDate:expiringDate,
            skuCode:skuCode
        }));

        emit LicenseAdded(customerId, skuCode, id);
    }


    function renewLicense(
        string customerId, 
        uint256 licenseId, 
        uint256 expiringDate
    )
        external 
        onlyOwner 
        licenseExists(customerId, licenseId)
    {
        bytes32 hashedCustomerId = keccak256(abi.encodePacked(customerId));
        License storage license = customerIdVsLicense[
            hashedCustomerId
            ][
                licenseId
            ];
        require(
            expiringDate > license.expiringDate, 
            "New expiring date should be greater then current expiring date for the license"
        );
        require(
            license.status != Status.ENDED || license.status != Status.TERMINATED
        );

        license.expiringDate = expiringDate;
        license.status = Status.ACTIVE;
        license.renewedDate = now;

        emit LicenseRenewed(customerId, licenseId, expiringDate);

    }

    function checkAndMarkExpire(
        string customerId, 
        uint256 licenseId
    )
        external 
        onlyOwner 
        licenseExists(customerId, licenseId)
        returns (bool expired)
    {   
        expired = false;
        bytes32 hashedCustomerId = keccak256(abi.encodePacked(customerId));
        License storage license = customerIdVsLicense[
            hashedCustomerId
            ][
                licenseId
            ];

        require(license.status == Status.ACTIVE, "License is not active");

        if(license.expiringDate < now){
            license.status = Status.EXPIRED;
            expired = true;
            emit LicenseExpired(customerId, licenseId);
        }
    }

    function endLicense(
        string customerId, 
        uint256 licenseId
    )
        external 
        onlyOwner 
        licenseExists(customerId, licenseId) 
    {
        bytes32 hashedCustomerId = keccak256(abi.encodePacked(customerId));
        License storage license = customerIdVsLicense[
            hashedCustomerId
            ][
                licenseId
            ];
        
        require(
            license.status == Status.EXPIRED, 
            "Only expired license can be end"
        );
        
        license.status = Status.ENDED;

        emit LicenseEnded(customerId, licenseId);
    }

    function terminateLicense(
        string customerId, 
        uint256 licenseId
    )
        external 
        onlyOwner 
        licenseExists(customerId, licenseId) 
    {
        bytes32 hashedCustomerId = keccak256(abi.encodePacked(customerId));
        License storage license = customerIdVsLicense[
            hashedCustomerId
        ][
            licenseId
        ];
        
        require(
            license.status == Status.ENDED || license.status == Status.TERMINATED, 
            "License already ended or terminated"
        );

        license.status = Status.TERMINATED;

        emit LicenseTerminated(customerId, licenseId);
    }

    function getLicenseStatus(
        string customerId, 
        uint256 licenseId
    )
        external 
        licenseExists(customerId, licenseId) 
        returns(Status status) 
    {
        bytes32 hashedCustomerId = keccak256(abi.encodePacked(customerId));

        status = customerIdVsLicense[hashedCustomerId][licenseId].status;

    }

    function getLicense(
        string customerId, 
        uint256 licenseId
    )
        external 
        licenseExists(customerId, licenseId) 
        returns (
            Type licenseType,
            Status status,
            uint256 createdDate,
            uint256 renewedDate,
            uint256 expiringDate,
            uint256 skuCode   
        )
    {
        bytes32 hashedCustomerId = keccak256(abi.encodePacked(customerId));
        License storage license = customerIdVsLicense[
            hashedCustomerId
            ][
                licenseId
            ];

        licenseType = license.licenseType;
        status = license.status;
        createdDate = license.createdDate;
        renewedDate = license.renewedDate;
        expiringDate = license.expiringDate;
        skuCode = license.skuCode;
    }

    function checkLicenseExists(
        string customerId, 
        uint256 licenseId
    )
        external 
        returns (bool exists)
    {
        bytes32 hashedCustomerId = keccak256(abi.encodePacked(customerId));

        exists = customerIdVsLicense[
            hashedCustomerId
        ][
            licenseId
        ].createdDate > 0;
    }

}