<sub>under development • building with vibe coding</sub>

# Admin Gudang (Beta)

Offline Windows desktop application built with Flutter for warehouse inventory management. Features local SQLite storage (`sqflite_common_ffi`), mass data entry workflows, and Excel import/export.

## Features
- **Local & Offline**: Standalone SQLite relational database for reliability without internet connectivity.
- **Master Data**: Manage product categories (`master_kategori`) and items (`master_barang`).
- **Stock & Transactions**: Record stock entry and release (`Masuk` / `Keluar`) alongside initial monthly stock balances.
- **Excel Integration**: Import and export inventory records via `.xlsx` spreadsheets.
- **Desktop Workflow**: Keyboard-friendly navigation designed for fast, high-volume data entry.

---

## How to Run (Pre-built Windows Release)

1. Download the release archive `admin_gudang_windows_release.zip` from the [Releases section](https://github.com/FirgiK/-beta-/releases).
2. Extract the `.zip` file to any local folder on your Windows computer.
3. Open the extracted folder and run `admin_gudang.exe`.
4. No additional installation or internet access required.

---

## How to Run from Source

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install/windows) (desktop Windows target enabled)
- Visual Studio 2022 with the "Desktop development with C++" workload installed

### Steps
1. Clone this repository:
   ```bash
   git clone https://github.com/FirgiK/-beta-.git
   cd -beta-
   ```
2. Fetch dependencies:
   ```bash
   flutter pub get
   ```
3. Run the application:
   ```bash
   flutter run -d windows
   ```
4. Build a standalone release bundle:
   ```bash
   flutter build windows
   ```

---

*Open to feedback and recommendations for improvement.*

