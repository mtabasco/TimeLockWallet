pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./lib/EIP712MetaTransaction.sol";

/// @title Time Lock Wallet
contract TimeLockWallet is Ownable, ReentrancyGuard, EIP712MetaTransaction {
    
    using SafeMath for uint256;
    
    // @dev Desposit item
    struct Deposit {
        uint256 index; // convenience index to fetch directly the deposit
        address token; // ERC20 address or address(0) if ETH deposit
        uint256 releaseTime; // unlock time
        uint256 amount; // amount in specific token units
    }

    // @dev Holds all deposits (tokens / ETH) for users
    mapping(address => Deposit[]) public deposits;

    // @dev required lock time to claim funds, in minutes
    uint256 public lockInterval = 2;

    // @dev events to fecth deposits and withdrawals
    event Deposited(address sender, uint256 amount, address receiver);
    event Withdrawn(address receiver, uint256 amount);
    
    constructor(
        string memory _name,
        string memory _version
    )
        EIP712MetaTransaction(_name, _version)
    { }

    /// @notice Avoid ETH deposits via regular transfers
    receive() payable external { }

    /// @notice Deposit tokens into contract.
    /// @dev The depositor should approve this contract to manage _token
    /// @param _token The token that holds the funds
    /// @param _amount The amount to be deposited (token units)
    /// @param _receiver The receiver that can claim the _amount after lock time
    function deposit(address _token, uint256 _amount, address _receiver) external nonReentrant {
            require(_amount > 0, "Non-positive deposit amount");
            require(IERC20(_token).allowance(msgSender(), address(this)) >= _amount, "Token allowance not enough");
            
            uint256 depositsLength = deposits[_receiver].length;
            
            Deposit memory depositData;
            depositData.token = _token;
            depositData.releaseTime = block.timestamp + lockInterval * 1 minutes;
            depositData.amount = _amount;
            depositData.index = depositsLength;
            deposits[_receiver].push(depositData);

            IERC20(_token).transferFrom(msgSender(), address(this), _amount);
            emit Deposited(msgSender(), _amount, _receiver);
    }
    
    /// @notice Deposit ETH into contract.
    /// @param _receiver The receiver that can claim the ETH amount sent after lock time
    function deposit(address _receiver) external payable nonReentrant {
        
        uint256 depositsLength = deposits[_receiver].length;
        
        Deposit memory depositData;
        // Left depositData.token default value
        depositData.releaseTime = block.timestamp + lockInterval * 1 minutes;
        depositData.amount = msg.value;
        depositData.index = depositsLength;
        deposits[_receiver].push(depositData);
        
        emit Deposited(msgSender(), msg.value, _receiver);
    }

    /// @notice Withdraw a specific deposit (token / ETH) idetified by its _depositIndex only if the funds are unlocked
    /// @dev Contract should have allowance to send funds to user
    /// @param _depositIndex The index of the deposit for a specific sender

    function withdraw(uint256 _depositIndex) external nonReentrant {
        
        require(deposits[msgSender()].length >= 1, "No deposits for this address");
        uint256 depositsLength = deposits[msgSender()].length;
        
        require(_depositIndex >= 0, "Positive index required");
        require(_depositIndex < depositsLength, "No index found");
        
        Deposit memory depositItem = deposits[msgSender()][_depositIndex];
        require(depositItem.releaseTime < block.timestamp, "Funds still locked");

        

        // After the funds wer sent, the deposit item in the array is removed
        // and replaced by the latest item. Then the latest position is removed.
        deposits[msgSender()][_depositIndex] = deposits[msgSender()][depositsLength - 1];
        deposits[msgSender()][_depositIndex].index = _depositIndex;
        deposits[msgSender()].pop();

        if(depositItem.token == address(0)) { // ETH deposits
            uint256 ethBalance = address(this).balance;
            require(depositItem.amount <= ethBalance, "Balance is low");
            payable(msgSender()).transfer(depositItem.amount);
            
        } else { // It's a token deposit
            IERC20 token = IERC20(depositItem.token);
        
            uint256 tokenBalance = token.balanceOf(address(this));
            require(depositItem.amount <= tokenBalance, "Balance is low");
            //require(token.allowance(msgSender(), address(this)) >= depositItem.amount, "Token allowance not sufficient");
            
            token.transfer(msgSender(), depositItem.amount);
        }

        emit Withdrawn(msgSender(), depositItem.amount);
    }

    /// @notice Sets the timelock interval (only onwer of the contract)
    /// @param _minutes new interval in minutes
    function setLockInterval(uint256 _minutes) external onlyOwner {
        lockInterval = _minutes;
    }

    /// @notice Get all deposits for a given sender
    function getUserDeposits() public view returns (Deposit[] memory) {
        return deposits[msgSender()];
    }

}