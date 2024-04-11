// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {WorldDecentralizedStableCoin} from "./WorldDecentralisedStableCoin.sol";

contract WDSCEngine {
    //////////////////////
    ///     ERRORS    ///
    ////////////////////
    error WDSCEngine_NeedsMorethanZero();
    error WDSCEngine_TokenAddressesAndPricesFeedAddressMustBeEqualLength();

    //////////////////////////
    /// State Variables   ///
    ////////////////////////

    mapping(address token => address priceFeed) private s_priceFeeds;
    WorldDecentralizedStableCoin private immutable s_wdsc;
    /*
     * @param tokenCollateralAddress - address of the token collateral
     * @param _amountCollateral - amount of token collateral
     *
     */

    //////////////////////
    ///     Modifiers    ///
    ////////////////////

    modifier moreThanZero(uint256 _amountCollateral) {
        if (_amountCollateral == 0) {
            revert WDSCEngine_NeedsMorethanZero();
        }
        _;
    }

    constructor(
        address _tokenAddress,
        address _priceFeedAddresses,
        address wdscAddress
    ) {
        if (_tokenAddress.length != _priceFeedAddresses.length) {
            revert WDSCEngine_TokenAddressesAndPricesFeedAddressMustBeEqualLength();
        }

        for (uint256 i = 0; i < _tokenAddress.length; i++) {
            s_priceFeeds[_tokenAddress[i]] = _priceFeedAddresses[i];
        }
        s_wdsc = WorldDecentralizedStableCoin(wdscAddress);
    }

    //////////////////////
    ///     Functions    ///
    ////////////////////
    function depositCollateral(
        address tokenCollateralAddress,
        uint256 _amountCollateral
    ) external payable moreThanZero(_amountCollateral) {}
}
