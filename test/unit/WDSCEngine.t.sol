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

    function testGetTokenAmountFromUsd() public {
        uint256 usdAmount = 100 ether;
        uint256 expectedWeth = 0.05 ether;
        uint256 actualWeth = engine.getTokenAmountFromUsd(weth, usdAmount);
        assert(actualWeth == expectedWeth);
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

    function testRevertWithUnApprovedCollateral() public {
        ERC20Mock testToken = new ERC20Mock();
        vm.startPrank(USER);
        vm.expectRevert(WDSCEngine.WDSCEngine__TokenNotAllowed.selector);
        engine.depositCollateral(address(testToken), AMOUNT_COLLATERAL);
        vm.stopPrank();
    }

    modifier depositCollateral() {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(engine), AMOUNT_COLLATERAL);
        engine.depositCollateral(weth, AMOUNT_COLLATERAL);
        vm.stopPrank();
        _;
    }

    function testCanDepositAndGetAccountInfo() public depositCollateral {
        (uint256 totalWdscMinted, uint256 collateralValueInUsd) = engine.getAccountInformation(USER);
        uint256 expectedTotalWdscMinted = 0;
        uint256 expectedDepositAmount = engine.getTokenAmountFromUsd(weth, collateralValueInUsd);
        console.log("expectedDepositAmount: ", expectedDepositAmount);
        console.log("collateralValueInUsd: ", collateralValueInUsd);
        assert(totalWdscMinted == expectedTotalWdscMinted);
        assert(AMOUNT_COLLATERAL == expectedDepositAmount);
    }

    function testMint() public depositCollateral {
        vm.startPrank(USER);
        engine.mintWdsc(100);
        vm.stopPrank();
        (uint256 totalWdscMinted, uint256 collateralValueInUsd) = engine.getAccountInformation(USER);
        uint256 expectedTotalWdscMinted = 100;
        uint256 expectedDepositAmount = engine.getTokenAmountFromUsd(weth, collateralValueInUsd);
        console.log("expectedDepositAmount: ", expectedDepositAmount);
        console.log("collateralValueInUsd: ", collateralValueInUsd);
        assert(totalWdscMinted == expectedTotalWdscMinted);
        assert(AMOUNT_COLLATERAL == expectedDepositAmount);
    }

    function testDepositCollateralAndMintWdsc() public {
        vm.startPrank(USER);
        uint256 amountWdscToMint = 1000000;
        ERC20Mock(weth).approve(address(engine), AMOUNT_COLLATERAL);
        engine.depositCollateralAndMintWdsc(weth, AMOUNT_COLLATERAL, amountWdscToMint);
        vm.stopPrank();
        uint256 totalWdscMinted = engine.getMintedWdsc(USER);
        console.log("totalWdscMinted: ", totalWdscMinted);
        assert(totalWdscMinted == amountWdscToMint);
    }

    function testMintBrokenHealthFactor() public {
        vm.startPrank(USER);
        uint256 amountWdscToMint = 100e18;
        uint256 amountOfCollateral = 0.005 ether;
        ERC20Mock(weth).approve(address(engine), amountOfCollateral);
        engine.depositCollateralAndMintWdsc(weth, amountOfCollateral, amountWdscToMint);
        uint256 totalWdscMinted = engine.getMintedWdsc(USER);
        console.log("totalWdscMinted: ", totalWdscMinted);
        assert(totalWdscMinted == amountWdscToMint);
        vm.stopPrank();
    }

    function testReedemCollateral() public {
        uint256 amountWdscToMint = 100;
        uint256 amountOfCollateral = 10000;
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(engine), amountOfCollateral);
        engine.depositCollateralAndMintWdsc(weth, amountOfCollateral, amountWdscToMint);
        wdsc.approve(address(engine), amountWdscToMint);
        vm.expectRevert(WDSCEngine.WDSCEngine__BreaksHealthFactor.selector);
        engine.reedemCollateralForWdsc(weth, amountOfCollateral, amountWdscToMint);
        vm.stopPrank();
        uint256 tokenToBeRedeemed = engine.getRedeemedCollateral(USER, weth);
        // uint256 redeemtolateral = engine.getRedeemedCollateral(USER, weth);
        // console.log("redeem colateral: ", redeemtolateral);
        uint256 bal = ERC20Mock(weth).balanceOf(USER);
        console.log("redeem colateral: ", bal);
        console.log("amount of collateral: ", engine.getMintedWdsc(USER));
    }
}
