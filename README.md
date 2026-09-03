# Aquajaal POS — Billing, Stock & Daily Sales Management App

A production-grade, offline-first Point of Sale (POS), product catalog manager, inventory tracking, and daily sales analytics application developed for **Yashodhar Enterprises** (Authorized Packaged Drinking Water Distributor, Shirva, Karnataka) distributing **Aquajaal™** packaged drinking water with added minerals.

Built with a single Flutter codebase supporting:
- **Web (Counter Laptop/PC & PWA)**: Full keyboard/mouse optimized UI with IndexedDB offline persistence, browser print dialog, Excel-compatible CSV export with UTF-8 BOM, and PDF invoice downloads.
- **Mobile & Tablet (Android/iOS)**: Touch-optimized counter billing with local binary persistence, low-stock alerts, system print spooler/Bluetooth printer support, and pre-compiled release APK.
- **Real-Time Cloud Sync**: Automatic bidirectional sync across multiple family devices (counter PC, father's phone, brother's phone) using Firebase Realtime Database while retaining 100% offline-first reliability.

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

### 1. Point of Sale (POS) Billing & High-Speed Checkout
- **Instant Numeric Input**: Tactile `+` / `-` steppers, plus an on-screen **Numeric Keypad & Direct Typeable Field** allowing cashiers to type bulk quantities (e.g. 60 cases) in under 2 seconds.
- **Adaptive Auto-Fitting Price Display**: Price ranges cleanly format as `₹60 – ₹100` (auto-scaling to fit any card or screen size without overflowing).
- **Low-Stock Alert on Add**: When adding an item that is at or below its low-stock threshold, an immediate, high-contrast modal displays: *"Item has only X units left (Threshold: Y). Add to cart anyway?"* with Cancel or Confirm & Add options.
- **Indian GST Tax Invoice Layout**:
  - Distributor details: Yashodhar Enterprises, Shirva Rishali Complex, Main Road, Shirva, Udupi Dist – 574116.
  - State & POS: Karnataka (State Code: 29).
  - Unique Sequential Invoice Numbers: `YE-YYYY-MMDD-XXXX` (e.g. `YE-2026-0903-0001`).
  - Itemized table with HSN code 2201, unit price, quantity, taxable value, and line total.
  - **Amount in Words**: Fully compliant Indian numbering format (*"Rupees Two Hundred and Eighty Only"*).
  - Print & Export actions: native browser print dialog on web, system print spooler & PDF share on mobile.

### 2. Product Catalog Management
- **Dedicated Catalog Screen**: Add, edit, and archive products and variants at any time without needing code changes.
- **Price Immutability**: Editing a product's price only updates future sales; past invoices permanently retain the exact `priceAtSale` charged at the time of purchase.
- **Archive / Soft Delete**: Discontinued products can be archived with one tap so they disappear from the POS billing grid while preserving historical invoices, sales reports, and stock movement logs intact. Archived products can be restored at any time.
- **Permanent Delete**: Only permitted if a product has zero sales history, synchronized across local storage and cloud database.

### 3. Real-Time Stock Management & Audit Trail
- **Live Inventory Overview**: On-hand counts for every jar variant and case SKU with color-coded badges (*Green: Healthy*, *Amber: Low Stock*, *Red: Out of Stock*).
- **Auto-Deduction on Sale**: Inventory decrements in real-time the instant an invoice is generated.
- **Negative Stock Warning & Override**: If a sale exceeds current stock, the cashier is alerted with exact deficit quantities and can choose to *Allow Sale & Override* or adjust the cart.
- **Factory Inward Intake**: Quick `+ Inward Stock` dialog to record received shipments from the plant with delivery note/batch references and notes.
- **Stock Adjustment**: Modal for recording breakage, leakages, or physical audit reconciliations.
- **Audit Movement Log**: 100% traceable chronological ledger recording timestamp, type (*Inward Intake*, *Bill Sale*, *Adjustment*), quantity delta, previous balance → new balance, and invoice/batch reference.

### 4. Daily Sales Analytics Dashboard
- **Period Filtering**: *Today*, *Yesterday*, *Last 7 Days*, *This Month*, *All Time*, and **Custom Date Range Picker**.
- **KPI Summary Cards**: Total Revenue (`₹#,##,##0.00`), Invoices Generated, Water Units Sold, Average Bill Value.
- **Top 3 Products by Revenue**: Shows Name, Qty Sold, and formatted Revenue (`₹X,XXX.XX`).
- **Top 3 Products by Quantity**: Shows Name, Units Sold, and Revenue (`₹X,XXX.XX`).
- **Visual Revenue Trend**: Interactive bar chart displaying sales revenue breakdown over hourly or daily time buckets.
- **Data Export & Reporting**:
  - **Export to CSV**: Generates `YE_Invoices_YYYY-MM-DD_HHmmss.csv` encoded in UTF-8 with BOM (`\uFEFF`) so Microsoft Excel renders the `₹` symbol cleanly without corrupt characters.
  - **Sales Summary Report (PDF)**: Generates an A4 report with Yashodhar letterhead, summary KPIs, top-selling products table, and daily breakdown table.

### 5. Multi-Device Real-Time Cloud Sync (Firebase RTDB)
- Seamless real-time and background sync between the shop counter PC and mobile phones (e.g. Brother's phone & Father's phone).
- **Offline-First Resilience**: If internet is unavailable at the counter, bills continue saving locally and sync to the cloud automatically as soon as connection is restored.
- **Live Sync Indicator**: Visual header pill showing status: *Synced*, *Syncing*, *Offline*, or *Error*.

### 6. Settings, Backup & Data Maintenance
- Configurable distributor profile (name, address, phone, email, GSTIN).
- Configurable default GST rate and global default low-stock threshold.
- One-tap switch between **Light Theme** and **Dark Theme** (persisted).
- **Clear Invoices Only**: Purge test transactions and reset invoice numbering to `#1` without touching your custom product catalog or store profile.
- **Reset Factory Defaults**: Fully wipes local Hive boxes and remote Firebase RTDB collections, restoring the official Aquajaal demo catalog and opening stock with an interactive progress indicator.

---

## Number Formatting — Indian Rupee (₹) Standard
- All amounts strictly display using the standard Indian locale pattern: `₹#,##,##0.00` (e.g. `₹60.00`, `₹1,00,000.00`, `₹2,50,000.50`).
- Comma placement: after the first 3 digits from right, then every 2 digits (lakhs & crores).
- Rupee symbol: Always uses literal Unicode `\u20B9` (₹), never `Rs.` or HTML entities.

---

## Deployment & Running

### 1. Local Counter PC / Laptop (Recommended for Shop)
Simply double-click the batch file in the project root:
```cmd
start_counter_app.bat
```
This launches the local production web server at `http://localhost:8080` and opens the POS counter in your default browser. Can be installed as a chromeless desktop PWA.

### 2. Android Phone / Counter Tablet (Direct Sideload)
The production-ready release APK is compiled and available in the project root:
```
Aquajaal-Counter-POS.apk
```
Copy it to any Android device via WhatsApp, Google Drive, or USB cable, tap to install, and run directly.

To rebuild the APK from source:
```bash
flutter build apk --release
```

### 3. Deploy to Vercel (Cloud Hosting)
The repository includes automated Vercel build configuration in `vercel.json`:
1. Go to **[vercel.com/new](https://vercel.com/new)**.
2. Import the `Hrishi9o/Aquajaal` repository.
3. Click **Deploy**. Vercel will automatically install Flutter, build the web app, and deploy it to a fast global CDN.

Or deploy via terminal using Vercel CLI:
```bash
vercel login
vercel --prod
```

### 4. Run Automated Tests
```bash
flutter test
```
Runs all 15+ automated end-to-end integration tests (POS billing, tax calculations, number to words, stock auto-deduction, invoice clearing, factory reset, product management, and CSV export).
