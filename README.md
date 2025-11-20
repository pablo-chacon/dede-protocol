
---

# **DeDe Protocol: Trustless, Universal Delivery Settlement (Mainnet-Ready)**

**DeDe Protocol** is a minimal, self-contained, production-ready settlement layer for decentralized delivery networks.
It implements the **core rails** that any delivery app, marketplace, or logistics platform can build on top of without dictating UI, routing logic, or business models.

This repository contains **only the immutable smart contracts**, the deploy script, and the mock token used in tests.

---

## **What DeDe Protocol Provides**

### 🔹 **1. ParcelCore: the settlement engine**

* ERC-721 parcels
* Pickup -> dropoff -> finalize lifecycle
* Automatic **finalization after 72h** if neither side finalizes
* **Immutable protocol fee** (0.5%) -> paid to `protocolTreasury`
* **Dynamic platform fee** (3% → 22%) -> paid to `platformTreasury`
* **Permissionless finalization** with a 0.05% finalizer tip
* Full slashing support through signer registry
* Emits deterministic events that indexers can build on

### 🔹 **2. Escrow: secure value transfer**

* Holds user funds until parcel completion
* Releases value automatically based on parcel state transitions
* Protocol + platform fees taken at payout time
* Trusted by `ParcelCore` only (no external writing)

### 🔹 **3. AStarSignerRegistryStaked: oracle/signer registry**

* Permissionless join
* Mandatory stake
* Slashing on misconduct
* Supports A* signatures only (cleaner, safer)

---

## 📦 Repo Structure

```
dede-protocol/
├── foundry.toml
├── README.md
├── script/
│   └── DeployProtocol.s.sol
├── src/
│   ├── AStarSignerRegistryStaked.sol
│   ├── Escrow.sol
│   └── ParcelCore.sol
└── test/
    └── MockERC20.sol
```

This repo is intentionally **bare-metal**.
It contains only the **canonical protocol implementation**.

Apps, UIs, APIs, routing engines, carrier apps, and SDKs should live in separate repositories.

---

## Quick Start (Local)

### **1. Install & test**

```bash
forge install
forge test -vv
```

### **2. Configure for deployment**

```bash
cp .env.deploy.example .env.deploy
```

Set:

* `PRIVATE_KEY`
* `PROTOCOL_TREASURY`
* `PLATFORM_TREASURY`
* `STAKE_TOKEN`
* `MIN_STAKE`

### **3. Deploy locally**

```bash
anvil
forge script script/DeployProtocol.s.sol:DeployProtocol \
  --rpc-url http://127.0.0.1:8545 \
  --broadcast \
  --env-file .env.deploy
```

---

## Deploy to Sepolia / Mainnet

Sepolia:

```bash
forge script script/DeployProtocol.s.sol:DeployProtocol \
  --rpc-url $SEPOLIA_RPC \
  --broadcast \
  --env-file .env.deploy
```

Mainnet:

```bash
forge script script/DeployProtocol.s.sol:DeployProtocol \
  --rpc-url $MAINNET_RPC \
  --broadcast \
  --legacy \
  --gas-price $(cast --to-wei 15 gwei) \
  --env-file .env.deploy
```

---

## Security Model

* Protocol fee is **immutable** and cannot be changed post-deploy.
* Platform fee **can** be tuned by the platform operator.
* `owner` of `ParcelCore` should be:

  * a **multisig**, or
  * a **safe**, or
  * fully renounced (turning protocol into neutral public infra).

---

## Philosophy

DeDe Protocol is intentionally:

* **Minimal**
* **Permissionless**
* **Composable**
* **Neutral**

Any routing engine (A*, MAPF, ML, off-chain apps) can plug into it.
Any delivery app can adopt it without adopting your architecture.

This repository is the **canonical implementation of the settlement rail**.

Everything else is optional ecosystem tooling.

---

## License

MIT — Completely open for commercial and public use.

---

