// SPDX-License-Identifier: MIT
pragma solidity ^0.8;
 
contract ownable{

    address owner;
    modifier onlyOwner(){
        require (isOwner(), "Only owner allowed." );
        _;
    }

    function isOwner() public view returns(bool){
        return(msg.sender == owner);
    }
}

contract Item{  //item specific contraact so user can buy specific item.
    
    uint public price;  
    uint public pricePaid;
    uint public index;
    string public name;
    
    ItemManager parentContract;

    constructor( ItemManager _parentContract, uint _price, uint _index, string memory _name){
        price = _price;
        index = _index;
        parentContract = _parentContract;
        name = _name;
    }

    receive() external payable{
        require(pricePaid == 0, "item is paid already");
        require(price == msg.value, "Only full payment allowed");
        pricePaid += msg.value;
        (bool success, ) = address(parentContract).call{value:msg.value}(abi.encodeWithSignature("buy(uint256)", index));
        require (success, "Transaction failed");
    }
}

contract ItemManager is ownable{

    enum deliveryStatus{CREATED, PAID, DELIVERED}

    struct structItem{
        Item _item;
        string name;
        uint price;
        ItemManager.deliveryStatus state;
    }

    mapping(uint => structItem) public items;

    uint itemIndex;

    event itemEvent(address purchasedBy, uint pricePaid, string itemName, address itemAddress , uint deliveryState, uint pice);


    function addNewItem(string memory _name, uint _price) public onlyOwner{
        Item item  = new Item(this, _price, itemIndex, _name); // item will be smart contract holding data of that particular item.
        items[itemIndex] = structItem(item,_name,_price, deliveryStatus.CREATED);
        emit itemEvent(address(0),0,items[itemIndex].name, address(item),uint(items[itemIndex].state), _price);
        itemIndex++;
    }

    function buy(uint _index) public payable{
        require(items[_index].price == msg.value, "Only full payments accepted" );
        require(items[_index].state == deliveryStatus.CREATED, "Sold out");
        items[_index].state = deliveryStatus.PAID;
        emit itemEvent(msg.sender, msg.value, items[_index].name, address(items[_index]._item),uint(items[_index].state), items[_index].price);
    }

    function deliver(uint _index)public onlyOwner{
        require(items[_index].state == deliveryStatus.PAID, "Product is not purched yet" );
        items[_index].state = deliveryStatus.DELIVERED;
    }

}