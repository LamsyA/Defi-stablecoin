// SPDX-Lincense-Identifier: MIT

pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {WDSCEngine} from "../../src/WDSCEngine.sol";
import {WorldDecentralizedStableCoin} from "../../src/WorldDecentralisedStableCoin.sol";
import {DeployWDSC} from "../../script/DeployWDSC.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract WDSCEngineTest is Test {
    DeployWDSC deployer;
    WorldDecentralizedStableCoin wdsc;
    WDSCEngine engine;
    HelperConfig config;
    address weth;
    address wbtc;
    address ethUsdPriceFeed;
    address btcUsdPriceFeed;
    address public USER = makeAddr("USER");
    uint256 public constant AMOUNT_COLLATERAL = 10 ether;
    uint256 public constant STARTING_USER_BALANCE = 10 ether;
    address[] public tokenAddress;
    address[] public priceFeedAddress;

    function setUp() public {
        deployer = new DeployWDSC();
        (wdsc, engine, config) = deployer.run();
        (ethUsdPriceFeed, btcUsdPriceFeed, weth, wbtc,) = config.activeNetworkConfig();
        ERC20Mock(weth).mint(USER, STARTING_USER_BALANCE);
        ERC20Mock(wbtc).mint(USER, STARTING_USER_BALANCE);
    }

    function testRevertIfTokenAddressLengthDoessNotMatchPriceFeeds() public {
        tokenAddress.push(weth);
        priceFeedAddress.push(btcUsdPriceFeed);
        priceFeedAddress.push(ethUsdPriceFeed);
        vm.expectRevert(WDSCEngine.WDSCEngine__TokenAddressesAndPricesFeedAddressMustBeEqualLength.selector);

        new WDSCEngine(tokenAddress, priceFeedAddress, address(wdsc));
    }

    function testGetUsdValue() public {
        uint256 ethAmount = 15e18;
        uint256 expectedUsd = 30000e18;
        uint256 ethUsdValue = engine.getUsdValue(weth, ethAmount);
        console.log("ethUsdValue: ", ethUsdValue);
        assert(ethUsdValue == expectedUsd);
    }

    ///////////////////////////////////
    /////// Deposit Collateral ///////
    ///////////////////////////////////

    function testDepositCollateral() public {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(engine), AMOUNT_COLLATERAL);

        vm.expectRevert(WDSCEngine.WDSCEngine__NeedsMorethanZero.selector);
        engine.depositCollateral(weth, 0);
        vm.stopPrank();
    }
}
