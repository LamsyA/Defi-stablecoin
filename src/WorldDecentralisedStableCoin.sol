// SPDX-Lincense-Identifier: MIT

pragma solidity 0.8.20;

import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
/*
 *  @title: Decentralised Stable Coin
 *  @author: Adetula Olamide
 *
 *
 */

contract WorldDecentralizedStableCoin is ERC20Burnable, Ownable {
    error WDSC_MustBeGreaterThanZero();
    error WDSC_InssufficientBalance();
    error WDSC_NotZeroAddress();

    constructor() ERC20("World Decentralised Stable Coin", "WDSC") Ownable(msg.sender) {}

    function burn(uint256 _amount) public override onlyOwner {
        uint256 balance = balanceOf(msg.sender);
        if (_amount <= 0) {
            revert WDSC_MustBeGreaterThanZero();
        }
        if (balance < _amount) {
            revert WDSC_InssufficientBalance();
        }
        super.burn(_amount);
    }

    function mint(address _to, uint256 _amount) external onlyOwner returns (bool) {
        if (_to == address(0)) {
            revert WDSC_NotZeroAddress();
        }
        if (_amount <= 0) {
            revert WDSC_MustBeGreaterThanZero();
        }
        _mint(_to, _amount);
        return true;
    }
}
