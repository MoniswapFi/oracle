pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IPriceSource} from "./interfaces/IPriceSource.sol";
import {Numerals} from "./libraries/Numerals.sol";

abstract contract PriceSource is Ownable, IPriceSource {
    using Numerals for uint256;
    using Numerals for int256;
    using Math for uint256;

    string public name;
    address public usdt;
    address public usdc;
    address public dai;
    address public weth;

    constructor(string memory _name, address _usdt, address _usdc, address _dai, address _weth) Ownable(_msgSender()) {
        name = _name;
        usdt = _usdt;
        usdc = _usdc;
        dai = _dai;
        weth = _weth;
    }

    function _getUnitValueInETH(address _token) internal view virtual returns (uint256 _exponentiated, int256 _normal);
    function _getUnitValueInUSDT(address _token) internal view virtual returns (uint256 _exponentiated, int256 _normal);
    function _getUnitValueInUSDC(address _token) internal view virtual returns (uint256 _exponentiated, int256 _normal);
    function _getUnitValueInDAI(address _token) internal view virtual returns (uint256 _exponentiated, int256 _normal);

    function getUnitValueInAllStables(
        address _token
    )
        external
        view
        returns (
            uint256 _exponentiatedUSDTValue,
            int256 _normalUSDTValue,
            uint256 _exponentiatedUSDCValue,
            int256 _normalUSDCValue,
            uint256 _exponentiatedDAIValue,
            int256 _normalDAIValue
        )
    {
        (_exponentiatedUSDTValue, _normalUSDTValue) = _getUnitValueInUSDT(_token);
        (_exponentiatedUSDCValue, _normalUSDCValue) = _getUnitValueInUSDC(_token);
        (_exponentiatedDAIValue, _normalDAIValue) = _getUnitValueInDAI(_token);
    }

    function getAverageValueInUSD(
        address _token,
        uint256 _value
    ) public view returns (uint256 _avgExp, int256 _avgNormal) {
        (uint256 _usdtExp, ) = _getUnitValueInUSDT(_token);
        (uint256 _usdcExp, ) = _getUnitValueInUSDC(_token);

        uint8 _decimal = ERC20(_token).decimals();
        (, uint256 _usdtValue) = _usdtExp.tryMul(_value);
        (, uint256 _usdcValue) = _usdcExp.tryMul(_value);

        (, uint256 _sum) = _usdtValue.tryAdd(_usdcValue);
        (, _avgExp) = _usdtValue == 0 || _usdcValue == 0 ? _sum.tryDiv(1) : _sum.tryDiv(2);
        _avgExp = _avgExp / 10 ** _decimal;
        (, uint256 _avgNrm) = (_avgExp * 10 ** 4).tryDiv(10 ** 18);
        _avgNormal = _avgNrm.toInt256();
    }

    function getAverageValueInAllStables(
        address _token,
        uint256 _value
    ) external view returns (uint256 _avgExp, int256 _avgNormal) {
        (uint256 _avgExpUSD, ) = getAverageValueInUSD(_token, _value);
        (uint256 _daiExp, ) = _getUnitValueInDAI(_token);

        uint8 _decimal = ERC20(_token).decimals();
        (, uint256 _usdValue) = _avgExpUSD.tryMul(_value);
        (, uint256 _daiValue) = _daiExp.tryMul(_value);

        (, uint256 _sum) = _usdValue.tryAdd(_daiValue);
        (, _avgExp) = _usdValue == 0 || _daiValue == 0 ? _sum.tryDiv(1) : _sum.tryDiv(2);
        _avgExp = _avgExp / 10 ** _decimal;
        (, uint256 _avgNrm) = (_avgExp * 10 ** 4).tryDiv(10 ** 18);
        _avgNormal = _avgNrm.toInt256();
    }

    function getValueInETH(
        address _token,
        uint256 _value
    ) external view returns (uint256 _exponentiated, int256 _normal) {
        (uint256 _valueInETH, ) = _getUnitValueInETH(_token);
        uint8 _decimal = ERC20(_token).decimals();
        (, _exponentiated) = _valueInETH.tryMul(_value);
        _exponentiated = _exponentiated / 10 ** _decimal;
        (, uint256 _nrm) = (_exponentiated * 10 ** 4).tryDiv(10 ** 18);
        _normal = _nrm.toInt256();
    }
}
