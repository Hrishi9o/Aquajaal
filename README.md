# Aquajaal POS — Billing, Stock & Daily Sales Management App

A production-grade, offline-first Point of Sale (POS), product catalog manager, inventory tracking, and daily sales analytics application developed for **Yashodhar Enterprises** (Authorized Packaged Drinking Water Distributor, Shirva, Karnataka) distributing **Aquajaal™** packaged drinking water with added minerals.

Built with a single Flutter codebase supporting:
- **Web (Counter Laptop/PC & PWA)**: Full keyboard/mouse optimized UI with IndexedDB offline persistence, browser print dialog, Excel-compatible CSV export with UTF-8 BOM, and PDF invoice downloads.
- **Mobile & Tablet (Android/iOS)**: Touch-optimized counter billing with local binary persistence, low-stock alerts, and system print spooler/Bluetooth printer support.

---

## Brand Identity & Design System

The visual identity was derived directly from the Yashodhar Enterprises distributor badge and Aquajaal product logo:

| Design Token | Value | Applied To |
|---|---|---|
| **Primary Brand Blue** | `#1E4CB8` | App header, primary buttons, invoice highlights, key stats |
| **Primary Dark / Navy** | `#0F318A` | Dark theme surfaces, text contrast, invoice watermarks |
| **Accent Lime Green** | `#98C528` / `#8DC63F` | CTAs, stock intake, healthy stock badges, successful checkouts |
| **Warning / Low Stock** | `#F59E0B` | Low-stock inventory alerts, addition warnings, and deficit flags |
| **Surface Light** | `#F8FAFC` & `#E8F3FD` | Water-tinted background, crisp card surfaces |
| **Surface Dark** | `#0B132B` & `#131E3D` | Sleek dark mode for low-light or evening counter shifts |
| **Typography** | `Plus Jakarta Sans` & `Outfit` | Bold readable numerals for totals & crisp table data |

### Logo Assets Included
- `assets/images/logo_yashodhar.png`: Yashodhar Enterprises company badge (used as app icon, sidebar badge, and invoice letterhead).
- `assets/images/logo_aquajaal.png`: Aquajaal product brand logo (used on POS catalog banners and item details).

---

## Pre-loaded Product Catalog & Pricing

The application comes pre-seeded with the exact catalog and opening stock:

| Product Name | Quality Variant | Price (₹) | HSN Code | Default Initial Stock |
|---|---|---|---|---|
| **Aquajaal JAR 20 Ltr Filling** | Dim Jar | **₹60.00** | 2201 | 120 jars (Alert: ≤25) |
| **Aquajaal JAR 20 Ltr Filling** | Medium Jar | **₹80.00** | 2201 | 180 jars (Alert: ≤30) |
| **Aquajaal JAR 20 Ltr Filling** | Best Jar | **₹100.00** | 2201 | 95 jars (Alert: ≤20) |
| **Aquajaal Premium 2000ml (2L case)** | — (Case SKU) | **₹120.00** | 2201 | 75 cases (Alert: ≤15) |
| **Aquajal SN Shrink Pack 1000ml (1L case)** | — (Case SKU) | **₹110.00** | 2201 | 140 cases (Alert: ≤25) |
| **Aquajal SN Shrink Pack 500ml (0.5L case)** | — (Case SKU) | **₹135.00** | 2201 | 85 cases (Alert: ≤20) |
| **Aquajal SN Shrink Pack 300ml (300ml case)**| — (Case SKU) | **₹145.00** | 2201 | 110 cases (Alert: ≤20) |

---

## Core Features

### 1. Product Catalog Management
- **Dedicated Catalog Screen**: Add, edit, and archive products and variants at any time without needing code changes.
- **Price Immutability**: Editing a product's price only updates future sales; past invoices permanently retain the exact `priceAtSale` charged at the time of purchase.
- **Archive / Soft Delete**: Discontinued products can be archived with one tap so they disappear from the POS billing grid while preserving historical invoices, sales reports, and stock movement logs intact. Archived products can be restored at any time.
- **Permanent Delete**: Only permitted if a product has zero sales history, protected by a safety confirmation step.

### 2. Point of Sale (POS) Billing & High-Speed Checkout
- **Instant Numeric Input**: Tactile `+` / `-` steppers, plus an on-screen **Numeric Keypad & Direct Typeable Field** allowing cashiers to type bulk quantities (e.g. 60 cases) in under 2 seconds.
- **Low-Stock Alert on Add**: When adding an item that is at or below its low-stock threshold, an immediate, high-contrast modal displays: *"Item has only X units left (Threshold: Y). Add to cart anyway?"* with Cancel or Confirm & Add options.
- **Indian GST Tax Invoice Layout**:
  - Distributor details: Yashodhar Enterprises, Shirva Rishali Complex, Main Road, Shirva, Udupi Dist – 574116.
  - State & POS: Karnataka (State Code: 29).
  - Unique Sequential Invoice Numbers: `YE-YYYY-MMDD-XXXX` (e.g. `YE-2026-0903-0001`).
  - Itemized table with HSN/SAC code 2201, unit price, quantity, taxable value, and line total.
  - **Amount in Words**: Fully compliant Indian numbering format (*"Rupees Two Hundred and Eighty Only"*).
  - Print & Export actions: native browser print dialog on web, system print spooler & PDF share on mobile.

### 3. Real-Time Stock Management & Audit Trail
- **Live Inventory Overview**: On-hand counts for every jar variant and case SKU with color-coded badges (*Green: Healthy*, *Amber: Low Stock*, *Red: Out of Stock*).
- **Auto-Deduction on Sale**: Inventory decrements in real-time the instant an invoice is generated.
- **Negative Stock Warning & Override**: If a sale exceeds current stock, the cashier is alerted with exact deficit quantities and can choose to *Allow Sale & Override* or adjust the cart.
- **Factory Inward Intake**: Quick `+ Inward Stock` dialog to record received shipments from the plant with delivery note/batch references and notes.
- **Stock Adjustment**: Modal for recording breakage, leakages, or physical audit reconciliations.
- **Audit Movement Log**: 100% traceable chronological ledger recording timestamp, type (*Inward Intake*, *Bill Sale*, *Adjustment*), quantity delta, previous balance → new balance, and invoice/batch reference.

### 4. Daily Sales Analytics Dashboard
- **Period Filtering**: *Today*, *Yesterday*, *This Week*, *This Month*, *All Time*, and **Custom Date Range Picker**.
- **KPI Summary Cards**: Total Revenue (`₹#,##,##0.00`), Invoices Generated, Water Units Sold, Average Bill Value.
- **Top 3 Products by Revenue**: Shows Name, Qty Sold, and formatted Revenue (`₹X,XXX.XX`).
- **Top 3 Products by Quantity**: Shows Name, Units Sold, and Revenue (`₹X,XXX.XX`).
- **Visual Revenue Trend**: Interactive bar chart displaying sales revenue breakdown over hourly or daily time buckets.
- **Data Export & Reporting**:
  - **Export to CSV**: Generates `YE_Invoices_YYYY-MM-DD_HHmmss.csv` encoded in UTF-8 with BOM (`\uFEFF`) so Microsoft Excel renders the `₹` symbol cleanly without corrupt characters.
  - **Sales Summary Report (PDF)**: Generates an A4 report with Yashodhar letterhead, summary KPIs, top-selling products table, and daily breakdown table.

### 5. Settings & Theme Customization
- Configurable distributor profile (name, address, phone, email, GSTIN).
- Configurable default GST rate and global default low-stock threshold.
- One-tap switch between **Light Theme** and **Dark Theme** (persisted).
- **Factory Reset**: Clear database and restore initial demo catalog at any time.

---

## Number Formatting — Indian Rupee (₹) Standard
- All amounts strictly display using the standard Indian locale pattern: `₹#,##,##0.00` (e.g. `₹60.00`, `₹1,00,000.00`, `₹2,50,000.50`).
- Comma placement: after the first 3 digits from right, then every 2 digits (lakhs & crores).
- Rupee symbol: Always uses literal Unicode `\u20B9` (₹), never `Rs.` or HTML entities.

---

## Cross-Platform Local Persistence

- **Database Engine**: **Hive** (`hive: ^2.2.3` + `hive_flutter: ^1.1.0`).
- **Web Build**: Automatically stores all boxes inside the browser's native **IndexedDB** engine. Survives browser refresh, tab closing, computer reboots, and operates 100% offline.
- **Mobile Build**: Stores high-performance binary boxes in the device's local application documents directory.
- **PWA Ready**: Includes `web/manifest.json` configured for standalone installation on Windows/Mac/Android Chrome.

---

## How to Run Locally

### Prerequisites
- Flutter SDK 3.32+ installed and added to `PATH`.
- Chrome (for web) or an Android device/emulator.

### 1. Run on Web (Browser)
```bash
cd e:\Aquajaal
flutter pub get
flutter run -d chrome
```
*Or build and serve the production PWA bundle:*
```bash
flutter build web --release
python -m http.server 8080 --directory build/web
# Open http://localhost:8080 in Chrome or Edge
```

### 2. Run on Mobile (Android Emulator / Device)
```bash
cd e:\Aquajaal
flutter run -d android
```

### 3. Run Automated Tests
```bash
flutter test
```
*Runs all unit and end-to-end integration tests (POS billing, tax calculations, number to words, stock auto-deduction, product management, and CSV export).*

---

## Future: Multi-Device Sync (Roadmap)

This application is designed specifically as a single-counter, offline-first application. For Yashodhar Enterprises' daily counter volume (a few hundred invoices per day), the local Hive embedded database provides instant, zero-latency response with zero monthly cloud bills.

If a second counter, delivery vehicle tablet, or multi-location warehouse is ever needed in the future:
1. An offline-first sync layer (such as **Firebase Cloud Firestore** or **Supabase**) can be added.
2. The existing `LocalDbService` and `StockProvider` repositories already isolate all database access, allowing a background sync service to synchronize transactions whenever an internet connection is available without rewriting the core POS or UI code.
