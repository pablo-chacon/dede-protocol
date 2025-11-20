
---

# **Multi-Currency Integrations (BTC, XMR, Fiat, Solana, TON, etc.)**

DeDe Protocol is an **EVM-native settlement layer**.
It handles value transfer exclusively using **ERC-20 tokens** inside a trust-minimized, on-chain escrow.

However, any app or marketplace can still accept **any currency**:

* Bitcoin (BTC)
* Monero (XMR)
* Fiat (EUR, USD, SEK)
* Lightning payments
* Solana / TON / Tron
* Layer-2 native tokens
* Any privacy coin

The key is simple:

> **Convert incoming payments into an ERC-20 token before interacting with DeDe.**

This keeps DeDe universal, minimal, and secure without expanding protocol complexity.

---

## **Why DeDe Uses ERC-20 Internally**

DeDe is designed to be:

* **immutable**
* **auditable**
* **minimal**
* **EVM-native**
* **platform-agnostic**

Supporting native BTC, XMR, or other L1s on-chain would introduce:

* bridging risks
* custodial wrappers
* cross-chain messaging
* additional trust assumptions
* increased attack surface

By keeping DeDe strictly ERC-20 inside the escrow, integrations remain:

* simple
* secure
* predictable
* composable

---

## **Architecture Overview**

Here is how a multi-currency integration typically looks:

```
User Pays (BTC / XMR / Solana / Fiat / etc.)
                │
                ▼
       Marketplace/App Backend
     (performs conversion to ERC-20)
                │
                ▼
        DeDe Protocol (EVM)
      - Escrow (ERC-20 only)
      - ParcelCore
      - Oracle signatures
                │
                ▼
         Parcel is finalized
                │
                ▼
   Marketplace optionally swaps back
 (ERC-20 → BTC/XMR/Fiat or keeps as-is)
```

This model is identical to how Web2 apps abstract payments today:

* PayPal
* Uber
* Airbnb
* Shopify
* Food delivery platforms

They accept many currencies, but the backend uses a single internal settlement currency.

---

## **Practical Integration Example (BTC)**

### 1. Customer pays in BTC

Using on-chain BTC or Lightning.

### 2. Your app converts BTC → ERC-20

Options include:

* an internal hot wallet
* a payment service provider
* a liquidity partner
* a decentralized swap (if the user already provided wrapped assets)

### 3. Your app calls DeDe

```solidity
token.approve(escrow, amount);
parcelCore.createParcel(receiver, amount, ...);
```

### 4. DeDe handles escrow and settlement

The value stays secure until parcel completion.

### 5. Your app receives ERC-20 payout

Optionally convert back:

* ERC-20 → BTC
* ERC-20 → fiat
* or keep in stables/ETH

---

## **Practical Integration Example (Monero)**

Monero is fully off-chain relative to EVMs.

Flow:

1. User pays XMR
2. Backend swaps XMR → USDC (or any ERC-20)
3. Interact with DeDe
4. Receive payout in USDC
5. Swap USDC → XMR (optional)
6. Distribute to couriers/users

This supports privacy-sensitive regions while keeping DeDe clean and deterministic.

---

## **Recommended ERC-20 Tokens for Integration**

Most platforms choose:

* **USDC** → predictable, stable
* **USDT** → globally available
* **DAI** → decentralized stablecoin
* **WETH** → gas-aligned
* **Platform-native tokens** → if the app has its own token economy

DeDe does not enforce a specific token.

---

## **Example Backend Pseudocode**

```python
# user pays in BTC
btc_received = receive_btc_payment()

# convert to ERC-20 (via exchange or service)
erc20_amount = swap_btc_to_erc20(btc_received)

# interact with DeDe
approve(token, ESCROW_ADDRESS, erc20_amount)
parcel_id = parcel_core.createParcel(
    receiver=carrier_address,
    value=erc20_amount,
    ...
)

# wait for oracle signatures & completion
await_parcel_finalization(parcel_id)

# optionally convert payout back to BTC/XMR/etc.
payout = get_erc20_payout(parcel_id)
swap_to_btc_or_xmr(payout)
```

This backend template works with any payment source.

---

## **What DeDe Will Never Do (By Design)**

To preserve security and immutability, DeDe does **not**:

* Accept native BTC
* Accept native XMR
* Connect to non-EVM chains
* Perform bridging
* Custody wrapped assets
* Offer swap/FX logic

All of these remain **off-chain responsibilities** of the integrating platform.

---

## **Security Notes**

* Conversion must happen **before** DeDe escrow.
* Your backend should protect private keys and hot wallets.
* Keep ERC-20 tokens isolated from operational funds (recommended).
* Use your own risk policies for FX and slippage.

DeDe stays trustless; you handle the fiat/crypto UX.

---

## **Summary**

**DeDe Protocol is currency-agnostic.**
Any marketplace or app can build on top of it, regardless of what the end-users pay with.

They simply:

1. Accept payment in any currency
2. Convert value → ERC-20
3. Interact with DeDe as usual
4. Optionally convert payouts afterward

This model gives the ecosystem maximum flexibility while keeping DeDe protocol minimal, secure, and future-proof.

---
