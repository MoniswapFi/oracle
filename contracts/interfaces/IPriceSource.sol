pragma solidity ^0.8.0;

interface IPriceSource {
    function name() external view returns (string memory);
    function usdt() external view returns (address);
    function usdc() external view returns (address);
    function dai() external view returns (address);
    function weth() external view returns (address);

    function getAverageValueInUSD(
        address _token,
        uint256 _value
    ) external view returns (uint256 _exponentiated, int256 _normal);
    function getAverageValueInAllStables(
        address _token,
        uint256 _value
    ) external view returns (uint256 _exponentiated, int256 _normal);
    function getValueInETH(
        address _token,
        uint256 _value
    ) external view returns (uint256 _exponentiated, int256 _normal);
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
        );
}
