// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PharmaSupplyChain is ERC721Enumerable, Ownable {
    //define the different roles in the supply chain
    enum role {
        Manufacturer,
        Pharmacist,
        Buyer,
        Admin
    }

    //define an array or string for all types of roles 
    string[] roleNames = ["Manufacturer", "Pharmacist", "Buyer", "Admin"];

    //define the state of each shipment
    enum shipmentState {
        ReadyToShip,
        ReceivedByPharmacist,
        ReceivedByBuyer
    }

    //define a struct to represent a shipment
    struct shipment {
        uint256 batchNumber;
        string nameOfItem;
        string expiryDate;
        shipmentState state;
        address owner;
        uint256 price;
    }

    //define a struct for a purchase order
    struct purchaseOrder {
        string nameOfItem;
        string descriptionOfOrder;
        address requester;
    }

    //define a mapping from manufacturer address to purchase order
    mapping(address => purchaseOrder) purchaseOrders;

    //define a mapping from user address to user role
    mapping(address => role) users;

    //define a mapping from token ID to medicine
    mapping(uint256 => shipment) private shipments;

    //event emitted when a shipment is created
    event shipmentCreated(uint256 tokenId);

    //event emitted when a shipment is transferred to a new owner
    event shipmentTransferred(uint256 tokenId, address newOwner);

    constructor() ERC721("PharmaSupplyChainSolution", "PSCS") {
        users[msg.sender] = role.Admin;
    }

    //modifier to check if invoker is only manufacturer based on its role
    modifier onlyManufacturer() {
        require(
            uint256(users[msg.sender]) == 0,
            "Only manufacturers can perform this operation"
        );
        _;
    }

    //modifier to check if invoker is only pharmacist based on its role
    modifier onlyPharmacist() {
        require(
            uint256(users[msg.sender]) == 1,
            "Only pharmacists can perform this operation"
        );
        _;
    }

    //modifier to check if invoker is either manufacturer or pharmacist based on its role
    modifier onlyManufacturerOrPharmacist() {
        require(
            (uint256(users[msg.sender]) == 1) ||
                (uint256(users[msg.sender]) == 0),
            "Either manufacturers or phamacists can perform this operation"
        );
        _;
    }

    //modifier to check if invoker is only admin based on its role
    modifier onlyAdmin() {
        require(
            uint256(users[msg.sender]) == 3,
            "Only admins can perform this operation"
        );
        _;
    }

    //function to onboard users into our pharma supply chain solution and assign them roles.
    function onBoardUser(address addrOfUser, role roleOfUser) public onlyAdmin {
        users[addrOfUser] = roleOfUser;
    }

    //function to view user role
    function viewRole() public view returns (string memory) {
        return roleNames[uint256(users[msg.sender])];
    }

    //function to create a purchase order for a particular batch of medicine
    function createPurchaseOrder(
        string memory nameOfItem,
        string memory description,
        address manufacturer
    ) public onlyPharmacist {
        purchaseOrder memory po = purchaseOrder(
            nameOfItem,
            description,
            msg.sender
        );
        purchaseOrders[manufacturer] = po;
    }

    //function to view purchase orders created by pharmacist
    function viewPurchaseOrders()
        public
        view
        onlyManufacturerOrPharmacist
        returns (
            string memory,
            string memory,
            address
        )
    {
        return (
            purchaseOrders[msg.sender].nameOfItem,
            purchaseOrders[msg.sender].descriptionOfOrder,
            purchaseOrders[msg.sender].requester
        );
    }

    //function to create a shipment based on a purchase order used by manufacturer
    function createShipment(
        uint256 batchNumber,
        string memory nameOfItem,
        string memory expiryDate,
        uint256 price
    ) public onlyManufacturer {
        shipment memory newShipment = shipment(
            batchNumber,
            nameOfItem,
            expiryDate,
            shipmentState.ReadyToShip,
            msg.sender,
            price
        );
        uint256 tokenId = totalSupply() + batchNumber;
        _safeMint(msg.sender, tokenId);
        shipments[tokenId] = newShipment;
    }

    //function to view shipments created by the manufacturer
    function viewShipment(uint256 tokenId)
        public
        view
        onlyManufacturerOrPharmacist
        returns (
            uint256,
            string memory,
            string memory,
            shipmentState,
            address,
            uint256
        )
    {
        return (
            shipments[tokenId].batchNumber,
            shipments[tokenId].nameOfItem,
            shipments[tokenId].expiryDate,
            shipments[tokenId].state,
            shipments[tokenId].owner,
            shipments[tokenId].price
        );
    }

    //function to transfer shipment from manufacturer or pharmacist to phramacist or buyer respectively
    function transferShipment(uint256 tokenId, address newOwner)
        public
        onlyManufacturerOrPharmacist
    {
        shipment memory shipmentToTransfer = shipments[tokenId];
        require(
            msg.sender == shipmentToTransfer.owner,
            "Only the current owner of the shipment can transfer the shipment"
        );
        if (users[msg.sender] == role.Manufacturer) {
            require(
                users[newOwner] == role.Pharmacist,
                "Manufacturers can only transfer shipments to  pharmacists"
            );
            require(
                shipmentToTransfer.state == shipmentState.ReadyToShip,
                "Shipment is not available for shipping"
            );
            shipmentToTransfer.state = shipmentState.ReceivedByPharmacist;
        } else if (users[msg.sender] == role.Pharmacist) {
            require(
                users[newOwner] == role.Buyer,
                "Pharmacists can only transfer shipments to buyers"
            );
            require(
                shipmentToTransfer.state == shipmentState.ReceivedByPharmacist,
                "Shipment is not available for shipping"
            );
            shipmentToTransfer.state = shipmentState.ReceivedByBuyer;
        }
        shipmentToTransfer.owner = newOwner;
        _transfer(msg.sender, newOwner, tokenId);
        shipments[tokenId] = shipmentToTransfer;
    }
}
