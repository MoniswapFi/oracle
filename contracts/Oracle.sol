pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IPriceSource} from "./interfaces/IPriceSource.sol";

contract Oracle is Ownable {
    error UnrecognizedPriceSource();

    IPriceSource[] public priceSources;

    constructor(IPriceSource[] memory _priceSources) Ownable(_msgSender()) {
        setPriceSources(_priceSources);
    }

    function _checkPriceSource(IPriceSource _priceSource) internal view {
        bool isRecognizedPriceSource;

        for (uint i = 0; i < priceSources.length; i++) {
            IPriceSource pS = priceSources[i];

            if (pS == _priceSource) {
                isRecognizedPriceSource = true;
                break;
            }
        }

        if (!isRecognizedPriceSource) revert UnrecognizedPriceSource();
    }

    function setPriceSources(IPriceSource[] memory _priceSources) public onlyOwner {
        priceSources = _priceSources;
    }

    function getAllPriceSources() external view returns (IPriceSource[] memory) {
        return priceSources;
    }

    function getAverageValueInUSD(address _token, uint256 _value) external view returns (uint256, int256) {
        uint256 _totalValueEXP;
        int256 _totalValueNormal;

        for (uint i = 0; i < priceSources.length; i++) {
            IPriceSource pS = priceSources[i];
            (uint256 _valueEXP, int256 _valueNormal) = pS.getAverageValueInUSD(_token, _value);
            (_totalValueEXP, _totalValueNormal) = (_totalValueEXP + _valueEXP, _totalValueNormal + _valueNormal);
        }

        return (_totalValueEXP / priceSources.length, _totalValueNormal / int256(priceSources.length));
    }

    function getAverageValueInAllStables(address _token, uint256 _value) external view returns (uint256, int256) {
        uint256 _totalValueEXP;
        int256 _totalValueNormal;

        for (uint i = 0; i < priceSources.length; i++) {
            IPriceSource pS = priceSources[i];
            (uint256 _valueEXP, int256 _valueNormal) = pS.getAverageValueInAllStables(_token, _value);
            (_totalValueEXP, _totalValueNormal) = (_totalValueEXP + _valueEXP, _totalValueNormal + _valueNormal);
        }

        return (_totalValueEXP / priceSources.length, _totalValueNormal / int256(priceSources.length));
    }

    function getAverageValueInETH(address _token, uint256 _value) external view returns (uint256, int256) {
        uint256 _totalValueEXP;
        int256 _totalValueNormal;

        for (uint i = 0; i < priceSources.length; i++) {
            IPriceSource pS = priceSources[i];
            (uint256 _valueEXP, int256 _valueNormal) = pS.getValueInETH(_token, _value);
            (_totalValueEXP, _totalValueNormal) = (_totalValueEXP + _valueEXP, _totalValueNormal + _valueNormal);
        }

        return (_totalValueEXP / priceSources.length, _totalValueNormal / int256(priceSources.length));
    }
}
