pragma solidity ^0.8.0;

import {PriceSource} from "../PriceSource.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {Numerals} from "../libraries/Numerals.sol";

contract MoniswapVolatilePriceSource is PriceSource {
    using Address for address;
    using Numerals for uint256;
    using Numerals for int256;
    using Math for uint256;

    address public immutable factory;

    bytes4 public constant getPoolSelector = bytes4(keccak256(bytes("getPool(address,address,bool)")));
    bytes4 public constant getAmountOutSelector = bytes4(keccak256("getAmountOut(uint256,address)"));

    constructor(
        address _factory,
        address _usdt,
        address _usdc,
        address _weth
    ) PriceSource("Moniswap", _usdt, _usdc, _weth) {
        factory = _factory;
    }

    function _getPool(address token0, address token1) internal view returns (address _poolAddress) {
        bytes memory _returnData = factory.functionStaticCall(
            abi.encodeWithSelector(getPoolSelector, token0, token1, false)
        );
        _poolAddress = abi.decode(_returnData, (address));
    }

    function _deriveAmountOut(
        address token0,
        address token1,
        uint256 _amountIn
    ) internal view returns (uint256 amountOut) {
        address pool = _getPool(token0, token1);

        if (pool != address(0)) {
            bytes memory _returnData = pool.functionStaticCall(
                abi.encodeWithSelector(getAmountOutSelector, _amountIn, token0)
            );

            amountOut = abi.decode(_returnData, (uint256));
        }
    }

    function _getUnitValueInETH(address token) internal view override returns (uint256 amountOut) {
        uint8 _decimals = ERC20(token).decimals();
        uint256 _amountIn = 1 * 10 ** _decimals;
        amountOut = _deriveAmountOut(token, weth, _amountIn);
    }

    function _getUnitValueInUSDC(address token) internal view override returns (uint256) {
        uint256 _valueInETH = _getUnitValueInETH(token);
        uint256 _ethUSDCAmountOut = _deriveAmountOut(weth, usdc, _valueInETH);

        if (_ethUSDCAmountOut > 0) {
            return _ethUSDCAmountOut;
        } else {
            uint8 _tokenDecimals = ERC20(token).decimals();
            uint256 _amountIn = 1 * 10 ** _tokenDecimals;
            uint256 amountOut = _deriveAmountOut(token, usdc, _amountIn);
            return amountOut;
        }
    }

    function _getUnitValueInUSDT(address token) internal view override returns (uint256) {
        uint256 _valueInETH = _getUnitValueInETH(token);
        uint256 _ethUSDTAmountOut = _deriveAmountOut(weth, usdt, _valueInETH);

        if (_ethUSDTAmountOut > 0) {
            return _ethUSDTAmountOut;
        } else {
            uint8 _tokenDecimals = ERC20(token).decimals();
            uint256 _amountIn = 1 * 10 ** _tokenDecimals;
            uint256 amountOut = _deriveAmountOut(token, usdt, _amountIn);
            return amountOut;
        }
    }
}
