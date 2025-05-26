// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TimeTitle {
    address public contractOwner;

    struct Property {
        address currentTenant;
        uint leaseStart;
        uint leaseDuration; // in seconds
        bool isLeased;
    }

    mapping(uint => Property) public properties; // propertyId => Property
    uint public nextPropertyId;

    event PropertyRegistered(uint propertyId);
    event LeaseAssigned(uint propertyId, address tenant, uint duration);
    event LeaseRevoked(uint propertyId);
    event LeaseRenewed(uint propertyId, uint newDuration);

    modifier onlyOwner() {
        require(msg.sender == contractOwner, "Only contract owner allowed");
        _;
    }

    modifier leaseActive(uint propertyId) {
        require(properties[propertyId].isLeased, "Property is not leased");
        require(block.timestamp < leaseEnd(propertyId), "Lease has expired");
        _;
    }

    constructor() {
        contractOwner = msg.sender;
    }

    function registerProperty() external onlyOwner {
        properties[nextPropertyId] = Property(address(0), 0, 0, false);
        emit PropertyRegistered(nextPropertyId);
        nextPropertyId++;
    }

    function leaseProperty(uint propertyId, address tenant, uint durationInDays) external onlyOwner {
        Property storage prop = properties[propertyId];
        prop.currentTenant = tenant;
        prop.leaseStart = block.timestamp;
        prop.leaseDuration = durationInDays * 1 days;
        prop.isLeased = true;

        emit LeaseAssigned(propertyId, tenant, durationInDays);
    }

    function revokeLease(uint propertyId) external onlyOwner {
        Property storage prop = properties[propertyId];
        prop.currentTenant = address(0);
        prop.leaseStart = 0;
        prop.leaseDuration = 0;
        prop.isLeased = false;

        emit LeaseRevoked(propertyId);
    }

    function renewLease(uint propertyId, uint additionalDays) external onlyOwner {
        Property storage prop = properties[propertyId];
        require(prop.isLeased, "Not leased");
        prop.leaseDuration += additionalDays * 1 days;

        emit LeaseRenewed(propertyId, prop.leaseDuration);
    }

    function getLeaseInfo(uint propertyId) external view returns (address tenant, uint start, uint end, bool active) {
        Property memory prop = properties[propertyId];
        return (
            prop.currentTenant,
            prop.leaseStart,
            leaseEnd(propertyId),
            isLeaseActive(propertyId)
        );
    }

    function leaseEnd(uint propertyId) public view returns (uint) {
        Property memory prop = properties[propertyId];
        return prop.leaseStart + prop.leaseDuration;
    }

    function isLeaseActive(uint propertyId) public view returns (bool) {
        Property memory prop = properties[propertyId];
        return prop.isLeased && block.timestamp < leaseEnd(propertyId);
    }
}
