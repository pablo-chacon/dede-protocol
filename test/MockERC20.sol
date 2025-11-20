// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
contract MockERC20 is ERC20 {
  constructor() ERC20("MockUSD","mUSD") { _mint(msg.sender, 1_000_000e18); }
  function mint(address to, uint256 amt) external { _mint(to, amt); }
}
