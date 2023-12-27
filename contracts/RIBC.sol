//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
contract RIBC is ERC20("Ribbit Coin", "RIBC"), Ownable{
    address public devWallet;
    uint256 public sellTax = 100;
    mapping(address => bool) public ammPools;

    event SetAmmPool(address indexed pool, bool indexed value);


    constructor()  {
        devWallet = msg.sender;
        _mint(msg.sender,21e29);
    }
    
    function setDevWallet(address newWallet) public onlyOwner {
        devWallet = newWallet;
    }
    function setSellTaxes(uint256 _tax) external onlyOwner {
        require(_tax <= 200, "Fee must be <= 20%");
        sellTax = _tax;
    }

    function setAutomatedMarketMakerPair(address newPair, bool value)
        external
        onlyOwner
    {
        _setAutomatedMarketMakerPool(newPair, value);
    }

    function _setAutomatedMarketMakerPool(address newPool, bool value) private {
        require(
            ammPools[newPool] != value,
            "Automated market maker pair is already set to that value"
        );
        ammPools[newPool] = value;

        emit SetAmmPool(newPool, value);
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }
        if(ammPools[to]){
            uint256 feeAmt;
            //1%
            feeAmt = (amount * sellTax) / 10000;
            feeSwap(from,feeAmt);
            amount = amount - feeAmt*2;
            super._transfer(from, address(this), feeAmt);
        }

        super._transfer(from, to, amount);

    }
    function feeSwap(address from, uint256 feeAmt) private{
        _burn(from,feeAmt);
    }

    function rescueERC20Tokens(address tokenAddress) external onlyOwner {
        IERC20(tokenAddress).transfer(
            devWallet,
            IERC20(tokenAddress).balanceOf(address(this))
        );
    }

    

}