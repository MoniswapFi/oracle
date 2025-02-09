pragma solidity ^0.8.0;

import {PriceSource} from "../PriceSource.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {Numerals} from "../libraries/Numerals.sol";

contract KodiakFinanceV2PriceSource is PriceSource {
    using Address for address;
    using Numerals for uint256;
    using Numerals for int256;
    using Math for uint256;

    address public immutable factory;
    address public immutable router;

    bytes4 public constant getPoolSelector = bytes4(keccak256(bytes("getPair(address,address)")));
    bytes4 public constant getAmountOutSelector = bytes4(keccak256("getAmountsOut(uint,address[])"));

    constructor(
        address _factory,
        address _router,
        address _usdt,
        address _usdc,
        address _weth
    ) PriceSource("Kodiak Finance V2", _usdt, _usdc, _weth) {
        factory = _factory;
        router = _router;
    }

    function _getPool(address token0, address token1) internal view returns (address _poolAddress) {
        bytes memory _returnData = factory.functionStaticCall(abi.encodeWithSelector(getPoolSelector, token0, token1));
        _poolAddress = abi.decode(_returnData, (address));
    }

    function _deriveAmountOut(
        address token0,
        address token1,
        uint256 _amountIn
    ) internal view returns (uint256 amountOut) {
        address pool = _getPool(token0, token1);

        if (pool != address(0)) {
            address[] memory path;
            path[0] = token0;
            path[1] = token1;

            bytes memory _returnData = router.functionStaticCall(
                abi.encodeWithSelector(getAmountOutSelector, _amountIn, path)
            );

            uint256[] memory amountsOut = abi.decode(_returnData, (uint256[]));
            amountOut = amountsOut[amountsOut.length - 1];
        }
    }

    function _getUnitValueInETH(address token) internal view override returns (uint256, int256) {
        uint8 _decimals = ERC20(token).decimals();
        uint256 _amountIn = 1 * 10 ** _decimals;
        uint256 amountOut = _deriveAmountOut(token, weth, _amountIn);
        uint256 amountOutEXP4 = amountOut * 10 ** 4;
        (, uint256 amountOutNormal) = amountOutEXP4.tryDiv(10 ** 18);

        return (amountOut, amountOutNormal.toInt256());
    }

    function _getUnitValueInUSDC(address token) internal view override returns (uint256, int256) {
        (uint256 _valueInETH, ) = _getUnitValueInETH(token);
        uint256 _ethUSDCAmountOut = _deriveAmountOut(weth, usdc, _valueInETH);
        uint8 _usdcDecimals = ERC20(usdc).decimals();
        _ethUSDCAmountOut = (_ethUSDCAmountOut * 10 ** 18) / 10 ** _usdcDecimals;

        if (_valueInETH > 0 && _ethUSDCAmountOut > 0) {
            uint256 amountOutEXP4 = _ethUSDCAmountOut * 10 ** 4;
            (, uint256 amountOutNormal) = amountOutEXP4.tryDiv(10 ** 18);
            return (_ethUSDCAmountOut, amountOutNormal.toInt256());
        } else {
            uint8 _tokenDecimals = ERC20(token).decimals();
            uint256 _amountIn = 1 * 10 ** _tokenDecimals;
            uint256 amountOut = _deriveAmountOut(token, usdc, _amountIn);
            amountOut = (amountOut * 10 ** 18) / 10 ** _usdcDecimals;
            uint256 amountOutEXP4 = amountOut * 10 ** 4;
            (, uint256 amountOutNormal) = amountOutEXP4.tryDiv(10 ** 18);

            return (amountOut, amountOutNormal.toInt256());
        }
    }

    function _getUnitValueInUSDT(address token) internal view override returns (uint256, int256) {
        (uint256 _valueInETH, ) = _getUnitValueInETH(token);
        uint256 _ethUSDTAmountOut = _deriveAmountOut(weth, usdt, _valueInETH);
        uint8 _usdtDecimals = ERC20(usdt).decimals();
        _ethUSDTAmountOut = (_ethUSDTAmountOut * 10 ** 18) / 10 ** _usdtDecimals;

        if (_valueInETH > 0 && _ethUSDTAmountOut > 0) {
            uint256 amountOutEXP4 = _ethUSDTAmountOut * 10 ** 4;
            (, uint256 amountOutNormal) = amountOutEXP4.tryDiv(10 ** 18);
            return (_ethUSDTAmountOut, amountOutNormal.toInt256());
        } else {
            uint8 _tokenDecimals = ERC20(token).decimals();
            uint256 _amountIn = 1 * 10 ** _tokenDecimals;
            uint256 amountOut = _deriveAmountOut(token, usdt, _amountIn);
            amountOut = (amountOut * 10 ** 18) / 10 ** _usdtDecimals;
            uint256 amountOutEXP4 = amountOut * 10 ** 4;
            (, uint256 amountOutNormal) = amountOutEXP4.tryDiv(10 ** 18);

            return (amountOut, amountOutNormal.toInt256());
        }
    }
}
