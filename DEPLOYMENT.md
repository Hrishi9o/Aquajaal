# Aquajaal POS — Production Deployment Guide
**Distributor**: Yashodhar Enterprises  
**Location**: Shirva Rishali Complex, Main Road, Shirva, Udupi Dist – 574116  
**State**: Karnataka (Code: 29) | **HSN**: 2201  

---

## 1. Overview of the Production Package

This codebase is a **clean, production-grade, offline-first application** built for single-codebase cross-platform execution (Web & Android/iOS). It contains:
- **Zero placeholder/mock logic**: Real Hive persistence layer using IndexedDB on Web and native binary storage on Mobile.
- **Pre-seeded official catalog**: Exact 7 Aquajaal SKUs/variants and opening inventory counts.
- **Production Web Release Bundle**: Pre-compiled into `build/web` with tree-shaken assets, Yashodhar Enterprises branding, PWA manifest, and service worker.
- **Turnkey Configuration Files**: Ready-to-use configs for Firebase (`firebase.json`), Vercel (`vercel.json`), Netlify (`netlify.toml`), and Docker (`Dockerfile` + `nginx.conf`).

---

## 2. Option A: Local Counter PC / Laptop Deployment (Recommended for Shop)

If you are running the POS at the store counter on a Windows PC or laptop, no internet connection or external server is required.

### 1-Click Launch:
Simply double-click the included batch file in the project root:
```cmd
start_counter_app.bat
```
This will:
1. Launch the local production web server at `http://localhost:8080` (serving `build/web`).
2. Automatically open the POS counter in your default browser.

### Install as Desktop PWA App (Full-Screen Counter Mode):
1. Navigate to `http://localhost:8080` in Google Chrome or Microsoft Edge.
2. In the browser URL address bar, click the **Install** icon (or go to `Settings > Apps > Install Aquajaal POS`).
3. The app will launch in its own dedicated, chromeless window with the Yashodhar Enterprises icon on your desktop and taskbar, working 100% offline.

---

## 3. Option B: Deploy to Cloud Web Hosting

### 1. Firebase Hosting (1 Command)
```bash
# If not already logged in
npm install -g firebase-tools
firebase login
firebase init hosting # Select 'build/web' as public directory
firebase deploy --only hosting
```
*(The included `firebase.json` already contains optimal caching and SPA rewrites).*

### 2. Vercel
```bash
npm install -g vercel
vercel deploy --prod
```
*(Uses the included `vercel.json`).*

### 3. Netlify
```bash
npm install -g netlify-cli
netlify deploy --prod --dir=build/web
```
*(Uses the included `netlify.toml`).*

### 4. Docker / Self-Hosted Linux/Windows Server (Nginx)
A production multi-stage `Dockerfile` and `nginx.conf` are included:
```bash
# Build the Docker container
docker build -t aquajaal-pos:latest .

# Run container on port 80
docker run -d -p 80:80 --name aquajaal-pos-counter aquajaal-pos:latest
```
Access at `http://<your-server-ip>`.

---

## 4. Option C: Android Mobile / Tablet Deployment

To install directly onto an Android phone or counter tablet:

### 1. Build the Release APK:
```bash
flutter build apk --release
```
The compiled, optimized release APK will be generated at:
```
build/app/outputs/flutter-apk/app-release.apk
```

### 2. Install on Device:
Connect your Android tablet/phone via USB with Developer Options & USB Debugging enabled:
```bash
flutter install
# Or directly via adb:
adb install build/app/outputs/flutter-apk/app-release.apk
```

---

## 5. First-Time Counter Setup & Verification

1. **Verify Official Catalog**:
   - Open **Product Catalog** tab to view the 7 seeded Aquajaal items.
   - Prices:
     - 20L Dim Jar: ₹60.00
     - 20L Medium Jar: ₹80.00
     - 20L Best Jar: ₹100.00
     - 2L Case: ₹120.00
     - 1L Case: ₹110.00
     - 500ml Case: ₹135.00
     - 300ml Case: ₹145.00
2. **Configure Store Profile (Optional)**:
   - Go to **Settings** to update Phone, Email, or GSTIN if needed.
3. **Data Backup**:
   - At the end of every business day/week, tap **Export All Invoices (CSV)** in Settings or Dashboard to download the complete UTF-8 BOM CSV ledger for accounting.
