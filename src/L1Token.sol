// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

contract L1Token is ERC20, ERC20Permit, ERC20Votes, Ownable {
    
    constructor(
        uint256 freeSupply,
        uint256 airdropSupply
    )
        ERC20("Interchain Token", "ICT")
        ERC20Permit("Interchain Token")
    {
        _mint(msg.sender, freeSupply);
        _mint(address(this), airdropSupply);
    }

    /**
     * @dev Mints new tokens.
     * @param dest The address to mint the new tokens to.
     * @param amount The quantity of tokens to mint.
     */
    function mint(address dest, uint256 amount) external {
        require(msg.sender ==  owner(), "Your role is not specified to mint tokens");
        _mint(dest, amount);
    }

    /**
     * @dev Burns the owner's tokens.
     * @param amount The quantity of tokens to burn.
     */
    function burn(uint256 amount) external onlyOwner {
        _burn(owner(), amount);
    }

    // The following functions are overrides required by Solidity.

    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._burn(account, amount);
    }
}