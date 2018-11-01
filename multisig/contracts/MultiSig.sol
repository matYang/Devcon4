pragma solidity ^0.4.23;

contract MultiSig {
	struct Transaction {
		address destinationAddress;
		uint256 valueWei;
		bool transactionStatus;
	}

	address[] public owners;
	uint256 public required;

	uint256 public transactionCount;
	mapping(uint => Transaction) public transactions;
	mapping(uint => mapping(address => bool)) public confirmations;
	mapping(address => bool) public validOwners;

	modifier handleEdgeCases(address[] _owners, uint256 _required) {
		require(_owners.length > 0);
		require(_required > 0);
		require(_required < _owners.length);

		_;
	}

	modifier validOwner() {
		require(validOwners[msg.sender]);

    	_;
	}

	constructor(address[] _owners, uint256 _required) public handleEdgeCases(_owners, _required) {
		for(uint256 i = 0; i < _owners.length; i++){
			require(_owners[i] != address(0), "Address cannot be 0");
      		validOwners[_owners[i]] = true;
	    }

		owners = _owners;
		required = _required;
	}

	function addTransaction(address _dest, uint256 _valueWei) internal returns (uint256) {
		require(_dest != address(0));

		transactions[transactionCount] = Transaction(
			_dest,
			_valueWei,
			false
		);

		transactionCount++;
		return transactionCount - 1;
	}

	function confirmTransaction(uint256 _txId) public validOwner {
		require(transactions[_txId].destinationAddress != address(0), "Must be a valid transaction");
		require(transactions[_txId].transactionStatus != true, "Must be an unconfirmed transaction");

    	confirmations[_txId][msg.sender] = true;

    	if (isConfirmed(_txId)) {
    		executeTransaction(_txId);
    	}
  	}

  	// Solidity cannot return dynamic arrays
	function getConfirmations(uint256 _transactionId) public view returns(address[] memory confirmators) {
		uint256 count = 0;
		for (uint256 j = 0; j < owners.length; j++) {
	  		if (confirmations[_transactionId][owners[j]]) {
	    		count ++;
	  		}
		}
		confirmators = new address[](count);
		uint256 ind = 0;
		for (uint256 i = 0; i < owners.length; i++) {
	  		if (confirmations[_transactionId][owners[i]]) {
	    		confirmators[ind] = owners[i];
	    		ind++;
	  		}
		}
	}

	function submitTransaction(address _dest, uint256 _valueWei) public {
		require(_dest != address(0));

		uint256 txId = addTransaction(_dest, _valueWei);
		confirmTransaction(txId);
	}

	function () public payable {

	}

	function isConfirmed(uint256 _txId) public view returns (bool) {
		address[] memory confirmedOwners = getConfirmations(_txId);

		return confirmedOwners.length >= required;
	}

	function executeTransaction(uint256 _txId) public {
		Transaction storage txn = transactions[_txId];
		require(txn.transactionStatus == false, "Transaction already executed");

		require(isConfirmed(_txId), "Transaction not yet confirmed");

		txn.destinationAddress.transfer(txn.valueWei);
		txn.transactionStatus = true;
	}

	function getOwners() public view returns(address[]) {
    	return owners;
    }

	function getTransactionCount(bool _pending, bool _executed) public view returns(uint256) {
		uint256 pendingCount = 0;
		uint256 executedCount = 0;

		for (uint256 i = 0; i < transactionCount; i++) {
			if (transactions[i].transactionStatus) {
				executedCount++;
			} else {
				pendingCount++;
			}
		}

		if (_pending && !_executed) {
			return pendingCount;
		} else if (!_pending && _executed) {
			return executedCount;
		} else if (_pending && _executed) {
			return pendingCount + executedCount;
		} else {
			return 0;
		}
	}

	function getTransactionIds(bool _pending, bool _executed) public view returns (uint256[] memory txIds) {
		uint256 count = getTransactionCount(_pending, _executed);

		txIds = new uint256[](count);
		uint256 txIdsIdx = 0;
		for (uint256 i = 0; i < transactionCount; i++) {
			if (_pending && !transactions[i].transactionStatus) {
				txIds[txIdsIdx] = i;
				txIdsIdx++;
			}

			if (_executed && transactions[i].transactionStatus) {
				txIds[txIdsIdx] = i;
				txIdsIdx++;
			}
		}
	}

}
