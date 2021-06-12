// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract SupplyChain {
    // 0.01 eth for creating a request for tracking
    uint CREATE_FEE = 1e16;

    struct Product {
        address creator;
        address[] entities;
        uint status;
        string[] productData;
    }

    mapping(uint => Product) _products;
    mapping(address => uint) _ownerToRequest;

    modifier productExists(uint _productHash) {
        require(_products[_productHash].creator != address(0), 'product with the given hash does not exist');
        _;
    }

    modifier correctOrder(uint _productHash) {
        require(_products[_productHash].entities[_products[_productHash].status] == msg.sender);
        _;
    }

    function createRequest(uint _productHash, address[] memory _entities) public payable {
        require(msg.value == CREATE_FEE, 'incorrect fee paid');
        require(_products[_productHash].creator == address(0), 'product with the given hash already exists');
        string[] memory temp = new string[](_entities.length);
        _products[_productHash] = Product(msg.sender, _entities, 0, temp);
    }

    function updateData(uint _productHash, string memory _data) public productExists(_productHash) correctOrder(_productHash) {
        _products[_productHash].productData[_products[_productHash].status] = _data;
        _products[_productHash].status += 1;
    }

    function getData(uint _productHash) public view productExists(_productHash) returns(address, address, string[] memory) {
        Product memory currentProduct = _products[_productHash];
        return (currentProduct.creator, currentProduct.entities[currentProduct.status], currentProduct.productData);
    }
}
