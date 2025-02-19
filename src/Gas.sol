// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./Ownable.sol";

contract GasContract {
    uint256 public immutable totalSupply; // cannot be updated
    uint256 public paymentCounter = 0;
    mapping(address => uint256) public balances;
    uint256 public tradePercent = 12;
    address public contractOwner;
    mapping(address => Payment[]) public payments;
    mapping(address => uint256) public whitelist;
    address[5] public administrators;
    enum PaymentType {
        Unknown,
        BasicPayment,
        Refund,
        Dividend,
        GroupPayment
    }
    // History[] public paymentHistory; // when a payment was updated

    struct Payment {
        PaymentType paymentType;
        bool adminUpdated;
        uint256 paymentID;
        string recipientName; // max 8 characters
        address recipient;
        address admin; // administrators address
        uint256 amount;
    }

    struct History {
        uint256 lastUpdate;
        address updatedBy;
        uint256 blockNumber;
    }
    uint256 wasLastOdd = 1;
    // mapping(address => uint256) public isOddWhitelistUser;
    
    struct ImportantStruct {
        uint256 amount;
        // uint256 valueA; // max 3 digits
        // uint256 bigValue;
        // uint256 valueB; // max 3 digits
        bool paymentStatus;
        // address sender;
    }
    mapping(address => ImportantStruct) public whiteListStruct;

    event AddedToWhitelist(address userAddress, uint256 tier);

    modifier onlyAdminOrOwner() {
        address senderOfTx = msg.sender;
        if (checkForAdmin(senderOfTx)) {
            _;
        } else if (senderOfTx == contractOwner) {
            _;
        } else {
            revert(
                "onlyAdminOrOwner"
            );
        }
    }

    // modifier checkIfWhiteListed(address sender) {
    //     address senderOfTx = msg.sender;
    //     require(
    //         senderOfTx == sender,
    //         "Gas Contract CheckIfWhiteListed modifier : revert happened because the originator of the transaction was not the sender"
    //     );
    //     // uint256 usersTier = whitelist[senderOfTx];
    //     // require(
    //     //     usersTier > 0,
    //     //     "Gas Contract CheckIfWhiteListed modifier : revert happened because the user is not whitelisted"
    //     // );
    //     // require(
    //     //     usersTier < 4,
    //     //     "Gas Contract CheckIfWhiteListed modifier : revert happened because the user's tier is incorrect, it cannot be over 4 as the only tier we have are: 1, 2, 3; therfore 4 is an invalid tier for the whitlist of this contract. make sure whitlist tiers were set correctly"
    //     // );
    //     _;
    // }

    event supplyChanged(address indexed, uint256 indexed);
    event Transfer(address recipient, uint256 amount);
    event PaymentUpdated(
        address admin,
        uint256 ID,
        uint256 amount,
        string recipient
    );
    event WhiteListTransfer(address indexed);

    constructor(address[] memory _admins, uint256 _totalSupply) {
        address _contractOwner = msg.sender;
        contractOwner = _contractOwner;
        totalSupply = _totalSupply;

        for (uint256 ii = 0; ii < administrators.length; ii++) {
            if (_admins[ii] != address(0)) {
                administrators[ii] = _admins[ii];
                if (_admins[ii] == _contractOwner) {
                    balances[_contractOwner] = _totalSupply;
                } 
                if (_admins[ii] == _contractOwner) {
                    emit supplyChanged(_admins[ii], _totalSupply);
                }
            }
        }
    }

    function checkForAdmin(address _user) public view returns (bool admin_) {
        for (uint256 ii = 0; ii < administrators.length; ii++) {
            if (administrators[ii] == _user) {
                return true;
            }
        }
        return false;
    }

    function balanceOf(address _user) public view returns (uint256 balance_) {
        return balances[_user];
    }

    function transfer(
        address _recipient,
        uint256 _amount,
        string calldata _name
    ) public {
        address senderOfTx = msg.sender;
        require(
            balances[senderOfTx] >= _amount,
            "insufficientBalance"
        );
        require(
            bytes(_name).length < 9,
            "nameLengthGreaterThan9"
        );
        balances[senderOfTx] -= _amount;
        balances[_recipient] += _amount;
        emit Transfer(_recipient, _amount);
        Payment memory payment;
        payment.admin = address(0);
        payment.adminUpdated = false;
        payment.paymentType = PaymentType.BasicPayment;
        payment.recipient = _recipient;
        payment.amount = _amount;
        payment.recipientName = _name;
        payment.paymentID = ++paymentCounter;
        payments[senderOfTx].push(payment);
        // bool[] memory status = new bool[](tradePercent);
        // for (uint256 i = 0; i < tradePercent; i++) {
        //     status[i] = true;
        // }
        // return (status[0] == true);
    }

    // function updatePayment(
    //     address _user,
    //     uint256 _ID,
    //     uint256 _amount,
    //     PaymentType _type
    // ) public onlyAdminOrOwner {
    //     require(
    //         _ID > 0,
    //         "Gas Contract - Update Payment function - ID must be greater than 0"
    //     );
    //     require(
    //         _amount > 0,
    //         "Gas Contract - Update Payment function - Amount must be greater than 0"
    //     );
    //     require(
    //         _user != address(0),
    //         "Gas Contract - Update Payment function - Administrator must have a valid non zero address"
    //     );

    //     address senderOfTx = msg.sender;

    //     for (uint256 ii = 0; ii < payments[_user].length; ii++) {
    //         if (payments[_user][ii].paymentID == _ID) {
    //             payments[_user][ii].adminUpdated = true;
    //             payments[_user][ii].admin = _user;
    //             payments[_user][ii].paymentType = _type;
    //             payments[_user][ii].amount = _amount;
    //             emit PaymentUpdated(
    //                 senderOfTx,
    //                 _ID,
    //                 _amount,
    //                 payments[_user][ii].recipientName
    //             );
    //         }
    //     }
    // }

    function addToWhitelist(address _userAddrs, uint256 _tier)
        public
        onlyAdminOrOwner
    {
        require(
            _tier < 255,
            "TierBiggerThan255"
        );
        
        if (_tier > 3) {
            whitelist[_userAddrs] = 3;
        } else {
            whitelist[_userAddrs] = _tier;
        }
        uint256 wasLastAddedOdd = wasLastOdd;
        if (wasLastAddedOdd == 1) {
            wasLastOdd = 0;
            // isOddWhitelistUser[_userAddrs] = wasLastAddedOdd;
        } else if (wasLastAddedOdd == 0) {
            wasLastOdd = 1;
            // isOddWhitelistUser[_userAddrs] = wasLastAddedOdd;
        } else {
            revert("Contract hacked, imposible, call help");
        }
        emit AddedToWhitelist(_userAddrs, _tier);
    }

    function whiteTransfer(
        address _recipient,
        uint256 _amount
    ) public {
        address senderOfTx = msg.sender;
        whiteListStruct[senderOfTx] = ImportantStruct(_amount, true);
        
        require(
            balances[senderOfTx] >= _amount,
            "insufficientBalance"
        );
        require(
            _amount > 3,
            "amountSmallerThan3"
        );
        balances[senderOfTx] -= _amount;
        balances[_recipient] += _amount;
        balances[senderOfTx] += whitelist[senderOfTx];
        balances[_recipient] -= whitelist[senderOfTx];
        
        emit WhiteListTransfer(_recipient);
    }


    function getPaymentStatus(address sender) public returns (bool, uint256) {        
        return (whiteListStruct[sender].paymentStatus, whiteListStruct[sender].amount);
    }

    receive() external payable {
        payable(msg.sender).transfer(msg.value);
    }


    fallback() external payable {
         payable(msg.sender).transfer(msg.value);
    }
}