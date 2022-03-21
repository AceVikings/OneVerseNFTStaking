//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./EIP712.sol";

contract PriceSigner is EIP712{

    string private constant SIGNING_DOMAIN = "OneVerse-Price";
    string private constant SIGNATURE_VERSION = "1";

    struct Price{
        uint price;
        uint time;
        bytes signature;
    }

    constructor() EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION){
        
    }

    function getSigner(Price memory result) public view returns(address){
        return _verify(result);
    }
  
    function _hash(Price memory result) internal view returns (bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(
        keccak256("Price(uint256 price,uint256 time)"),
        result.price,
        result.time
        )));
    }

    function _verify(Price memory result) internal view returns (address) {
        bytes32 digest = _hash(result);
        return ECDSA.recover(digest, result.signature);
    }

}