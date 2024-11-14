// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SimpleEscrow is Pausable, Ownable {
    enum EscrowState { Created, Funded, Completed, Refunded }
    
    struct Escrow {
        address payable buyer;
        address payable seller;
        uint256 amount;
        EscrowState state;
    }

    mapping(uint256 => Escrow) public escrows;
    uint256 public escrowCount;

    event EscrowCreated(uint256 indexed escrowId, address indexed buyer, address indexed seller, uint256 amount);
    event EscrowFunded(uint256 indexed escrowId);
    event EscrowCompleted(uint256 indexed escrowId);
    event EscrowRefunded(uint256 indexed escrowId);

    modifier onlyBuyer(uint256 escrowId) {
        require(msg.sender == escrows[escrowId].buyer, "Only buyer can call this function");
        _;
    }

    modifier onlySeller(uint256 escrowId) {
        require(msg.sender == escrows[escrowId].seller, "Only seller can call this function");
        _;
    }

    modifier inState(uint256 escrowId, EscrowState state) {
        require(escrows[escrowId].state == state, "Invalid escrow state");
        _;
    }

    function createEscrow(address payable seller) external payable whenNotPaused {
        require(msg.value > 0, "Amount must be greater than zero");
        
        escrowCount++;
        escrows[escrowCount] = Escrow({
            buyer: payable(msg.sender),
            seller: seller,
            amount: msg.value,
            state: EscrowState.Created
        });

        emit EscrowCreated(escrowCount, msg.sender, seller, msg.value);
    }

    function fundEscrow(uint256 escrowId) external inState(escrowId, EscrowState.Created) whenNotPaused {
        Escrow storage escrow = escrows[escrowId];
        require(msg.sender == escrow.buyer, "Only buyer can fund the escrow");
        
        escrow.state = EscrowState.Funded;
        emit EscrowFunded(escrowId);
    }

    function completeEscrow(uint256 escrowId) external onlySeller(escrowId) inState(escrowId, EscrowState.Funded) whenNotPaused {
        Escrow storage escrow = escrows[escrowId];
        escrow.state = EscrowState.Completed;

        escrow.seller.transfer(escrow.amount);
        emit EscrowCompleted(escrowId);
    }

    function refundEscrow(uint256 escrowId) external inState(escrowId, EscrowState.Funded) whenPaused {
        Escrow storage escrow = escrows[escrowId];
        escrow.state = EscrowState.Refunded;

        escrow.buyer.transfer(escrow.amount);
        emit EscrowRefunded(escrowId);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}