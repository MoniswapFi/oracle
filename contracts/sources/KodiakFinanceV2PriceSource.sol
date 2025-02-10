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

    bytes4 public constant getPoolSelector = bytes4(keccak256(bytes("getPair(address,address)")));
    bytes4 public constant getReservesSelector = bytes4(keccak256(bytes("getReserves()")));

    constructor(
        address _factory,
        address _usdt,
        address _usdc,
        address _weth
    ) PriceSource("Kodiak Finance V2", _usdt, _usdc, _weth) {
        factory = _factory;
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
        if (token0 == weth && token1 == weth) return 1 ether;
        if (token0 == token1) return _amountIn;

        (address tokenA, ) = sortTokens(token0, token1);
        address pool = _getPool(token0, token1);

        if (pool != address(0)) {
            bytes memory _reservesData = pool.functionStaticCall(abi.encodeWithSelector(getReservesSelector));

            (uint256 reserve0, uint256 reserve1) = abi.decode(_reservesData, (uint256, uint256));

            if (reserve0 == 0 || reserve1 == 0) amountOut = 0;
            else {
                (uint256 reserveA, uint256 reserveB) = token0 == tokenA ? (reserve0, reserve1) : (reserve1, reserve0);
                uint256 amountInWithFee = _amountIn * (1000 - 25);
                uint256 numerator = amountInWithFee * reserveB;
                uint256 denominator = (reserveA * 1000) + amountInWithFee;
                amountOut = numerator / denominator;
            }
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

    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    }
}
