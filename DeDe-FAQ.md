
---

# DeDe Protocol: FAQ

## What is DeDe?

DeDe is **not an app**, **not a marketplace**, and **not a company**. It is a minimal **delivery settlement rail** that runs on Ethereum.
Think of it like:

* **Bitcoin -> money**
* **Matrix -> messaging**
* **DeDe -> physical delivery**

These are **neutral protocols**, not platforms. They don’t provide apps, account systems, or surveillance layers. DeDe works the same way, it only handles **settlement** for deliveries.

**SaaS/PaaS** (Software as a Service / Platform as a Service) **vs** **Protocol**:

* SaaS and PaaS live at the OSI model’s **Application and Presentation layer**
* Protocols like TCP/IP or DeDe live at the **Transport layer**

---

[DeDe Medium Story](https://medium.com/@ekarlsson66/dede-the-delivery-rail-for-a-free-world-e7be944b90fc)

---

## What does DeDe actually do?

DeDe allows anyone to:

1. **Register a parcel on-chain** as an ERC-721 NFT
2. **Deposit an escrow** amount that represents the parcel's value
3. Let **any voluntary carrier** choose to deliver it
4. **Settle payment** trustlessly when both parties confirm delivery

Once confirmed by both sides:

* **0.5%** is taken as a **protocol fee**
* **99.5%** goes to the **carrier**

This fee structure is **immutable** and enforced **on-chain** by the smart contract.

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

## What if someone builds an app on top of DeDe?

DeDe does **not control** apps, fees, or business models.

If a marketplace adds an extra fee (e.g., 4.5%), that:

* is **external to the protocol**
* belongs to the **specific service**
* has **nothing to do with DeDe’s smart contract**

Example:

If a carrier receives **95%** of the parcel value:

* **0.5%** went to DeDe as the protocol fee
* **4.5%** was taken by the app or marketplace

---

## What does DeDe NOT include?

DeDe does **not** include:

* Account systems
* Identity management
* GPS tracking
* Centralized scheduling
* Surveillance
* Marketplaces

Those are built by others. DeDe **only handles settlement**.

---

## Is DeDe tied to crypto payments?

No. DeDe is DeFi and CeFi agnostic.

Platforms can accept any currency and settle however they prefer.
They only convert value to an ERC-20 token when entering DeDe escrow.

DeDe stays minimal and the payment system stays off-chain.

**[DeDe Multi-Currency DeFI Integration](https://github.com/pablo-chacon/dede-templates/blob/main/integration/multi-currency.md)** 


**[DeDe Multi-Currency CeFi Integration](https://github.com/pablo-chacon/dede-templates/blob/main/integration/multi-currency-cefi.md)**

---

## How do carriers choose what to deliver?

Carriers can:

* Pick **any parcel**
* Deliver ones that match their **existing routes**
* Use **any transport method** they prefer

There are:

* No forced routes
* No assignments
* No central schedules

Everything is **voluntary**.

---

## Where does trust come from?

From the **smart contract**:

* No user identities
* No behavior tracking
* No sensitive data on-chain

It simply:

* Holds escrow
* Waits for mutual confirmation
* Releases payment

If delivery is confirmed: the carrier is paid.
If not: **nobody gets paid**.

---

## Is sensitive data on-chain?

**No.**
Only:

* the `tokenId`
* and its **lifecycle state** (CREATED, PICKED_UP, DELIVERED)

are public.

All other data:

* pickup/dropoff coordinates
* photos
* timestamps

are stored in **encrypted NFT metadata** or **off-chain**.
Ethereum only sees a **hash**, not the data.

---

## Why use NFTs?

The NFT acts as:

* the **parcel ID**
* the **receipt**
* the **proof of ownership**
* a container for **off-chain data**

NFTs are:

* Not just “art pictures”
* Programmable primitives
* Ideal for ownership transfers (e.g., cars, deeds, parcels)

DeDe uses them as **parcel containers**.


* **Further Technical Reading: [NFTs: Digital Containers for Real-World Assets](https://medium.com/@ekarlsson66/nfts-digital-containers-for-real-world-assets-a6f8fb001c65)**

---

## Summary

DeDe is:

* **Voluntary**
* **Decentralized**
* **Permissionless**
* **Private**
* **Trustless**

It is a **neutral rail** for physical delivery, not a product or service.

Apps, dApps and marketplaces can build on top of it, but DeDe itself will always remain:

* **small**
* **simple**
* **sovereign**
* **free**

---

**MIT Licensed**
**Deployed to Ethereum Mainnet**

---

**[Contact Email](pablo-chacon-ai@proton.me)**


