pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IPriceSource} from "./interfaces/IPriceSource.sol";

contract Oracle is Ownable {
    error UnrecognizedPriceSource();

    IPriceSource[] public priceSources;

    event SetPriceSources(IPriceSource[] priceSources);

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
        emit SetPriceSources(_priceSources);
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

    function getAverageValueInUSDBySource(
        IPriceSource _pS,
        address _token,
        uint256 _value
    ) external view returns (uint256 _avgEXP, int256 _avgNormal) {
        _checkPriceSource(_pS);
        (_avgEXP, _avgNormal) = _pS.getAverageValueInUSD(_token, _value);
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

    function getAverageValueInAllStablesBySource(
        IPriceSource _pS,
        address _token,
        uint256 _value
    ) external view returns (uint256 _avgEXP, int256 _avgNormal) {
        _checkPriceSource(_pS);
        (_avgEXP, _avgNormal) = _pS.getAverageValueInAllStables(_token, _value);
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

    function getValueInETH(
        IPriceSource _pS,
        address _token,
        uint256 _value
    ) external view returns (uint256 _avgEXP, int256 _avgNormal) {
        _checkPriceSource(_pS);
        (_avgEXP, _avgNormal) = _pS.getValueInETH(_token, _value);
    }

    struct UnitValueInStablesPerSource {
        address _sourceAddress;
        string _sourceName;
        uint256 _exponentiatedUSDTValue;
        int256 _normalUSDTValue;
        uint256 _exponentiatedUSDCValue;
        int256 _normalUSDCValue;
        uint256 _exponentiatedDAIValue;
        int256 _normalDAIValue;
    }

    function getUnitValueInAllStables(address _token) external view returns (UnitValueInStablesPerSource[] memory) {
        UnitValueInStablesPerSource[] memory _values = new UnitValueInStablesPerSource[](priceSources.length);

        for (uint i = 0; i < priceSources.length; i++) {
            IPriceSource pS = priceSources[i];
            (
                uint256 _exponentiatedUSDTValue,
                int256 _normalUSDTValue,
                uint256 _exponentiatedUSDCValue,
                int256 _normalUSDCValue,
                uint256 _exponentiatedDAIValue,
                int256 _normalDAIValue
            ) = pS.getUnitValueInAllStables(_token);

            _values[i] = UnitValueInStablesPerSource(
                address(pS),
                pS.name(),
                _exponentiatedUSDTValue,
                _normalUSDTValue,
                _exponentiatedUSDCValue,
                _normalUSDCValue,
                _exponentiatedDAIValue,
                _normalDAIValue
            );
        }

        return _values;
    }

    function getUnitValueInAllStablesBySource(
        IPriceSource _pS,
        address _token
    ) external view returns (UnitValueInStablesPerSource memory _values) {
        _checkPriceSource(_pS);
        (
            uint256 _exponentiatedUSDTValue,
            int256 _normalUSDTValue,
            uint256 _exponentiatedUSDCValue,
            int256 _normalUSDCValue,
            uint256 _exponentiatedDAIValue,
            int256 _normalDAIValue
        ) = _pS.getUnitValueInAllStables(_token);

        _values = UnitValueInStablesPerSource(
            address(_pS),
            _pS.name(),
            _exponentiatedUSDTValue,
            _normalUSDTValue,
            _exponentiatedUSDCValue,
            _normalUSDCValue,
            _exponentiatedDAIValue,
            _normalDAIValue
        );
    }
}
