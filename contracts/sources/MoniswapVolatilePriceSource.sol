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
        address _dai,
        address _weth
    ) PriceSource("Moniswap", _usdt, _usdc, _dai, _weth) {
        factory = _factory;
    }

    function _getPool(address token0, address token1) internal view returns (address _poolAddress) {
        bytes memory _returnData = factory.functionStaticCall(
            abi.encodeWithSelector(getPoolSelector, token0, token1, false)
        );
        _poolAddress = abi.decode(_returnData, (address));
    }

    function _getUnitValueInETH(address token) internal view override returns (uint256, int256) {
        address pool = _getPool(token, weth);

        if (pool == address(0)) {
            return (0, 0);
        }

        uint8 _decimals = ERC20(token).decimals();
        uint256 _amountIn = 1 * 10 ** _decimals;
        bytes memory _returnData = pool.functionStaticCall(
            abi.encodeWithSelector(getAmountOutSelector, _amountIn, token)
        );

        uint256 amountOut = abi.decode(_returnData, (uint256));
        uint256 amountOutEXP4 = amountOut * 10 ** 4;
        (, uint256 amountOutNormal) = amountOutEXP4.tryDiv(10 ** 18);

        return (amountOut, amountOutNormal.toInt256());
    }

    function _getUnitValueInUSDC(address token) internal view override returns (uint256, int256) {
        (uint256 _valueInETH, ) = _getUnitValueInETH(token);
        address _ethUSDCPool = _getPool(weth, usdc);

        if (_valueInETH > 0 && _ethUSDCPool != address(0)) {
            bytes memory _returnData = _ethUSDCPool.functionStaticCall(
                abi.encodeWithSelector(getAmountOutSelector, _valueInETH, weth)
            );
            uint256 amountOut = abi.decode(_returnData, (uint256));
            uint8 _decimals = ERC20(usdc).decimals();
            uint256 amountOutEXP4 = amountOut * 10 ** 4;
            (, uint256 amountOutNormal) = amountOutEXP4.tryDiv(10 ** _decimals);
            return (amountOut, amountOutNormal.toInt256());
        } else {
            address pool = _getPool(token, usdc);

            if (pool == address(0)) {
                return (0, 0);
            }

            uint8 _decimals = ERC20(token).decimals();
            uint8 _usdcDecimals = ERC20(usdc).decimals();
            uint256 _amountIn = 1 * 10 ** _decimals;
            bytes memory _returnData = pool.functionStaticCall(
                abi.encodeWithSelector(getAmountOutSelector, _amountIn, token)
            );

            uint256 amountOut = abi.decode(_returnData, (uint256));
            uint256 amountOutEXP4 = amountOut * 10 ** 4;
            (, uint256 amountOutNormal) = amountOutEXP4.tryDiv(10 ** _usdcDecimals);

            return (amountOut, amountOutNormal.toInt256());
        }
    }

    function _getUnitValueInUSDT(address token) internal view override returns (uint256, int256) {
        (uint256 _valueInETH, ) = _getUnitValueInETH(token);
        address _ethUSDTPool = _getPool(weth, usdt);

        if (_valueInETH > 0 && _ethUSDTPool != address(0)) {
            bytes memory _returnData = _ethUSDTPool.functionStaticCall(
                abi.encodeWithSelector(getAmountOutSelector, _valueInETH, weth)
            );
            uint256 amountOut = abi.decode(_returnData, (uint256));
            uint8 _decimals = ERC20(usdt).decimals();
            uint256 amountOutEXP4 = amountOut * 10 ** 4;
            (, uint256 amountOutNormal) = amountOutEXP4.tryDiv(10 ** _decimals);
            return (amountOut, amountOutNormal.toInt256());
        } else {
            address pool = _getPool(token, usdt);

            if (pool == address(0)) {
                return (0, 0);
            }

            uint8 _decimals = ERC20(token).decimals();
            uint8 _usdtDecimals = ERC20(usdt).decimals();
            uint256 _amountIn = 1 * 10 ** _decimals;
            bytes memory _returnData = pool.functionStaticCall(
                abi.encodeWithSelector(getAmountOutSelector, _amountIn, token)
            );

            uint256 amountOut = abi.decode(_returnData, (uint256));
            uint256 amountOutEXP4 = amountOut * 10 ** 4;
            (, uint256 amountOutNormal) = amountOutEXP4.tryDiv(10 ** _usdtDecimals);

            return (amountOut, amountOutNormal.toInt256());
        }
    }

    function _getUnitValueInDAI(address token) internal view override returns (uint256, int256) {
        (uint256 _valueInETH, ) = _getUnitValueInETH(token);
        address _ethDAIPool = _getPool(weth, dai);

        if (_valueInETH > 0 && _ethDAIPool != address(0)) {
            bytes memory _returnData = _ethDAIPool.functionStaticCall(
                abi.encodeWithSelector(getAmountOutSelector, _valueInETH, weth)
            );
            uint256 amountOut = abi.decode(_returnData, (uint256));
            uint8 _decimals = ERC20(dai).decimals();
            uint256 amountOutEXP4 = amountOut * 10 ** 4;
            (, uint256 amountOutNormal) = amountOutEXP4.tryDiv(10 ** _decimals);
            return (amountOut, amountOutNormal.toInt256());
        } else {
            address pool = _getPool(token, dai);

            if (pool == address(0)) {
                return (0, 0);
            }

            uint8 _decimals = ERC20(token).decimals();
            uint8 _daiDecimals = ERC20(dai).decimals();
            uint256 _amountIn = 1 * 10 ** _decimals;
            bytes memory _returnData = pool.functionStaticCall(
                abi.encodeWithSelector(getAmountOutSelector, _amountIn, token)
            );

            uint256 amountOut = abi.decode(_returnData, (uint256));
            uint256 amountOutEXP4 = amountOut * 10 ** 4;
            (, uint256 amountOutNormal) = amountOutEXP4.tryDiv(10 ** _daiDecimals);

            return (amountOut, amountOutNormal.toInt256());
        }
    }
}
