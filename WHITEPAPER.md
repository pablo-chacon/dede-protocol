
---

# DeDe Protocol

### Trustless, Universal Delivery Settlement (Mainnet-Ready)

## Abstract

DeDe Protocol is a minimal, production-ready settlement layer for decentralized delivery networks. It provides escrow, fee routing, and dispute-safe finalization for parcel deliveries on public blockchains. Any marketplace, app, or logistics platform can integrate DeDe to get neutral, trust-minimized delivery settlement without giving up their own routing logic, UX, or business model.

DeDe is **not** a delivery service and does not operate vehicles, terminals, or couriers. It is open-source general-purpose software: A protocol others can use, fork, or ignore under their own legal responsibilities.

---

## 1. Introduction

Traditional delivery systems are often centralized, opaque, and slow to adapt. At the same time, there is an enormous, unused capacity in how people already move through cities by foot, bike, public transit, and cars. Many of these trips could carry parcels if there were a fair and secure way to coordinate them.

DeDe Protocol addresses this gap by focusing on **the settlement rail only**:

* Who should get paid?
* Under what conditions?
* How do we minimize trust between sender, carrier, and app?

All routing, UI, and product logic lives off-chain. The protocol itself only encodes a small, auditable state machine for parcels, escrow, and fees.

---

## 2. Design Goals

DeDe is designed to be:

* **Minimal**: One small, composable settlement layer; no monolithic “all-in-one” stack.
* **Neutral**: DeDe is not a marketplace, front-end, or employer; it is just code.
* **DeFi/CeFi Agnostic**: Only convert value to an ERC-20 token.
* **Permissionless**: Anyone can mint parcels, act as a carrier, or build apps on top.
* **Composable**: Any off-chain routing engine (A*, MAPF, ML, or custom logic) can be plugged in.
* **Predictable**: Protocol fee is immutable; platform fees are explicit and bounded in BPS.
* **Legible**: Parcel lifecycle and events are deterministic, so indexers and explorers can reason about them.

---

## 3. System Overview

The canonical DeDe Protocol deployment consists of three contracts:

1. **ParcelCore**: ERC-721 parcel lifecycle, fee calculation, and finalization logic.
2. **Escrow**: Token and ETH escrow, fee splits, and payouts.
3. **AStarSignerRegistryStaked**: Staked registry for A* routing signers.

The protocol is chain-agnostic across EVM networks and is implemented with Solidity 0.8.24 and modern tooling (Foundry).

---

## 4. Core Components

### 4.1 ParcelCore: Parcel State Machine & Fees

`ParcelCore` is the main settlement engine. Each parcel is an ERC-721 token that encodes the delivery lifecycle on-chain:

* **Minted**: A platform mints a parcel NFT and sets receiver, escrow token, and amount.
* **Accepted**: A carrier claims the parcel and is recorded on-chain.
* **PickedUp**: Carrier confirms pickup; this starts the **finalization window** (default: 72 hours).
* **OutForDelivery**: Carrier marks the parcel as actively being delivered.
* **Dropped**: Carrier records dropoff, an A* route hash, and proof photo metadata.
* **Delivered**: Receiver confirms they got the parcel.
* **Finalized**: Funds are released or refunded; the escrow closes.
* **Disputed**: Platform flags a dispute; owner resolves to either carrier or platform.

Each parcel stores:

* Parties: `platform`, `receiver`, `carrier`
* Timestamps: `createdAt`, `pickupAt`, `dropoffAt`, `finalizeAfter`
* Location hashes: `pickupCellHash`, `dropoffCellHash`
* Routing & evidence: `routeHash`, `photoCid`, `photoDigest`
* Economics: `escrowToken`, `escrowAmount`, `stakeAmount` (informational)

The protocol enforces **automatic finalization**:

* `finalizeAfter` is set to `pickupAt + 72 hours`.
* Anyone can call `finalize(id)` after that time.
* The finalizer receives a small **tip** (default 0.05% of escrow).

This removes the need for a centralized cron server or off-chain keeper.

**Important:** DeDe Protocol does **not** implement any time-based *value decay* of the escrowed amount. The principal funds remain intact until release or refund. Any “value drop” or pricing policy over time is entirely an off-chain concern of the app and/or marketplace.

#### Platform Fee Calculation

`ParcelCore` supports a **platform fee schedule** expressed in basis points (BPS) and configured by the contract owner:

* `baseBps`: baseline platform fee (default: 300 = 3%).
* `feeCutThresholds[]` + `feeCutBps[]`: optional schedule for alternate fee BPS.

The exact schedule is up to the operator (for example, a range from 3% to 22%). What matters at protocol level is:

* Protocol fee (below) is **immutable**.
* Platform fee is **explicit**, bounded by 0–100% and configured on-chain.
* Payout always uses a single BPS value per parcel when funds are released.

The recommended deployment script sets an initial schedule but operators are free to adjust it within sane bounds.

### 4.2 Escrow: Token & ETH Settlement

`Escrow` is a simple ledger keyed by `parcelId`:

* `fund(id, token, amount, payer)`: called by `ParcelCore` when a parcel is minted. Accepts ETH (native) or ERC-20 tokens.
* `releaseWithFees(...)`: splits escrowed funds between:

  * **Carrier**: main payout
  * **Platform treasury**: platform fee (BPS of escrow)
  * **Protocol treasury**: immutable protocol fee (BPS of escrow)
  * **Finalizer**: caller tip (BPS of escrow)
* `refund(id, to)`: returns the full escrow amount to the platform (for example, if a dispute resolves in the platform’s favor or the parcel never progressed).

`Escrow` trusts **only** the `ParcelCore` contract as a caller; no external app can arbitrarily drain funds. All release conditions are enforced by the parcel state machine.

### 4.3 AStarSignerRegistryStaked: Routing Signer Registry

`AStarSignerRegistryStaked` maintains a set of approved A* routing signers:

* Signers deposit a stake in a configurable ERC-20 token.
* Each signer has: `stake`, `canWithdrawAfter`, `allowed` flag.
* A signer is considered valid for A* if:

  * `allowed == true`, and
  * `stake >= minStake`.

Core functions:

* `join(amount)`: stake tokens and become an allowed signer.
* `requestUnbond()`: disable signing and start the unbonding delay.
* `withdraw()`: withdraw stake after the unbonding period (default 7 days).
* `slash(signer, amount, to)`: owner can slash stake and send it to a recipient (for example, protocol treasury or a fraud compensation pool).

`ParcelCore.dropoff(...)` requires that the provided `astarSigner` is currently allowed in the registry. This ties the on-chain dropoff event to off-chain route computation that is at least **economically bonded**.

---

## 5. Parcel Lifecycle

A typical delivery in DeDe Protocol looks like this:

1. **Creation (Mint)**

   * A platform calls `mintParcel(...)` with:

     * `id` (parcel NFT ID),
     * `receiver`,
     * escrow `token` (0 for ETH),
     * `amount`,
     * `pickupCellHash` and `dropoffCellHash`.
   * `Escrow.fund` is invoked and holds the funds.
   * Parcel is in state **Minted** and owned by the platform (ERC-721).

2. **Acceptance**

   * A carrier calls `accept(id, stakeAmount)`.
   * Protocol records `carrier` and `stakeAmount` (informational).
   * Parcel state: **Accepted**.

3. **Pickup**

   * Carrier calls `pickup(id, coarseCellHash)`.
   * Protocol records `pickupAt` and sets `finalizeAfter = pickupAt + 72 hours`.
   * Parcel state: **PickedUp**.

4. **Out For Delivery**

   * Carrier calls `markOutForDelivery(id)`.
   * Parcel state: **OutForDelivery**.

5. **Dropoff**

   * Carrier calls:

     ```solidity
     dropoff(
       id,
       routeHash,
       photoCid,
       photoDigest,
       astarSigner
     )
     ```
   * Protocol verifies that `astarSigner` is allowed in `AStarSignerRegistryStaked`.
   * `routeHash`, `photoCid`, and `photoDigest` are stored along with `dropoffAt`.
   * Parcel state: **Dropped**.

6. **Delivery Confirmation (optional but typical)**

   * Receiver calls `deliver(id)`.
   * Parcel state: **Delivered**.

7. **Finalization**

   * After `finalizeAfter`, anyone may call `finalize(id)`.
   * If parcel is in **Dropped** or **Delivered**:

     * `Escrow.releaseWithFees` sends funds to carrier, platform treasury, protocol treasury, and finalizer (tip).
   * If parcel is still **Minted / Accepted / PickedUp / OutForDelivery** and never completed, the platform may dispute or cancel; finalization then refunds the platform if that branch is reached.
   * Parcel state: **Finalized**.

   * **All on-chain fees (protocol fee, platform fee, and finalizer tip) are deducted from the carrier’s payout.** The sender never pays settlement fees after funding the escrow.

8. **Disputes**

   * Platform can call `dispute(id, reasonHash)` when parcel is Dropped/Delivered.
   * Owner (for example, a multisig or DAO) later calls `resolve(id, winner)` where `winner` is either the carrier or the platform.
   * Depending on resolution:

     * If `winner == carrier`: funds are released with fees as usual.
     * Otherwise: full refund to platform.
   * State becomes **Finalized** and a `Resolved` event is emitted.

---

## 6. Fees, Treasuries, and Economics

### 6.1 Protocol Fee (Immutable)

* Set at deployment via `PROTOCOL_BPS` (for example, `50` = 0.5%).
* Paid on every successful release to the **protocol treasury** (`protocolTreasury`).
* Hard-coded as `immutable` in `ParcelCore`: cannot be changed after deployment, and is not controlled by apps or platforms.

**DeDe Treasury Wallet**

The `protocolTreasury` address is the **DeDe treasury**. Best practice:

* Use a multisig (for example, a Safe) controlled by multiple independent parties.
* Publish the address publicly so integrators can verify where protocol fees go.
* Optionally, govern the treasury with a DAO or off-chain governance that decides how protocol fees are used (for example, audits, grants, client SDKs).

### 6.2 Platform Fee

* Configured via `setFeeSchedule(thresholds, bps, baseBps)`.
* Typical configuration ranges from **3% up to 22%**, depending on operator policy.
* Paid to `platformTreasury`, which is set by `setPlatformTreasury(address)`.

This allows each deployment to encode its own economics while keeping the protocol fee fixed and neutral.

### 6.3 Finalizer Tip

* `finalizeTipBps` (default 5 = 0.05%) is paid to whoever calls `finalize(id)` after the deadline.
* The owner can adjust this within a small cap (hard-capped at under 1% in the implementation) to ensure finalization incentives without excessive cost.

### 6.4 No Built-In Value Decay

The protocol **does not** reduce the principal escrowed amount over time. There is:

* A time window for **finalization** (for example, 72 hours after pickup),
* Potentially time-aware **fee scheduling** for the platform,

…but **no mechanism that burns, cuts, or decays the escrowed value** based on time. Any policies like “late deliveries get less pay” must be implemented off-chain (for example, by minting smaller escrow amounts for late jobs or resolving disputes differently).

---

## 7. Security Model

Key security properties:

* **Minimal attack surface**: No upgradeability proxies; contracts are small and focused.
* **Immutable protocol fee**: Cannot be hijacked by a future admin.
* **Escrow isolation**: Only `ParcelCore` can instruct `Escrow` to pay or refund.
* **Signer bonding**: A* signers must stake and can be slashed for misconduct.
* **Permissionless finalize**: No reliance on any single keeper or cron job.
* **Owner role**: Platform fee schedule, platform treasury, and signer parameters are controlled by the owner, which should be:

  * A multisig or Safe, or
  * Eventually renounced if turning the protocol into fully neutral public infrastructure.

The protocol itself does not protect users from malicious *apps* or off-chain behavior, but it keeps the on-chain rules narrow and auditable.

---

## 8. What DeDe Is and Is Not

### 8.1 DeDe *Is*

* A **settlement rail** for parcel deliveries.
* A **smart-contract escrow** with deterministic states and fees.
* A **staked registry** for A* routing signers.
* An **open-source, neutral protocol** anyone can integrate with.

### 8.2 DeDe Is *Not*

* A postal or logistics company.
* A courier marketplace or job board.
* An employer of couriers or a handler of physical parcels.
* A routing engine. A*, MAPF, or ML routing logic lives off-chain.
* A KYC/AML system.
* A policy engine encoding time-based price/penalty functions.

All of those concerns must be handled by the applications, marketplaces, or organizations that build on top of DeDe and interact with users.

---

## 9. Legal Position and Responsibility Boundary

DeDe runs entirely on public blockchains. Its developers:

* Do not operate terminals, trucks, bikes, or depots.
* Do not contract with senders, carriers, or recipients.
* Do not control, schedule, or intermediate actual deliveries.
* Publish open-source code that anyone can deploy and use independently.

Responsibility for lawful use rests with:

* The entities who deploy the contracts,
* The apps and marketplaces that integrate them,
* The carriers and platforms that perform real-world operations,
* The platform and/or carrier, who is responsible for reporting income according to local taxation and law.

This is analogous to how BitTorrent, IPFS, or blockchain node software is used: the authors of the software are not automatically liable for whatever independent operators choose to do with it. Local laws may vary and integrators must seek their own legal advice.

---

## 10. Integration Patterns and Use Cases

Some example integrations:

* **Urban Side-Hustle Apps**: Individuals deliver parcels during commutes; the app handles matching and routing, DeDe handles settlement.
* **Local Businesses**: Shops mint parcels for orders and let a network of carriers accept and deliver them, without signing opaque courier contracts.
* **E-commerce Platforms**: Marketplaces integrate DeDe as a backend escrow layer for deliveries, keeping UX and branding fully in-house.
* **Research Pilots**: Universities and NGOs experiment with decentralized logistics and trust-minimized payouts, while keeping code and treasury flows transparent.

Because DeDe is only the settlement layer, multiple, mutually incompatible apps can share the same on-chain rails without coordination.

---

## 11. Conclusion

DeDe Protocol is a canonical, minimal implementation of a **trustless delivery settlement rail**. It:

* Uses ERC-721 parcels as a clear, auditable representation of deliveries.
* Handles escrow, fees, and disputes in a deterministic way.
* Keeps a hard-coded, immutable protocol fee for the DeDe treasury.
* Allows platforms to configure their own fee schedules and treasuries.
* Avoids complex, fragile policy logic like time-based value decay, leaving such concerns to off-chain applications.

It is not a product or company; it is **neutral infrastructure**. Anyone can audit, fork, or deploy it. What gets built on top of it, and how that is governed, regulated, and monetized, is entirely up to the communities and organizations that choose to use it.

---

**[Contact Email](pablo-chacon-ai@proton.me)**
