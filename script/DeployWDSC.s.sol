// SPDX-Line-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {WDSCEngine} from "../src/WDSCEngine.sol";
import {WorldDecentralizedStableCoin} from "../src/WorldDecentralisedStableCoin.sol";

contract DeployWDSC is Script {
    address[] public tokenAddresses;
    address[] public priceFeedAddresses;

    function run() external returns (WorldDecentralizedStableCoin, WDSCEngine, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        (address wethUsdPriceFeed, address wbtcUsdPriceFeed, address weth, address wbtc, uint256 deployerKey) =
            helperConfig.activeNetworkConfig();
        tokenAddresses = [weth, wbtc];
        priceFeedAddresses = [wethUsdPriceFeed, wbtcUsdPriceFeed];

        vm.startBroadcast(deployerKey);
        WorldDecentralizedStableCoin wdsc = new WorldDecentralizedStableCoin();
        WDSCEngine wdscEngine = new WDSCEngine(tokenAddresses, priceFeedAddresses, address(wdsc));
        wdsc.transferOwnership(address(wdscEngine));
        vm.stopBroadcast();
        return (wdsc, wdscEngine, helperConfig);
    }
}
