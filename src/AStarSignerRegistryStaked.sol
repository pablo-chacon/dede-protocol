// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";

contract AStarSignerRegistryStaked is Ownable2Step {
  IERC20  public immutable stakeToken;
  uint256 public minStake;
  uint256 public unbondingDelay = 7 days;

  struct SignerInfo { uint256 stake; uint64 canWithdrawAfter; bool allowed; }
  mapping(address => SignerInfo) public info;

  event SignerJoined(address signer, uint256 stake);
  event SignerAllowed(address signer, bool allowed);
  event Slashed(address signer, uint256 amount, address to);
  event UnbondRequested(address signer, uint64 canWithdrawAfter);
  event Withdrawn(address signer, uint256 amount);

  constructor(address _stakeToken, uint256 _minStake)
    Ownable(msg.sender)                      // ✅ call base Ownable constructor
  {
    stakeToken = IERC20(_stakeToken);        // ✅ init immutable
    minStake   = _minStake;
  }

  function setMinStake(uint256 s) external onlyOwner { minStake = s; }
  function setUnbondingDelay(uint256 d) external onlyOwner { unbondingDelay = d; }

  function join(uint256 amount) external {
    require(amount >= minStake, "stake too low");
    SignerInfo storage s = info[msg.sender];
    require(s.stake == 0, "already joined");
    require(stakeToken.transferFrom(msg.sender, address(this), amount), "transferFrom");
    s.stake = amount; s.allowed = true; s.canWithdrawAfter = 0;
    emit SignerJoined(msg.sender, amount); emit SignerAllowed(msg.sender, true);
  }

  function requestUnbond() external {
    SignerInfo storage s = info[msg.sender];
    require(s.stake > 0, "no stake");
    s.allowed = false; s.canWithdrawAfter = uint64(block.timestamp + unbondingDelay);
    emit SignerAllowed(msg.sender, false); emit UnbondRequested(msg.sender, s.canWithdrawAfter);
  }

  function withdraw() external {
    SignerInfo storage s = info[msg.sender];
    require(s.stake > 0 && s.canWithdrawAfter != 0 && block.timestamp >= s.canWithdrawAfter, "not ready");
    uint256 amt = s.stake; s.stake = 0; s.canWithdrawAfter = 0;
    require(stakeToken.transfer(msg.sender, amt), "xfer"); emit Withdrawn(msg.sender, amt);
  }

  function slash(address signer, uint256 amount, address to) external onlyOwner {
    SignerInfo storage s = info[signer];
    require(s.stake >= amount, "exceeds stake");
    s.stake -= amount; s.allowed = false;
    require(stakeToken.transfer(to, amount), "xfer");
    emit Slashed(signer, amount, to); emit SignerAllowed(signer, false);
  }

  bytes32 public constant ROLE_ASTAR = keccak256("ROLE_ASTAR");
  function isAllowed(address signer, bytes32 role) external view returns (bool) {
    if (role != ROLE_ASTAR) return false;
    SignerInfo memory s = info[signer];
    return s.allowed && s.stake >= minStake;
  }
}
