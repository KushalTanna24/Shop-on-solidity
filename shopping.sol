// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

contract Ownable{
    address payable _owner;

    constructor(){
        _owner = payable(msg.sender);
    }

    modifier onlyOwner(){
        require(isOwner(), "You are the owner.");
        _;
    }

    function isOwner() public view returns(bool){
         return(msg.sender == _owner);
    }
}

contract Item{
    uint public price;
    uint public pricePaid;
    uint public index;

    ItemManager parentContract;

    constructor(ItemManager _parentContract, uint _price, uint _index){
        price = _price;
        index = _index;
        parentContract = _parentContract;
    }

    receive() external payable{
        require(pricePaid == 0, "item purchased already");
        (bool success, ) = address(parentContract).call{value:msg.value}(abi.encodeWithSignature("buy(uint256)", index));
        pricePaid += msg.value;
        require (success, "Transaction failed");
    }

}

contract ItemManager is Ownable{

    enum supplyChainState{CREATED, PAID, DELIVERED}

    struct structItem{
        Item _item;
        string _name;
        uint _price;
        supplyChainState _state;
    }

    mapping (uint => structItem)public items;
    uint itemIndex;

    event updateDeleviryStatus(uint _itemIndex, uint _step, address _itemAddress);

    function listNewItem(string memory _name, uint _price)public onlyOwner{
        Item item = new Item(this, _price, itemIndex);
        items[itemIndex]._item = item;
        items[itemIndex]._name = _name;
        items[itemIndex]._price = _price;
        items[itemIndex]._state = supplyChainState.CREATED;
        emit updateDeleviryStatus(itemIndex, 0,address(item));
        itemIndex++;
    }

    function buy(uint _itemIndex) public payable{
        require(items[_itemIndex]._price == msg.value,"Please pay full amount to buy selected product");
        require(items[_itemIndex]._state == supplyChainState.CREATED, "Sold out");
        emit updateDeleviryStatus(_itemIndex, 1, address(items[itemIndex]._item));
        items[_itemIndex]._state = supplyChainState.PAID;
    }

    function updateDeliveryStatus(uint _itemIndex) public payable onlyOwner{
        require(items[_itemIndex]._state == supplyChainState.PAID, "You havent paid for this item yet.");
        emit updateDeleviryStatus(_itemIndex, 2, address(items[itemIndex]._item));
        items[_itemIndex]._state = supplyChainState.DELIVERED;
    }
}