// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";

interface IEscrow {
  function fund(uint256, address, uint256, address) external payable;
  function releaseWithFees(
    uint256 id,
    address carrier,
    address platformFeeTo, uint16 platformFeeBps,
    address protocolFeeTo, uint16 protocolFeeBps,
    address caller,        uint16 callerTipBps
  ) external;
  function refund(uint256 id, address to) external;
}

interface ISignerRegistry {
  function isAllowed(address, bytes32) external view returns (bool);
}

contract ParcelCore is ERC721, Ownable2Step {
  enum State {
    Minted,
    Accepted,
    PickedUp,
    OutForDelivery,
    Dropped,
    Delivered,
    Finalized,
    Disputed
  }

  struct Parcel {
    address platform;
    address receiver;
    address carrier;
    State   state;

    uint64  createdAt;
    uint64  pickupAt;
    uint64  dropoffAt;
    uint64  finalizeAfter;

    bytes32 pickupCellHash;
    bytes32 dropoffCellHash;
    bytes32 routeHash;
    bytes32 photoDigest;
    string  photoCid;

    address escrowToken;
    uint256 escrowAmount;
    uint256 stakeAmount;
  }

  mapping(uint256 => Parcel) public parcels;

  IEscrow public immutable escrow;
  ISignerRegistry public immutable signerRegistry;

  bytes32 public constant ROLE_ASTAR = keccak256("ROLE_ASTAR");

  // Platform fee schedule (owner-governed, protocol fee is immutable)
  address public platformTreasury;
  uint64[] public feeCutThresholds;  // seconds since pickup
  uint16[] public feeCutBps;         // bps tiers
  uint16   public baseBps = 300;     // 3%

  // Immutable protocol fee (e.g. 50 = 0.5%)
  address public immutable protocolTreasury;
  uint16  public immutable protocolCutBps; // must be set at deploy (e.g. 50 for 0.5%)

  // Permissionless finalize tip (bps of escrow)
  uint16  public finalizeTipBps = 5; // 0.05%

  event ParcelMinted(uint256 parcelId, address platform, address receiver, address token, uint256 amount);
  event Accepted(uint256 parcelId, address carrier, uint256 stake);
  event PickedUp(uint256 parcelId, address carrier, uint64 t, bytes32 coarseCellHash);
  event OutForDelivery(uint256 parcelId, uint64 t);
  event Dropoff(uint256 parcelId, uint64 t, bytes32 routeHash, string photoCid, bytes32 photoDigest);
  event Delivered(uint256 parcelId);
  event Finalized(uint256 parcelId);
  event Disputed(uint256 parcelId, bytes32 reasonHash);
  event Resolved(uint256 parcelId, address winner);

  modifier onlyPlatform(uint256 id) {
    require(msg.sender == parcels[id].platform, "not-platform");
    _;
  }

  modifier onlyCarrier(uint256 id) {
    require(msg.sender == parcels[id].carrier, "not-carrier");
    _;
  }

  constructor(
    address _escrow,
    address _signerReg,
    address _protocolTreasury,
    uint16  _protocolCutBps  // e.g. 50 for 0.5%
  )
    ERC721("DeDeParcel", "DEDE")
    Ownable(msg.sender)              // Set initial owner
  {
    require(_protocolTreasury != address(0), "proto-zero");
    require(_protocolCutBps > 0 && _protocolCutBps < 200, "proto-bps-cap"); // <2%
    escrow           = IEscrow(_escrow);
    signerRegistry   = ISignerRegistry(_signerReg);
    protocolTreasury = _protocolTreasury;
    protocolCutBps   = _protocolCutBps;
  }


  // Admin
  function setPlatformTreasury(address t) external onlyOwner {
    platformTreasury = t;
  }

  function setFeeSchedule(
    uint64[] calldata th,
    uint16[] calldata bp,
    uint16   base
  ) external onlyOwner {
    require(th.length == bp.length, "len");
    require(base < 10000, "base");
    for (uint256 i = 0; i < bp.length; i++) {
      require(bp[i] < 10000, "bps");
    }
    for (uint256 i = 1; i < th.length; i++) {
      require(th[i] > th[i - 1], "thr");
    }
    feeCutThresholds = th;
    feeCutBps        = bp;
    baseBps          = base;
  }

  function setFinalizeTipBps(uint16 b) external onlyOwner {
    require(b < 100, "cap 1%"); // small safety cap
    finalizeTipBps = b;
  }

  // ---- Fee lookup ----

  function feeBps(uint256 id, uint64 refTime) public view returns (uint16) {
    Parcel storage p = parcels[id];
    if (p.pickupAt == 0 || refTime <= p.pickupAt) return baseBps;

    uint64 age = refTime - p.pickupAt;
    uint16 bps = baseBps;
    for (uint256 i = 0; i < feeCutThresholds.length; i++) {
      if (age >= feeCutThresholds[i]) bps = feeCutBps[i];
      else break;
    }
    return bps;
  }

  // ---- Core flow ----

  function mintParcel(
    uint256 id,
    address platform,
    address receiver,
    address token,
    uint256 amount,
    bytes32 pickupCellHash,
    bytes32 dropoffCellHash
  ) external payable {
    // OZ v5: use _ownerOf instead of _exists
    require(_ownerOf(id) == address(0), "exists");
    _safeMint(platform, id);

    Parcel storage p = parcels[id];
    p.platform        = platform;
    p.receiver        = receiver;
    p.state           = State.Minted;
    p.createdAt       = uint64(block.timestamp);
    p.pickupCellHash  = pickupCellHash;
    p.dropoffCellHash = dropoffCellHash;
    p.escrowToken     = token;
    p.escrowAmount    = amount;

    if (token == address(0)) {
      escrow.fund{value: amount}(id, token, amount, msg.sender);
    } else {
      escrow.fund(id, token, amount, msg.sender);
    }

    emit ParcelMinted(id, platform, receiver, token, amount);
  }

  function accept(uint256 id, uint256 stake) external {
    Parcel storage p = parcels[id];
    require(p.state == State.Minted, "bad-state");
    p.carrier     = msg.sender;
    p.stakeAmount = stake;
    p.state       = State.Accepted;
    emit Accepted(id, msg.sender, stake);
  }

  function pickup(uint256 id, bytes32 coarseCellHash) external onlyCarrier(id) {
    Parcel storage p = parcels[id];
    require(p.state == State.Accepted, "bad-state");
    p.pickupAt      = uint64(block.timestamp);
    p.finalizeAfter = p.pickupAt + 72 hours;
    p.state         = State.PickedUp;
    emit PickedUp(id, msg.sender, p.pickupAt, coarseCellHash);
  }

  function markOutForDelivery(uint256 id) external onlyCarrier(id) {
    Parcel storage p = parcels[id];
    require(p.state == State.PickedUp, "bad-state");
    p.state = State.OutForDelivery;
    emit OutForDelivery(id, uint64(block.timestamp));
  }

  function dropoff(
    uint256 id,
    bytes32 routeHash,
    string calldata photoCid,
    bytes32 photoDigest,
    address astarSigner
  ) external onlyCarrier(id) {
    Parcel storage p = parcels[id];
    require(p.state == State.OutForDelivery, "bad-state");

    // check signer allowlist (content-verified off-chain)
    bytes32 ROLE_ASTAR_LOCAL = ROLE_ASTAR;
    require(signerRegistry.isAllowed(astarSigner, ROLE_ASTAR_LOCAL), "bad-astar-signer");

    p.routeHash   = routeHash;
    p.photoCid    = photoCid;
    p.photoDigest = photoDigest;
    p.dropoffAt   = uint64(block.timestamp);
    p.state       = State.Dropped;

    emit Dropoff(id, p.dropoffAt, routeHash, photoCid, photoDigest);
  }

  function deliver(uint256 id) external {
    Parcel storage p = parcels[id];
    require(msg.sender == p.receiver, "not-receiver");
    require(p.state == State.Dropped, "bad-state");
    p.state = State.Delivered;
    emit Delivered(id);
  }

  function finalize(uint256 id) external {
    Parcel storage p = parcels[id];

    require(platformTreasury != address(0), "plat-treasury unset");
    require(p.pickupAt != 0 && block.timestamp >= p.finalizeAfter, "too-early");

    if (p.state == State.Dropped || p.state == State.Delivered) {
      uint64 refTime = p.dropoffAt == 0 ? uint64(block.timestamp) : p.dropoffAt;
      uint16 platformBps = feeBps(id, refTime);

      escrow.releaseWithFees(
        id,
        p.carrier,
        platformTreasury,  platformBps,
        protocolTreasury,  protocolCutBps,
        msg.sender,        finalizeTipBps
      );

      p.state = State.Finalized;
      emit Finalized(id);
    } else {
      // Never reached dropoff+delivery flow => refund platform
      escrow.refund(id, p.platform);
      p.state = State.Finalized;
      emit Finalized(id);
    }
  }

  function dispute(uint256 id, bytes32 reasonHash) external onlyPlatform(id) {
    Parcel storage p = parcels[id];
    require(p.state == State.Dropped || p.state == State.Delivered, "bad-state");
    p.state = State.Disputed;
    emit Disputed(id, reasonHash);
  }

  function resolve(uint256 id, address winner) external onlyOwner {
    Parcel storage p = parcels[id];
    require(p.state == State.Disputed, "bad-state");

    if (winner == p.carrier) {
      uint64 refTime = p.dropoffAt == 0 ? uint64(block.timestamp) : p.dropoffAt;
      uint16 platformBps = feeBps(id, refTime);

      escrow.releaseWithFees(
        id,
        p.carrier,
        platformTreasury,  platformBps,
        protocolTreasury,  protocolCutBps,
        msg.sender,        0
      );
    } else {
      escrow.refund(id, p.platform);
    }

    p.state = State.Finalized;
    emit Resolved(id, winner);
    emit Finalized(id);
  }
}
