// SPDX-Lincense-Identifier: MIT

pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {WDSCEngine} from "../../src/WDSCEngine.sol";
import {WorldDecentralizedStableCoin} from "../../src/WorldDecentralisedStableCoin.sol";
import {DeployWDSC} from "../../script/DeployWDSC.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract WDSCEngineTest is Test {
    DeployWDSC deployer;
    WorldDecentralizedStableCoin wdsc;
    WDSCEngine engine;
    HelperConfig config;
    address weth;
    address ethUsdPriceFeed;

    function setUp() public {
        deployer = new DeployWDSC();
        (wdsc, engine, config) = deployer.run();
        (ethUsdPriceFeed,, weth,,) = config.activeNetworkConfig();
    }

    function testGetUsdValue() public {
        uint256 ethAmount = 15e18;
        uint256 expectedUsd = 30000e18;
        uint256 ethUsdValue = engine.getUsdValue(weth, ethAmount);
        console.log("ethUsdValue: ", ethUsdValue);
        assert(ethUsdValue == expectedUsd);
    }

    function testDepositCollateral() public {
        vm.prank;
    }
}
