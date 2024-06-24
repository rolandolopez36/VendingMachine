// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

// Contract Properties:
// 1) Only the owner can add new products.
// 2) Only the owner can restock products.
// 3) Only the owner can access the machine's balance.
// 4) Anyone can buy products.
// 5) Only the owner can transfer the machine's balance to their account.

contract VendingMachine is Ownable {

    // Struct to represent a snack product
    struct Snack {
        uint32 id;        // Unique identifier for the snack
        string name;      // Name of the snack
        uint32 quantity;  // Quantity available in the machine
        uint256 price;    // Price of the snack in Wei
    }

    // Array to store all snacks
    Snack[] public stock;
    // Mapping from snack ID to its index in the stock array for quick access
    mapping(uint32 => uint32) private snackIndexById;
    // Total number of different snack types
    uint32 public totalSnacks;

    // Events to log significant actions
    event NewSnackAdded(string name, uint256 price);
    event SnackRestocked(string name, uint32 quantity);
    event SnackSold(string name, uint32 amount);

    // Constructor that sets the owner of the contract
    constructor() Ownable() {
        totalSnacks = 0;
    }

    // Function to get all snacks in the machine
    function getAllSnacks() external view returns (Snack[] memory) {
        return stock;
    }

    // Function to add a new snack to the machine, only callable by the owner
    function addNewSnack(string memory _name, uint32 _quantity, uint256 _price) external onlyOwner {
        require(bytes(_name).length != 0, "Error: Name cannot be empty.");
        require(_price != 0, "Error: Price cannot be empty.");
        require(_quantity != 0, "Error: Quantity cannot be empty");

        // Check for duplicate snack names
        for (uint32 i = 0; i < stock.length; i++) {
            require(!compareStrings(_name, stock[i].name), "Error: Duplicate name");
        }

        // Convert price to Wei and create a new snack
        uint256 priceInWei = _price * 1 ether;
        Snack memory newSnack = Snack(totalSnacks, _name, _quantity, priceInWei);
        
        // Add the new snack to the stock array and update the mapping
        stock.push(newSnack);
        snackIndexById[totalSnacks] = uint32(stock.length - 1);
        totalSnacks++;

        // Emit event for adding a new snack
        emit NewSnackAdded(_name, priceInWei);
    }

    // Function to restock an existing snack, only callable by the owner
    function restock(uint32 _id, uint32 _quantity) external onlyOwner {
        require(_quantity != 0, "Error: Invalid quantity.");
        require(_id < totalSnacks, "Error: ID doesn't exist.");

        // Update the quantity of the snack
        uint32 index = snackIndexById[_id];
        stock[index].quantity += _quantity;

        // Emit event for restocking
        emit SnackRestocked(stock[index].name, stock[index].quantity);
    }

    // Function to get the machine's balance, only callable by the owner
    function getMachineBalance() external view onlyOwner returns (uint256) {
        return address(this).balance;
    }

    // Function to withdraw the machine's balance to the owner's account, only callable by the owner
    function withdraw() external onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }

    // Function to buy a snack from the machine
    function buySnack(uint32 _id, uint32 _amount) external payable {
        require(_amount > 0, "Error: Incorrect amount.");
        require(_id < totalSnacks, "Error: ID doesn't exist.");

        uint32 index = snackIndexById[_id];
        require(stock[index].quantity >= _amount, "Error: Insufficient product to fulfill your request.");
        
        uint256 totalPrice = _amount * stock[index].price;
        require(msg.value >= totalPrice, "Error: Insufficient Ether to buy.");

        // Update the quantity of the snack
        stock[index].quantity -= _amount;

        // Emit event for selling a snack
        emit SnackSold(stock[index].name, _amount);

        // Refund excess payment if any
        if (msg.value > totalPrice) {
            payable(msg.sender).transfer(msg.value - totalPrice);
        }
    }

    // Internal pure function to compare two strings
    function compareStrings(string memory a, string memory b) internal pure returns(bool) {
        return (keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b)));
    }
}
