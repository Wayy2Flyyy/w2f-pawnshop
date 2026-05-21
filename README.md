The best NPC-owned dynamic pawnshop

A realistic, NPC-owned pawnshop for FiveM with **player-driven stock**, a **five-tier loyalty system**, **low-stock demand pricing**, and a **level-gated black market**. Built for modern ox stacks (ox_lib, ox_target, ox_inventory, oxmysql) with ESX and Qbox support.

**Current version:** `0.5.0` · Resource path: [`w2f-pawnshop/`](w2f-pawnshop/)

## Preview 
<img width="1280" height="767" alt="image" src="https://github.com/user-attachments/assets/57068444-10a4-434c-b310-f7ebf1a14a37" />
<img width="355" height="311" alt="image" src="https://github.com/user-attachments/assets/8bb79c8f-6af2-47ba-a1ff-1a90c5c3f916" />
<img width="871" height="581" alt="image" src="https://github.com/user-attachments/assets/4183da0e-77bc-47d8-b95d-66b52a8d7812" />


---

## Overview

Players interact with **Vincent**, the pawnshop owner, to sell valuables, buy from live shelves, and browse stock. Everything the shop buys from players becomes stock other players can purchase. Reputation (loyalty) improves prices and unlocks categories. At **level 4+**, Vincent can point players to **Silas**, a separate black market dealer with illicit goods and its own MySQL stock.

All prices, stock counts, and payouts are **validated on the server**. The NUI never sends trusted prices or item definitions.

```text
Player sells item  →  money + XP  →  pawnshop stock increases
Player buys item   →  money taken →  pawnshop stock decreases
Low stock          →  higher sell payouts + demand dialog hints
Loyalty level 4+   →  black market dealer + exclusive stock tiers
```

---

## Features

| System | Description |
|--------|-------------|
| **NPC pawnshop** | Frozen, invincible owner ped with ox_target (*Talk to Pawnshop Owner*) |
| **Custom NUI** | Dark premium UI — conversation, sell panel, storefront with cart, stock view |
| **Live stock** | MySQL-backed `w2f_pawnshop_stock`; seeded from config, updated on every trade |
| **Sell flow** | Only owned + catalog items; loyalty/demand bonuses; margin-safe payouts |
| **Buy flow** | Grid + cart checkout; loyalty discounts; category and level locks |
| **Loyalty (5 tiers)** | Persistent XP, level-ups, greetings, sell bonus %, buy discount % |
| **Demand** | Items at or below stock threshold pay more and earn bonus XP; NPC mentions them |
| **Black market** | Second ped, separate stock table, level 4/5 item gates, buy-only storefront |
| **Framework bridge** | Auto-detect ESX / Qbox; isolated money handling |
| **Anti-exploit** | Transaction locks, quantity sanitization, server-side pricing, source checks |

---

## Requirements

| Dependency | Purpose |
|------------|---------|
| [ox_lib](https://github.com/overextended/ox_lib) | Callbacks, notifications, UI helpers |
| [ox_target](https://github.com/overextended/ox_target) | Ped interactions |
| [ox_inventory](https://github.com/overextended/ox_inventory) | Player items, add/remove on trades |
| [oxmysql](https://github.com/overextended/oxmysql) | Stock, loyalty, transactions |
| **ESX** (`es_extended`) or **Qbox** (`qbx_core` / `qb-core`) | Player money (required for payouts) |

- **Lua 5.4** enabled (`lua54 'yes'` in manifest)
- **MySQL** database (MariaDB compatible)

---

## Installation

### 1. Download and place the resource

Copy the `w2f-pawnshop` folder into your server `resources` directory.

```text
resources/
└── w2f-pawnshop/
    ├── fxmanifest.lua
    ├── config.lua
    ├── client/
    ├── server/
    ├── shared/
    ├── web/
    └── sql/
```

### 2. Database

Tables are created automatically on resource start from [`w2f-pawnshop/sql/install.sql`](w2f-pawnshop/sql/install.sql). You can also run that file manually once:

| Table | Purpose |
|-------|---------|
| `w2f_pawnshop_stock` | Pawnshop shelf quantities |
| `w2f_pawnshop_blackmarket_stock` | Black market quantities |
| `w2f_pawnshop_transactions` | Sell/buy/black market audit log |
| `w2f_pawnshop_loyalty` | Per-player XP, level, trade totals |

Ensure **oxmysql** is configured and starts before this resource.

### 3. ox_inventory items

Register every item name from:

- [`shared/items.lua`](w2f-pawnshop/shared/items.lua) — 10 pawnshop goods (e.g. `gold_watch`, `silver_ring`)
- [`shared/blackmarket.lua`](w2f-pawnshop/shared/blackmarket.lua) — 10 black market goods (e.g. `dirty_money`, `hacking_usb`)

Item **keys must match** exactly between config and your inventory item definitions.

### 4. server.cfg

Start dependencies first, then the resource:

```cfg
ensure ox_lib
ensure ox_target
ensure ox_inventory
ensure oxmysql

ensure w2f-pawnshop
```

### 5. Configure

Edit [`w2f-pawnshop/config.lua`](w2f-pawnshop/config.lua):

- `Config.Ped.coords` — pawnshop owner location
- `Config.BlackMarket.Ped.coords` — dealer location (near alley / back area)
- `Config.Framework` — leave `nil` for auto-detect, or set `'esx'` / `'qbox'`
- `Config.Debug` — `true` for console debug lines

Restart the resource after changes.

---

## Player experience

### Pawnshop owner (Vincent)

1. **Talk to Pawnshop Owner** (ox_target)
2. Dialog shows **loyalty strip**, tier-based **greeting**, and optional **low-stock hints**
3. Options:
   - **Sell Items** — list of owned catalog items with bonuses and demand tags
   - **Buy Items** — storefront (in-stock only) with cart checkout
   - **View Stock** — same UI, view-only (no cart)
   - **Black Market Contact** — appears at loyalty **level 4+**; directions to the dealer
   - **Nevermind** — close

### Black market dealer (Silas)

- Requires pawnshop loyalty **level 4+**
- Target: **Speak to Black Market Dealer** (hidden below level 4 if `hideTargetBelowLevel` is true)
- Darker NUI storefront; **buy-only**; separate prices and stock
- **Level 5** items are marked *Inner circle* and need loyalty 5

---

## Loyalty tiers

Defined in [`shared/loyalty.lua`](w2f-pawnshop/shared/loyalty.lua). XP is earned on pawnshop sells and buys (configurable multipliers). Data persists in `w2f_pawnshop_loyalty`.

| Level | Label | XP required | Sell bonus | Buy discount | Black market |
|------:|-------|------------:|-----------:|-------------:|:------------:|
| 1 | Unknown Customer | 0 | 0% | 0% | — |
| 2 | Regular | 100 | 3% | 2% | — |
| 3 | Trusted Seller | 300 | 6% | 4% | — |
| 4 | Connected | 750 | 10% | 6% | Unlock |
| 5 | Inner Circle | 1500 | 15% | 10% | Unlock + exclusive BM items |

**Category unlocks** by tier (e.g. art at level 3). Individual items can also set `minLoyaltyToBuy` in the pawnshop catalog.

---

## Low-stock demand

When pawnshop stock for an item is **at or below** `Config.LowStock.threshold` (default `3`):

- Sell price gets an extra **percent bonus** (`sellBonusPercent`)
- Loyalty XP uses **`xpBonusMultiplier`**
- Vincent may append a short demand line to his greeting (up to `Config.DemandedItemLimit` items)

Demand is evaluated when menus open — no background polling loops.

---

## Pricing rules (server)

| Action | Formula |
|--------|---------|
| **Sell** | `baseSellPrice` + loyalty bonus + demand bonus, capped so payout stays below `buyPrice - MinimumProfitMargin` |
| **Buy** | `buyPrice` minus loyalty discount % |
| **Black market buy** | Fixed `buyPrice` from black market catalog (no client input) |

The margin rule prevents sell/buy arbitrage loops.

---

## Configuration reference

Main file: [`w2f-pawnshop/config.lua`](w2f-pawnshop/config.lua)

| Option | Default | Notes |
|--------|---------|-------|
| `Config.Debug` | `false` | Tagged `Dbg.Print` output |
| `Config.InteractionDistance` | `2.5` | ox_target range |
| `Config.MinimumProfitMargin` | `75` | Min gap between buy and sell prices |
| `Config.DefaultBuyAccount` / `DefaultSellAccount` | `'money'` | Qbox maps to `cash` in bridge |
| `Config.MaxSellPerAction` | `50` | Per sell click |
| `Config.CartMaxPerCheckout` | `25` | Max total units per checkout |
| `Config.HideLockedItems` | `false` | Hide vs show locked buy rows |
| `Config.AllowViewingOutOfStock` | `true` | View-stock mode |
| `Config.BlackMarket.minAccessLevel` | `4` | Dealer + contact option |
| `Config.BlackMarket.hideTargetBelowLevel` | `true` | Hide dealer target if too low |

Catalogs (prices, stock seeds, XP, loyalty gates) live in `shared/items.lua` and `shared/blackmarket.lua`.

---

## Project structure

```text
w2f-pawnshop/
├── config.lua                 # All tunables (documented in-file)
├── fxmanifest.lua
├── client/
│   ├── main.lua               # Bootstrap both peds
│   ├── ped.lua / target.lua   # Pawnshop owner
│   ├── blackmarket_ped.lua    # Dealer spawn
│   ├── blackmarket_target.lua
│   ├── nui.lua                # NUI callbacks ↔ server
│   ├── notify.lua             # ox_lib notifications
│   └── state.lua              # Client cache (e.g. BM access)
├── server/
│   ├── main.lua               # lib.callback registrations
│   ├── transactions.lua       # Pawnshop sell/buy
│   ├── blackmarket.lua        # Black market checkout
│   ├── stock.lua / blackmarket_stock.lua
│   ├── loyalty.lua / pricing.lua / demand.lua / dialog.lua
│   ├── security.lua           # Locks, quantity validation
│   ├── bridge.lua             # ESX / Qbox money
│   └── database.lua           # Schema init
├── shared/
│   ├── items.lua              # Pawnshop catalog
│   ├── blackmarket.lua        # Black market catalog
│   ├── loyalty.lua            # Tier definitions
│   └── bridge.lua             # Framework detection
├── web/
│   ├── index.html / style.css
│   ├── app.js                 # Dialog, sell, routing
│   └── storefront.js          # Grid + cart (pawnshop & BM themes)
└── sql/install.sql
```

---

## Server callbacks

| Callback | Description |
|----------|-------------|
| `w2f-pawnshop:getDialog` | Greeting, loyalty profile, demand list, BM unlock |
| `w2f-pawnshop:getSellMenu` | Sellable owned items + prices |
| `w2f-pawnshop:sellItem` | Process one sell |
| `w2f-pawnshop:getStorefront` | Buy or view-stock rows |
| `w2f-pawnshop:checkout` | Pawnshop cart purchase |
| `w2f-pawnshop:getBlackMarket` | Black market storefront |
| `w2f-pawnshop:blackMarketCheckout` | Black market cart (item names + quantities only) |
| `w2f-pawnshop:canAccessBlackMarket` | Access check for dealer target |

---

## Security

Handled in [`server/security.lua`](w2f-pawnshop/server/security.lua) and transaction modules:

- Valid player `source` on every action
- Integer quantities only (no negatives, zero, decimals, or huge values)
- Per-player **transaction lock** to block checkout/sell spam
- Item names must exist in the correct catalog
- Stock re-checked at checkout from MySQL
- Black market blocked below configured loyalty level
- Prices computed only on the server

---

## Troubleshooting

| Issue | Check |
|-------|--------|
| Resource starts but no ped | `Config.Ped.coords`, model name, server console errors |
| No money on sell/buy | ESX/Qbox running; `Config.Framework`; `DefaultSellAccount` / `DefaultBuyAccount` |
| Items missing in UI | Item not in ox_inventory or name mismatch with catalog |
| Database errors | oxmysql connection; run `sql/install.sql`; check table prefixes |
| Black market target missing | Player loyalty level ≥ 4 in `w2f_pawnshop_loyalty` |
| Prices look wrong | Server recalculates on each open — clear client cache, verify `MinimumProfitMargin` |
| Debug logging | Set `Config.Debug = true` and watch for `[w2f-pawnshop][...]` lines |

---

## Credits

**Author:** Wayy2Flyyy
**Resource:** `w2f-pawnshop`  
Built for communities using Overextended resources and ESX/Qbox frameworks.
