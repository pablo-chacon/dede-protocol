

# Decentralized Delivery (DeDe) Protocol


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

## **DeDe Protocol: Trustless, Universal Delivery Settlement (Etherum-Mainnet)**

**DeDe Protocol** is a minimal, self-contained, production-ready settlement layer for decentralized delivery networks.  
It implements the core rails that any delivery app, marketplace, or logistics platform can build on top of without dictating UI, routing logic, or business models.

This repository contains only the immutable smart contracts, the deploy script, and the mock token used in tests.

DeDe Quick-Start Templates:
[https://github.com/pablo-chacon/dede-templates](https://github.com/pablo-chacon/dede-templates)

---

## **What DeDe Protocol Provides**

### **1. ParcelCore: the settlement engine**

* ERC-721 parcels  
* Pickup -> dropoff -> finalize lifecycle  
* Automatic finalization after 72h if neither side finalizes  
* Immutable protocol fee (0.5%) paid to `protocolTreasury`  
* Dynamic platform fee (3% -> 22%) paid to `platformTreasury`  
* Permissionless finalization with a 0.05% finalizer tip  
* Full slashing support through signer registry  
* Emits deterministic events that indexers can build on  

### **2. Escrow: secure value transfer**

* Holds user funds until parcel completion  
* Releases value automatically based on parcel state transitions  
* Protocol and platform fees taken at payout time  
* Trusted by `ParcelCore` only  

### **3. AStarSignerRegistryStaked: oracle/signer registry**

* Permissionless join  
* Mandatory stake  
* Slashing on misconduct  
* Supports A* signatures only  

---

## **Repo Structure**

```
.
├── contracts
│   ├── AStarSignerRegistryStaked.sol
│   ├── Escrow.sol
│   └── ParcelCore.sol
├── DeDe-FAQ.md
├── docs
│   └── integration
│       └── multi-currency.md
├── foundry.lock
├── foundry.toml
├── README.md
├── script
│   └── DeployProtocol.s.sol
├── test
│   └── MockERC20.sol
└── WHITEPAPER.md
```


This repo is intentionally bare-metal.  
It contains only the canonical protocol implementation.

Apps, UIs, APIs, routing engines, carrier apps, and SDKs live in separate repositories.

---

## **Quick Start (Local)**

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
This deployment includes the immutable 0.5% protocol fee, which supports ongoing audits, tooling, SDKs, and ecosystem maintenance.

Integrators are encouraged to use this **official DeDe Protocol deployment** because:

1. **Security**
   The canonical contracts are audited, publicly inspected, and governed by a multisig.

2. **Compatibility**
   Indexers, explorers, and SDKs will follow the official deployment.

3. **Sustainability**
   The immutable protocol fee funds maintenance without affecting platform economics.

---

**Official contract addresses (Ethereum Mainnet)**

  * ParcelCore: 0xeF1D4970c3B988840B13761Ec4FBb85106d789F8

  * Escrow: 0x834317eFB2E6eE362a63474837398086cC302934

  * AStarSignerRegistryStaked: 0x311A4c3Ed79D4467C55dd7CEE0C731501DF3f161

  * protocolTreasury: 0x9C34d6a6BF1257A9e36758583cDC36F4cE2fA78F

To integrate, simply point your application or marketplace to these contract addresses.

DeDe Quick-Start Templates:
[https://github.com/pablo-chacon/dede-templates](https://github.com/pablo-chacon/dede-templates)


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
