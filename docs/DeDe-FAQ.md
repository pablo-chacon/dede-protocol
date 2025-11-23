
---

# DeDe Protocol: FAQ

## What is DeDe?

DeDe is **not an app**, **not a marketplace**, and **not a company**. It is a minimal **delivery settlement rail** that runs on Ethereum.
Think of it like:

* **Bitcoin → money**
* **Matrix → messaging**
* **DeDe → physical delivery**

These are **neutral protocols**, not platforms. They don’t provide apps, account systems, or surveillance layers. DeDe works the same way, it only handles **settlement** for deliveries.

**SaaS/PaaS** (Software as a Service / Platform as a Service) **vs** **Protocol**:

* SaaS and PaaS live at the OSI model’s **Application and Presentation layer**
* Protocols like TCP/IP or DeDe live at the **Transport layer**

---

## What does DeDe actually do?

DeDe allows anyone to:

1. **Register a parcel on-chain** as an ERC-721 NFT
2. **Deposit an escrow** amount that represents the parcel's value
3. Let **any voluntary carrier** choose to deliver it
4. **Settle payment** trustlessly when both parties confirm delivery

Once confirmed by both sides:

* **0.5%** is taken as a **transaction fee**
* **99.5%** goes to the **carrier**

This fee structure is **immutable** and enforced **on-chain** by the smart contract.

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

