//SPDX-License-Identifier: MIT
pragma solidity >=0.8.17 <0.9.0;

interface IPriceOracle {
    struct Price {
        uint256 base;
        uint256 premium;
    }

    /**
     * @dev Returns the price to register or renew a name.
     * @param name The name being registered or renewed.
     * @param expires When the name presently expires (`launchTime` if this is a new registration).
     * @param duration How long the name is being registered or extended for, in seconds.
     * @return price Price struct containing base price and premium price
     */
    function price(string calldata name, uint256 expires, uint256 duration) external view returns (Price calldata);
}
