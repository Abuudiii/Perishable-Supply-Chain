// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract SupplyChain {
    // 0.01 eth for creating a request for tracking
    uint CREATE_FEE = 1e16;
    address owner;

    struct Product {
        address creator;
        address[] entities;
        mapping(address => uint) entityIndex;
        uint status;
        string[] productData;
    }

    mapping(uint => Product) _products;
    mapping(address => uint) _ownerToRequest;
    mapping(address => bool) _blacklist;

    constructor() {
        owner = msg.sender;
    }

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
        for (uint i=0; i< _entities.length;i++) {
            require(!_blacklist[_entities[i]], 'the chosen provider is in the blacklist');
            _products[_productHash].entityIndex[_entities[i]] = i+1;
        }
    }

    function updateData(uint _productHash, string memory _data) public productExists(_productHash) correctOrder(_productHash) {
        _products[_productHash].productData[_products[_productHash].status] = _data;
        _products[_productHash].status += 1;
    }

    function changeProvider(uint _productHash, address _previousProvider, address _newProvider) public productExists(_productHash) {
        require(msg.sender == _products[_productHash].creator, 'only the creator can change the provider');
        uint index = _products[_productHash].entityIndex[_previousProvider];
        require(index != 0, 'unknown previous provider');
        require(index > _products[_productHash].status, 'already passed that state');
        _products[_productHash].entityIndex[_previousProvider] = 0;
        _products[_productHash].entityIndex[_newProvider] = index;
        _products[_productHash].entities[index - 1] = _newProvider;
    }

    function blacklistProvider(address _badProvider) public {
        require(msg.sender == owner, 'only the owner can blacklist a provider');
        _blacklist[_badProvider] = true;
    }

    function unblockProvider(address _provider) public {
        require(msg.sender == owner, 'only the owner can unblock a provider');
        _blacklist[_provider] = false;
    }

    function getData(uint _productHash) public view productExists(_productHash) returns(address, address, string[] memory) {
        Product memory currentProduct = _products[_productHash];
        return (currentProduct.creator, currentProduct.entities[currentProduct.status], currentProduct.productData);
    }
}
