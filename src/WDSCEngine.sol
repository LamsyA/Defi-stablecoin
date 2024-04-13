// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {WorldDecentralizedStableCoin} from "./WorldDecentralisedStableCoin.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract WDSCEngine is ReentrancyGuard {
    //////////////////////
    ///     ERRORS    ///
    ////////////////////
    error WDSCEngine__NeedsMorethanZero();
    error WDSCEngine__TokenAddressesAndPricesFeedAddressMustBeEqualLength();
    error WDSCEngine__TokenNotAllowed();
    error WDSCEngine__TransferFailed();
    error WDSCEngine__BreaksHealthFactor(uint256);
    error WDSCEngine__MintingFailed();

    //////////////////////////
    /// State Variables   ///
    ////////////////////////
    uint256 private constant FEED_PRECISON = 1e10;
    uint256 private constant PRECISION = 1e18;
    uint256 private constant LIQUIDATION_THRESHOLD = 50;
    uint256 private constant LIQUIDATION_PRECISION = 100;
    uint256 private constant MIN_HEALTH_FACTOR = 1;
    mapping(address token => address priceFeed) private s_priceFeeds;
    mapping(address user => mapping(address token => uint256)) private s_collateralDeposited;
    mapping(address user => uint256 amountDscMinted) private s_WdscMinted;
    address[] private s_Colateraltokens;
    WorldDecentralizedStableCoin private immutable s_wdsc;

    //////////////////////////
    ////     Events        ///
    /////////////////////////
    event CollateralDeposited(address indexed user, address indexed token, uint256 indexed amount);
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
            revert WDSCEngine__NeedsMorethanZero();
        }
        _;
    }

    modifier isAlloweToken(address token) {
        if (s_priceFeeds[token] == address(0)) {
            revert WDSCEngine__TokenNotAllowed();
        }
        _;
    }

    constructor(address[] memory _tokenAddress, address[] memory _priceFeedAddresses, address wdscAddress) {
        if (_tokenAddress.length != _priceFeedAddresses.length) {
            revert WDSCEngine__TokenAddressesAndPricesFeedAddressMustBeEqualLength();
        }

        for (uint256 i = 0; i < _tokenAddress.length; i++) {
            s_priceFeeds[_tokenAddress[i]] = _priceFeedAddresses[i];
            s_Colateraltokens.push(_tokenAddress[i]);
        }
        s_wdsc = WorldDecentralizedStableCoin(wdscAddress);
    }

    //////////////////////////////
    ///   External  Functions ///
    ////////////////////////////

    function depositCollateralAndMintWdsc(
        address tokenCollateralAddress,
        uint256 amountCollateral,
        uint256 amountWdscToMint
    ) external {
        depositCollateral(tokenCollateralAddress, amountCollateral);
        mintWdsc(amountWdscToMint);
    }

    function depositCollateral(address tokenCollateralAddress, uint256 amountCollateral)
        public
        moreThanZero(amountCollateral)
        isAlloweToken(tokenCollateralAddress)
        nonReentrant
    {
        s_collateralDeposited[msg.sender][tokenCollateralAddress] += amountCollateral;
        emit CollateralDeposited(msg.sender, tokenCollateralAddress, amountCollateral);
        bool success = IERC20(tokenCollateralAddress).transferFrom(msg.sender, address(this), amountCollateral);
        if (!success) revert WDSCEngine__TransferFailed();
    }

    function mintWdsc(uint256 amountWdscToMint) public moreThanZero(amountWdscToMint) nonReentrant {
        s_WdscMinted[msg.sender] += amountWdscToMint;
        _revertIfHealthFactorIsBroken(msg.sender);
        bool success = s_wdsc.mint(msg.sender, amountWdscToMint);
        if (!success) revert WDSCEngine__MintingFailed();
    }

    ///////////////////////////////////////
    ///   Internal & Private  Functions ///
    //////////////////////////////////////

    function _getAccountInformation(address user)
        private
        view
        returns (uint256 totalWdscMinted, uint256 collateralValueInUsd)
    {
        totalWdscMinted = s_WdscMinted[user];
        collateralValueInUsd = getAccountCollateralValue(user);
    }

    function _healthFactor(address user) private view returns (uint256) {
        (uint256 totalWdscMinted, uint256 collateralValueInUsd) = _getAccountInformation(user);
        uint256 adjustCollateralHealthfactor = (collateralValueInUsd * LIQUIDATION_THRESHOLD) / LIQUIDATION_PRECISION;

        return (adjustCollateralHealthfactor * LIQUIDATION_PRECISION) / totalWdscMinted;
    }

    function _revertIfHealthFactorIsBroken(address user) internal view {
        (uint256 userHealthFactor) = _healthFactor(user);
        if (userHealthFactor < MIN_HEALTH_FACTOR) {
            revert WDSCEngine__BreaksHealthFactor(userHealthFactor);
        }
    }

    //////////////////////////////////////////
    ///   public & external view  Functions ///
    //////////////////////////////////////////

    function getAccountCollateralValue(address user) public view returns (uint256 tokenCollateralValueInUsd) {
        for (uint256 i = 0; i < s_Colateraltokens.length; i++) {
            address token = s_Colateraltokens[i];
            uint256 tokenAmount = s_collateralDeposited[user][token];
            tokenCollateralValueInUsd += getUsdValue(token, tokenAmount);
        }
        return tokenCollateralValueInUsd;
    }

    function getUsdValue(address token, uint256 amount) public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[token]);
        (, int256 price,,,) = priceFeed.latestRoundData();
        return ((uint256(price) * FEED_PRECISON) * amount) / PRECISION;
    }
}
