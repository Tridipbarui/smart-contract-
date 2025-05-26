// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TimeTitle {
    address public propertyOwner;

    struct Lease {
        address lessee;
        uint256 startTime;
        uint256 endTime;
        bool active;
    }

    uint256 public nextPropertyId;
    mapping(uint256 => Lease) public leases;

    event LeaseCreated(uint256 indexed propertyId, address indexed lessee, uint256 startTime, uint256 endTime);
    event LeaseEnded(uint256 indexed propertyId, address indexed lessee);
    event LeaseRevoked(uint256 indexed propertyId);

    modifier onlyOwner() {
        require(msg.sender == propertyOwner, "Not the property owner");
        _;
    }

    modifier onlyLessee(uint256 _id) {
        require(msg.sender == leases[_id].lessee, "Not the lessee");
        _;
    }

    constructor() {
        propertyOwner = msg.sender;
    }

    function createLease(address _lessee, uint256 _durationInSeconds) external onlyOwner {
        uint256 currentTime = block.timestamp;
        uint256 endTime = currentTime + _durationInSeconds;

        leases[nextPropertyId] = Lease({
            lessee: _lessee,
            startTime: currentTime,
            endTime: endTime,
            active: true
        });

        emit LeaseCreated(nextPropertyId, _lessee, currentTime, endTime);
        nextPropertyId++;
    }

    function isLeaseActive(uint256 _id) public view returns (bool) {
        Lease memory lease = leases[_id];
        return lease.active && block.timestamp < lease.endTime;
    }

    function endLease(uint256 _id) external onlyOwner {
        Lease storage lease = leases[_id];
        require(lease.active, "Lease already ended");
        lease.active = false;
        emit LeaseEnded(_id, lease.lessee);
    }

    function revokeLease(uint256 _id) external onlyOwner {
        require(leases[_id].active, "Lease already inactive");
        leases[_id].active = false;
        emit LeaseRevoked(_id);
    }

    function getLeaseInfo(uint256 _id) external view returns (
        address lessee,
        uint256 startTime,
        uint256 endTime,
        bool active,
        bool currentlyActive
    ) {
        Lease memory lease = leases[_id];
        return (
            lease.lessee,
            lease.startTime,
            lease.endTime,
            lease.active,
            isLeaseActive(_id)
        );
    }
}

