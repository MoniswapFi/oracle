pragma solidity ^0.8.0;

library Numerals {
    error Overflow();
    error Underflow();

    function toInt256(uint256 _x) internal pure returns (int256 _y) {
        if (_x > uint256(type(int256).max)) revert Overflow();
        _y = int256(_x);
    }

    function toUint256(int256 _x) internal pure returns (uint256 _y) {
        if (_x < 0) revert Underflow();
        _y = uint256(_x);
    }
}
