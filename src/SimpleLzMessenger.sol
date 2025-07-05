// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {OApp, Origin, MessagingFee} from "@layerzerolabs/oapp-evm/contracts/oapp/OApp.sol";
import {OAppOptionsType3} from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OAppOptionsType3.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract SimpleLzMessenger is OApp, OAppOptionsType3 {
    // Global variable to store received bytes
    bytes public lastReceivedBytes;

    // Event for tracking
    event BytesSent(uint32 indexed dstEid, bytes data);
    event BytesReceived(uint32 indexed srcEid, bytes data);

    constructor(
        address _endpoint,
        address _owner
    ) OApp(_endpoint, _owner) Ownable(_owner) {}

    // Send bytes to another chain
    function sendBytes(uint32 _dstEid, bytes calldata _data) external payable {
        _lzSend(
            _dstEid,
            _data,
            "", // no options
            MessagingFee(msg.value, 0),
            payable(msg.sender)
        );
        emit BytesSent(_dstEid, _data);
    }

    // Quote the cost
    function quoteSendBytes(
        uint32 _dstEid,
        bytes calldata _data
    ) external view returns (MessagingFee memory fee) {
        return _quote(_dstEid, _data, "", false);
    }

    // Receive bytes from another chain
    function _lzReceive(
        Origin calldata _origin,
        bytes32 /*_guid*/,
        bytes calldata _message,
        address /*_executor*/,
        bytes calldata /*_extraData*/
    ) internal override {
        lastReceivedBytes = _message;
        emit BytesReceived(_origin.srcEid, _message);
    }

    // Get the last received bytes
    function getLastReceivedBytes() external view returns (bytes memory) {
        return lastReceivedBytes;
    }
}
