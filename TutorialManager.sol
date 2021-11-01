pragma solidity ^0.8.0;

contract Ownable {
    address public _owner;
    constructor() {
        _owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(isOwner(), "You are not authorized to send payment.");
        _;
    }
    
    function isOwner() public view returns(bool) {
        return (_owner == msg.sender);
    }
}

//Tutorial smart contract will handling the payment of each tutorial
contract Tutorial {
   uint public index;
   uint public price;
   uint public amountPaid;
   
   TutorialManager public tutorialManager;
   
   constructor(TutorialManager _tutorialManager, uint _index, uint _price) public {
       index = _index;
       price = _price;
       tutorialManager = _tutorialManager;
   }
   
   receive() external payable {
       require(amountPaid == 0, "Must pay full amount.");
       amountPaid += msg.value;
       (bool success, ) = address(tutorialManager).call{value: msg.value}(abi.encodeWithSignature("payForTutorial(uint256)", index));
       require(success, "Purchase was not successful!");
   }
   
   fallback() external {}
}

//Smart Contract responsible for creating, paying, and setting tutorial to finished.
contract TutorialManager is Ownable {
    
    enum TutorialState{NotPaid, Paid, Finished}
    
    struct Tutorial_Item {
        Tutorial _tutorial;
        uint _tutorialId;
        uint _tutorialPrice;
        TutorialManager.TutorialState _tutorialState;
    }
    
    mapping(uint => Tutorial_Item) public tutorials;
    
    uint numberOfTutorials;
    
    event TutorialStateChanges(uint indexed _tutorialId, uint indexed _index, TutorialManager.TutorialState indexed _tutorialState);
    
    function createTutorial(uint _tutorialPrice, uint _tutorialId) public {
        Tutorial tutorial = new Tutorial(this, numberOfTutorials, _tutorialPrice);
        tutorials[numberOfTutorials]._tutorial = tutorial;
        tutorials[numberOfTutorials]._tutorialPrice = _tutorialPrice;
        tutorials[numberOfTutorials]._tutorialId = _tutorialId;
        tutorials[numberOfTutorials]._tutorialState = TutorialState.NotPaid;
        
        emit TutorialStateChanges(tutorials[numberOfTutorials]._tutorialId, numberOfTutorials, TutorialState.NotPaid);
        
        numberOfTutorials++;
    }
    
    function payForTutorial(uint _index) public payable {
        require(tutorials[_index]._tutorialState == TutorialState.NotPaid, "Tutorial is paid already.");
        require(tutorials[_index]._tutorialPrice == msg.value, "Must pay the tutorial for the full amount.");
        tutorials[_index]._tutorialState = TutorialState.Paid;
        
        emit TutorialStateChanges(tutorials[_index]._tutorialId, _index, TutorialState.Paid);
    }
    
    function finishTutorial(uint _index) public {
        require(tutorials[_index]._tutorialState == TutorialState.Paid, "Tutorial is not finished to be considered finished.");
        tutorials[_index]._tutorialState = TutorialState.Finished;
        
        emit TutorialStateChanges(tutorials[_index]._tutorialId, _index, TutorialState.Finished);
    }
    
}