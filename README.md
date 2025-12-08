

# Decentralized Delivery (DeDe) Protocol

**Decentralized Crowdshipping Protocol (Peer-to-Peer Parcel)**

---

## Legal Disclaimer

This repository contains general-purpose, open-source smart contracts.  
The authors and contributors:

* do not operate any delivery service, marketplace, or business built on top of this code  
* do not verify or supervise users, carriers, or platforms  
* do not provide legal, financial, or tax advice  
* are not responsible for deployments, integrations, or real-world usage  

All deployments of DeDe Protocol are performed **at the risk of the deployer and the integrating platform**.

No warranty of any kind is provided.  
The software is offered strictly **as-is**, without guarantees of fitness for any purpose.  
The authors are not liable for any damages, losses, claims, or issues arising from the use, misuse, or failure of this software or any derivative work.

By using, deploying, integrating, or interacting with this software in any form, you agree that all responsibility for legal compliance, operation, and outcomes lies solely with you.

---

## **DeDe Protocol: Trustless, Universal Delivery Settlement (Ethereum-Mainnet)**

**DeDe Protocol** is a minimal, self-contained, production-ready settlement layer for decentralized delivery networks.

**Peer-to-Peer Parcel** -> Pickup -> Dropoff -> Delivery confirmation.  

**DeFi/CeFi Agnostic:**
Easy integration of delivery settlement for apps, fintech providers, and payment platforms within existing workflows.


**This repository contains only the immutable smart contracts, the deploy script, and the mock token used in tests.**

---

## **Ethereum Mainnet Deployment**

Official DeDe Protocol contract addresses:

* **ParcelCore:** 0xeF1D4970c3B988840B13761Ec4FBb85106d789F8
* **Escrow:** 0x834317eFB2E6eE362a63474837398086cC302934
* **AStarSignerRegistryStaked:** 0x311A4c3Ed79D4467C55dd7CEE0C731501DF3f161
* **protocolTreasury:** 0x9C34d6a6BF1257A9e36758583cDC36F4cE2fA78F

---

## **Start building:**

Links to dede-templates repository.


**[DeDe Quick-Start Templates](https://github.com/pablo-chacon/dede-templates)**


**[DeDe Multi-Currency DeFI Integration](https://github.com/pablo-chacon/dede-templates/blob/main/integration/multi-currency.md)** 


**[DeDe Multi-Currency CeFi Integration](https://github.com/pablo-chacon/dede-templates/blob/main/integration/multi-currency-cefi.md)**

---

## **Repo Structure**

```
.
├── contracts
│   ├── AStarSignerRegistryStaked.sol
│   ├── Escrow.sol
│   └── ParcelCore.sol
├── DeDe-FAQ.md
├── foundry.lock
├── foundry.toml
├── media
│   └── dede.svg
├── README.md
├── script
│   └── DeployProtocol.s.sol
├── test
│   └── MockERC20.sol
└── WHITEPAPER.md
```

---

## **Centralized P2P Crowdshipping VS DeDe (P2P Decentralized Delivery)**

| **System Function**       | **Centralized Platforms (Uber / DoorDash / Amazon Flex)** | **DeDe Protocol (Decentralized Delivery)**    |
| ------------------------- | --------------------------------------------------------- | --------------------------------------------- |
| **Identity**              | User identity controlled by the platform                  | Off-chain identity (wallet, KYC, or none)     |
| **Matching / Assignment** | Platform assigns and controls job visibility              | Open matching; integrators choose logic       |
| **Parcel Lifecycle**      | Private backend, mutable state                            | On-chain immutable state machine              |
| **Escrow / Settlement**   | Company-controlled funds, reversible payouts              | Trustless on-chain escrow, automatic payout   |
| **Fees**                  | Platform can change fees anytime                          | Immutable protocol fee + visible platform fee |
| **Routing**               | Proprietary black-box algorithms                          | Any routing engine (A*, MAPF, ML, custom)     |
| **Disputes**              | Opaque centralized arbitration                            | Auto-finalization + permissionless finalize   |
| **Data Ownership**        | Platform owns and monetizes movement + behavioral data    | Neutral infrastructure, no data extraction    |

---

## **NFT as a representation of a physical object**

DeDe uses NFTs as non-speculative infrastructure, not for art, not for collectibles.

An NFT is simply a digital record of ownership for something non-fungible (i.e., unique and indivisible).
Unlike ETH or BTC (which are fungible and can be split), an NFT always refers to one unique object.

In DeDe, the NFT parcel stores:

* parcelId  
* lifecycleState  
* encrypted or hashed pickup/dropoff data  
* route hash and evidence digest 

DeDe does not “put the package on-chain.” The NFT anchors the parcel’s identity and lifecycle in a verifiable, tamper-proof way.
If someone tries to spoof it, the metadata won’t match, fraud becomes detectable by design, not by policy.

* This same primitive can apply to:

* Title deeds

* Vehicle ownership

* Event tickets

* Physical access credentials

The NFT model provides a deterministic, auditable, and trustless lifecycle, ideal for physical-world assets that change hands.

---

## **What DeDe Protocol Provides**

### **1. ParcelCore: the settlement engine**

* ERC-721 parcels  
* Pickup -> dropoff -> finalize lifecycle  
* Automatic finalization after 72h if neither side finalizes  
* Immutable Protocol fee (0.5%) paid to `protocolTreasury`  
* Dynamic Platform fee (3% -> 22%) paid to `platformTreasury`  
* Permissionless finalization with a 0.05% finalizer tip  
* Full slashing support through signer registry  
* Emits deterministic events that indexers can build on  

### **2. Escrow: secure value transfer**

* Holds user funds until parcel completion  
* Releases value automatically based on parcel state transitions  
* Protocol and platform fees are taken at payout time
* Trusted by `ParcelCore` only  

### **3. AStarSignerRegistryStaked: oracle/signer registry**

* Permissionless join  
* Mandatory stake  
* Slashing on misconduct  
* Supports A* signatures only  

---

This repo is intentionally bare-metal.  
It contains only the canonical protocol implementation.

Apps, UIs, APIs, routing engines, carrier apps, and SDKs live in separate repositories.

---

## **Finalization and Disputes**

### **Finalization**

   * After `finalizeAfter`, anyone may call `finalize(id)`.
   * If parcel is in **Dropped** or **Delivered**:

     * `Escrow.releaseWithFees` sends funds to carrier, platform treasury, protocol treasury, and finalizer (tip).
   * If parcel is still **Minted / Accepted / PickedUp / OutForDelivery** and never completed, the platform may dispute or cancel; finalization then refunds the platform if that branch is reached.
   * Parcel state: **Finalized**.

   * **All on-chain fees (protocol fee, platform fee, and finalizer tip) are deducted from the carrier’s payout.** The sender never pays settlement fees after funding the escrow.

### **Disputes**

   * Platform can call `dispute(id, reasonHash)` when parcel is Dropped/Delivered.
   * Owner (for example, a multisig or DAO) later calls `resolve(id, winner)` where `winner` is either the carrier or the platform.
   * Depending on resolution:

     * If `winner == carrier`: funds are released with fees as usual.
     * Otherwise: full refund to platform.
   * State becomes **Finalized** and a `Resolved` event is emitted.

---

## **Quick Start (Local)**

### **Prerequisites**

[foundry](https://getfoundry.sh/)


### **1. Install and test**

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

## **Security Model**

* Protocol fee is immutable and cannot be changed post-deploy
* Platform fee can be tuned by the platform operator
* `owner` of `ParcelCore` should be:

  * a multisig, or
  * a Safe, or
  * fully renounced

---

## **Philosophy**

DeDe Protocol is:

* Minimal
* Permissionless
* Composable
* Neutral

Any routing engine (A*, MAPF, ML, off-chain apps) can plug into it.
Any delivery app can adopt it without DeDe adopting your architecture.

---

# **Official Canonical Deployment (Recommended for All Integrators)**

DeDe Protocol official, on-chain canonical deployment.
This deployment includes the immutable 0.5% Protocol Fee, which supports ongoing audits, tooling, SDKs, and ecosystem maintenance.

Integrators are encouraged to use this **official DeDe Protocol deployment** because:

1. **Security**
   The canonical contracts are audited, publicly inspected, and governed by a multisig.

2. **Compatibility**
   Indexers, explorers, and SDKs will follow the official deployment.

3. **Sustainability**
   The immutable Protocol Fee funds maintenance without affecting platform economics.

---

### DeDe Quick-Start Templates:
**[https://github.com/pablo-chacon/dede-templates](https://github.com/pablo-chacon/dede-templates)**

---

# **Custom Deployment (Optional Advanced Usage)**

Most platforms should use the canonical deployment.
However, advanced users, researchers, and private test networks may deploy their own instance.

### **Sepolia**

```bash
forge script script/DeployProtocol.s.sol:DeployProtocol \
  --rpc-url $SEPOLIA_RPC \
  --broadcast \
  --env-file .env.deploy
```

### **Mainnet**

```bash
forge script script/DeployProtocol.s.sol:DeployProtocol \
  --rpc-url $MAINNET_RPC \
  --broadcast \
  --legacy \
  --gas-price $(cast --to-wei 15 gwei) \
  --env-file .env.deploy
```

Custom deployments will **not** be indexed alongside the canonical DeDe contracts and will not automatically inherit ecosystem tooling.

---

## **License**

MIT License

Copyright (c) 2025 Emil Karlsson

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

---

## **Contact**

**[Contact Email](pablo-chacon-ai@proton.me)**

---

## **Further Reading**

* **Technical: [NFTs: Digital Containers for Real-World Assets](https://medium.com/@ekarlsson66/nfts-digital-containers-for-real-world-assets-a6f8fb001c65)**

* **Vision: [DeDe: The Delivery Rail for a Free World](https://medium.com/@ekarlsson66/dede-the-delivery-rail-for-a-free-world-e7be944b90fc)**


