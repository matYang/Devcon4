pragma solidity 0.4.19;
contract MultiSig {
  address[] public owners;
  uint256 public required;
  struct Transaction {
    address destinationAddress;
    uint256 valueInWei;
    bool transactionStatus;
    bytes data;
  }
  uint256 public transactionCount; 
  mapping (uint=>Transaction) public transactions;
  mapping (uint=>mapping(address=>bool)) public confirmations;
  mapping (address =>bool) public validOwners;
  modifier handleEdgeCases(address[] _owners, uint _required) {
    require(_owners.length > 0);
    require(_required > 0);
    require(_required <= _owners.length);
    _;
  }
  function MultiSig(address[] _owners, uint256 _required) handleEdgeCases(_owners, _required) public {
    owners = _owners;
    for(uint i=0;i<owners.length;i++){
      validOwners[owners[i]] = true;
    }
    required = _required;
  }
  function addTransaction(address _dest, uint256 _value, bytes _data) internal returns (uint256) {
    require(_dest != address(0));
    transactions[transactionCount] = Transaction (
      _dest, _value, false, _data
    );
    transactionCount++;
    return transactionCount - 1;
  }  
  modifier isValidOwner() {
    require(validOwners[msg.sender]);
    _;
  }
  function confirmTransaction(uint txId) public isValidOwner {
    require(transactions[txId].destinationAddress!=address(0));
    require(confirmations[txId][msg.sender]==false);
    confirmations[txId][msg.sender] = true;
    if(isConfirmed(txId)) {
      executeTransaction(txId);
    }
  }
  function getConfirmations(uint _transactionId) public view returns(address[] memory confirmators) {
    uint count = 0;
    for (uint j = 0; j<owners.length; j++) {
      if (confirmations[_transactionId][owners[j]]) {
        count ++;
      }
    }
    confirmators = new address[](count);
    uint ind = 0;
    for (uint i = 0; i<owners.length; i++) {
      if (confirmations[_transactionId][owners[i]]) {
        confirmators[ind++] = owners[i];
      }
    }
  }
  
  function () public payable {
  }
  function isConfirmed(uint256 _transactionId) public constant returns (bool) {
    address[] memory confirmators = getConfirmations(_transactionId);
    return (confirmators.length >= required);
  }
  function submitTransaction(address _destinationAddress,uint256 _value, bytes _data) public {
    uint256 txnID = addTransaction(_destinationAddress,_value, _data);
    confirmTransaction(txnID);
  }
  function executeTransaction(uint256 _transactionId) public {
    require(isConfirmed(_transactionId));
    Transaction storage txn = transactions[_transactionId];
    require(!txn.transactionStatus);
    txn.destinationAddress.call.value(txn.valueInWei)(txn.data);
    txn.transactionStatus = true;
  }
  function getTransactionCount(bool _pending, bool _executed) public view returns(uint) {
    uint count;
    for(uint i = 0; i < transactionCount; i++) {
        if(_pending && !transactions[i].transactionStatus) {
            count++;
        }
        else if(_executed && transactions[i].transactionStatus) {
            count++;
        }
    }
    return count;
  }
  function getTransactionIds(bool _pending, bool _executed) public view returns(uint[]) {
    uint count;
    for(uint i = 0; i < transactionCount; i++) {
        if(_pending && !transactions[i].transactionStatus) {
            count++;
        }
        else if(_executed && transactions[i].transactionStatus) {
            count++;
        }
    }
    uint[] memory ids = new uint[](count);
    uint idsCount = 0;
    for(uint j = 0; j < transactionCount; j++) {
        if(_pending && !transactions[j].transactionStatus) {
            ids[idsCount] = j;
            idsCount++;
        }
        else if(_executed && transactions[j].transactionStatus) {
            ids[idsCount] = j;
            idsCount++;
        }
    }
    return ids;
  }
  function getOwners() public view returns(address[]) {
      return owners;
    }
}