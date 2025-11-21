// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";

contract Escrow is Ownable2Step {
  address public parcelCore;

  struct Ledger {
    address token;
    uint256 amount;
    address payer;
    bool    paid;
    bool    released;
  }

  mapping(uint256 => Ledger) public ledgers;

  modifier onlyCore() {
    require(msg.sender == parcelCore, "not-core");
    _;
  }

  constructor() Ownable(msg.sender) {}

  function setParcelCore(address core) external onlyOwner {
    parcelCore = core;
  }

  function fund(
    uint256 id,
    address token,
    uint256 amount,
    address payer
  ) external payable onlyCore {
    Ledger storage L = ledgers[id];
    require(!L.paid, "already-funded");

    L.token  = token;
    L.amount = amount;
    L.payer  = payer;
    L.paid   = true;

    if (token == address(0)) {
      require(msg.value == amount, "bad-value");
    } else {
      require(IERC20(token).transferFrom(payer, address(this), amount), "transferFrom");
    }
  }

  function releaseWithFees(
    uint256 id,
    address carrier,
    address platformFeeTo, uint16 platformFeeBps,
    address protocolFeeTo, uint16 protocolFeeBps,
    address caller,        uint16 callerTipBps
  ) external onlyCore {
    Ledger storage L = ledgers[id];
    require(L.paid && !L.released, "bad-ledger");
    L.released = true;

    require(platformFeeBps < 10000 && protocolFeeBps < 10000 && callerTipBps < 10000, "bps");
    require(
      uint32(platformFeeBps) + uint32(protocolFeeBps) + uint32(callerTipBps) <= 10000,
      "total-bps"
    );

    uint256 p = (L.amount * platformFeeBps) / 10000;
    uint256 r = (L.amount * protocolFeeBps) / 10000;
    uint256 t = (L.amount * callerTipBps)   / 10000;
    uint256 v = L.amount - p - r - t;

    if (L.token == address(0)) {
      if (p > 0) payable(platformFeeTo).transfer(p);
      if (r > 0) payable(protocolFeeTo).transfer(r);
      if (t > 0) payable(caller).transfer(t);
      payable(carrier).transfer(v);
    } else {
      if (p > 0) require(IERC20(L.token).transfer(platformFeeTo, p), "xferP");
      if (r > 0) require(IERC20(L.token).transfer(protocolFeeTo, r), "xferR");
      if (t > 0) require(IERC20(L.token).transfer(caller,        t), "xferT");
      require(IERC20(L.token).transfer(carrier, v), "xferV");
    }
  }

  function refund(uint256 id, address to) external onlyCore {
    Ledger storage L = ledgers[id];
    require(L.paid && !L.released, "bad-ledger");
    L.released = true;

    if (L.token == address(0)) {
      payable(to).transfer(L.amount);
    } else {
      require(IERC20(L.token).transfer(to, L.amount), "xfer");
    }
  }
}
