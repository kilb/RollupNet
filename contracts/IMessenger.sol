// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOPMessenger {
    function sendMessage(address _target, bytes calldata _message, uint32 _minGasLimit) external payable;
}

// https://docs.metis.io/dev/protocol-in-detail/cross-domain-messaging
interface IMetisMessenger {
    /*************
     * Variables *
     *************/

    function xDomainMessageSender() external view returns (address);

    /********************
     * Public Functions *
     ********************/
    
    /**
     * Sends a cross domain message to the target messenger.
     * @param _target Target contract address.
     * @param _message Message to send to the target.
     * @param _gasLimit Gas limit for the provided message.
     */
    function sendMessage(
        address _target,
        bytes calldata _message,
        uint32 _gasLimit
    ) external payable;
}


interface IMantleMessenger {
    /*************
     * Variables *
     *************/

    function xDomainMessageSender() external view returns (address);

    /********************
     * Public Functions *
     ********************/
    
    /**
     * Sends a cross domain message to the target messenger.
     * @param _target Target contract address.
     * @param _message Message to send to the target.
     * @param _gasLimit Gas limit for the provided message.
     */
    function sendMessage(
        address _target,
        bytes calldata _message,
        uint32 _gasLimit
    ) external payable;
}

interface IArbMessenger {
     function sendL2Message(bytes calldata messageData) external returns (uint256);
     // `l1CallValue (also referred to as deposit)`: Not a real function parameter, it is rather the callValue that is sent along with the transaction
     // `address to`: The destination L2 address
     // `uint256 l2CallValue`: The callvalue for retryable L2 message that is supplied within the deposit (l1CallValue)
     // `uint256 maxSubmissionCost`: The maximum amount of ETH to be paid for submitting the ticket. This amount is (1) supplied within the deposit (l1CallValue) to be later deducted from sender's L2 balance and is (2) directly proportional to the size of the retryable’s data and L1 basefee  
     // `address excessFeeRefundAddress`: The L2 address to which the excess fee is credited (l1CallValue - (autoredeem ? ticket execution cost : submission cost) - l2CallValue)
     // `address callValueRefundAddress`: The L2 address to which the l2CallValue is credited if the ticket times out or gets cancelled (this is also called the `beneficiary`, who's got a critical permission to cancel the ticket)
     // `uint256 gasLimit`: Maximum amount of gas used to cover L2 execution of the ticket
     // `uint256 maxFeePerGas`: The gas price bid for L2 execution of the ticket that is supplied within the deposit (l1CallValue)
     // `bytes calldata data`: The calldata to the destination L2 address
     function createRetryableTicket(
        address to,
        uint256 l2CallValue,
        uint256 maxSubmissionCost,
        address excessFeeRefundAddress,
        address callValueRefundAddress,
        uint256 gasLimit,
        uint256 maxFeePerGas,
        bytes calldata data
    ) external payable returns (uint256);
}

interface IZKMessenger {
    function requestL2Transaction(
        address _contractL2,
        uint256 _l2Value,
        bytes calldata _calldata,
        uint256 _l2GasLimit,
        uint256 _l2GasPerPubdataByteLimit,
        bytes[] calldata _factoryDeps,
        address _refundRecipient
    ) external payable returns (bytes32 canonicalTxHash);
}

// https://github.com/0xPolygonHermez/zkevm-contracts/blob/main/contracts/interfaces/IPolygonZkEVMBridge.sol
interface IPolyMessenger {
    // destinationNetwork   Network destination
    // destinationAddress	Address destination
    // forceUpdateGlobalExitRoot    Indicates if the new global exit root is updated or not
    // metadata	bytes   metadata
    function bridgeMessage(
        uint32 destinationNetwork,
        address destinationAddress,
        bool forceUpdateGlobalExitRoot,
        bytes calldata metadata
    ) external payable;
}

interface IScrollMessenger {
  /**********
   * Events *
   **********/

  /// @notice Emitted when a cross domain message is sent.
  /// @param sender The address of the sender who initiates the message.
  /// @param target The address of target contract to call.
  /// @param value The amount of value passed to the target contract.
  /// @param messageNonce The nonce of the message.
  /// @param gasLimit The optional gas limit passed to L1 or L2.
  /// @param message The calldata passed to the target contract.
  event SentMessage(
    address indexed sender,
    address indexed target,
    uint256 value,
    uint256 messageNonce,
    uint256 gasLimit,
    bytes message
  );

  /// @notice Emitted when a cross domain message is relayed successfully.
  /// @param messageHash The hash of the message.
  event RelayedMessage(bytes32 indexed messageHash);

  /// @notice Emitted when a cross domain message is failed to relay.
  /// @param messageHash The hash of the message.
  event FailedRelayedMessage(bytes32 indexed messageHash);

  /*************************
   * Public View Functions *
   *************************/

  /// @notice Return the sender of a cross domain message.
  function xDomainMessageSender() external view returns (address);

  /****************************
   * Public Mutated Functions *
   ****************************/

  /// @notice Send cross chain message from L1 to L2 or L2 to L1.
  /// @param target The address of account who recieve the message.
  /// @param value The amount of ether passed when call target contract.
  /// @param message The content of the message.
  /// @param gasLimit Gas limit required to complete the message relay on corresponding chain.
  function sendMessage(
    address target,
    uint256 value,
    bytes calldata message,
    uint256 gasLimit
  ) external payable;

  /// @notice Deposit ETH to some recipient's account in L2 and call the target contract.
  /// @param to The address of recipient's account on L2.
  /// @param amount The amount of ETH to be deposited.
  /// @param data Optional data to forward to recipient's account.
  /// @param gasLimit Gas limit required to complete the deposit on L2.
  function depositETHAndCall(
    address to,
    uint256 amount,
    bytes calldata data,
    uint256 gasLimit
  ) external payable;
}

// https://github.com/starkware-libs/cairo-lang/blob/54d7e92a703b3b5a1e07e9389608178129946efc/src/starkware/starknet/solidity/IStarknetMessaging.sol#L13
interface IStarknetMessenger {
    /**
      Sends a message to an L2 contract.
      This function is payable, the payed amount is the message fee.

      Returns the hash of the message and the nonce of the message.
    */
    function sendMessageToL2(
        uint256 toAddress,
        uint256 selector,
        uint256[] calldata payload
    ) external payable returns (bytes32, uint256);
}