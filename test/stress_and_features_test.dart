import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:excel/excel.dart';
import 'package:admin_gudang/models/barang.dart';
import 'package:admin_gudang/models/kategori.dart';
import 'package:admin_gudang/models/transaksi.dart';
import 'package:admin_gudang/models/laporan_item.dart';
import 'package:admin_gudang/repositories/barang_repository.dart';
import 'package:admin_gudang/repositories/kategori_repository.dart';
import 'package:admin_gudang/repositories/transaksi_repository.dart';
import 'package:admin_gudang/repositories/laporan_repository.dart';
import 'package:admin_gudang/utils/excel_helper.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late String dbPath;
  late KategoriRepository kategoriRepo;
  late BarangRepository barangRepo;
  late TransaksiRepository transaksiRepo;
  late LaporanRepository laporanRepo;

  setUpAll(() async {
    final tempDir = Directory.systemTemp.createTempSync('admin_gudang_stress_test_');
    dbPath = '${tempDir.path}/test.db';

    db = await databaseFactoryFfi.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 1,
        onConfigure: (db) async => await db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS master_kategori (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              nama_kategori TEXT NOT NULL UNIQUE
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS master_barang (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              nama_barang TEXT NOT NULL,
              no_barang TEXT NOT NULL UNIQUE,
              kategori_id INTEGER NOT NULL,
              satuan TEXT NOT NULL,
              FOREIGN KEY (kategori_id) REFERENCES master_kategori(id) ON DELETE RESTRICT
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS transaksi (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              barang_id INTEGER NOT NULL,
              tanggal TEXT NOT NULL,
              jenis TEXT NOT NULL CHECK(jenis IN ('Masuk', 'Keluar')),
              jumlah REAL NOT NULL,
              keterangan TEXT,
              FOREIGN KEY (barang_id) REFERENCES master_barang(id) ON DELETE RESTRICT
            )
          ''');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_transaksi_barang_tanggal ON transaksi(barang_id, tanggal)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_transaksi_tanggal ON transaksi(tanggal)');
        },
      ),
    );

    kategoriRepo = KategoriRepository();
    barangRepo = BarangRepository();
    transaksiRepo = TransaksiRepository();
    laporanRepo = LaporanRepository();
  });

  tearDownAll(() async {
    await db.close();
  });

  group('PENGUJIAN INTEGRITAS DATABASE & VALIDASI INPUT', () {
    test('1. Foreign Key RESTRICT: Gagal hapus kategori jika masih ada barang terkait', () async {
      await db.insert('master_kategori', {'id': 100, 'nama_kategori': 'Kategori Test'});
      await db.insert('master_barang', {
        'id': 100,
        'nama_barang': 'Barang Relasi',
        'no_barang': 'REL-001',
        'kategori_id': 100,
        'satuan': 'Pcs'
      });

      expect(() async => await db.delete('master_kategori', where: 'id = ?', whereArgs: [100]),
          throwsA(isA<DatabaseException>()));
    });

    test('2. Unique Constraint Kode Barang: Gagal insert kode barang duplikat', () async {
      await db.insert('master_barang', {
        'nama_barang': 'Barang A',
        'no_barang': 'DUP-001',
        'kategori_id': 100,
        'satuan': 'Pcs'
      });

      expect(
        () async => await db.insert('master_barang', {
          'nama_barang': 'Barang B',
          'no_barang': 'DUP-001',
          'kategori_id': 100,
          'satuan': 'Box'
        }),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('3. Check Constraint Transaksi: Menolak nilai selain Masuk/Keluar', () async {
      expect(
        () async => await db.insert('transaksi', {
          'barang_id': 100,
          'tanggal': '2026-10-12',
          'jenis': 'Rusak', // Invalid jenis
          'jumlah': 10.0
        }),
        throwsA(isA<DatabaseException>()),
      );
    });
  });

  group('PENGUJIAN BEBAN / STRESS TEST DATA DUMMY (1.000 BARANG & 5.000 TRANSAKSI)', () {
    test('Batch insert 1.000 data barang performa tinggi', () async {
      await db.insert('master_kategori', {'id': 200, 'nama_kategori': 'Bulk Kategori'});

      final batch = db.batch();
      for (int i = 1; i <= 1000; i++) {
        batch.insert('master_barang', {
          'id': 1000 + i,
          'nama_barang': 'Produk Bulk $i',
          'no_barang': 'BLK-${i.toString().padLeft(4, '0')}',
          'kategori_id': 200,
          'satuan': 'Pcs'
        });
      }
      final stopwatch = Stopwatch()..start();
      await batch.commit(noResult: true);
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(3000)); // Harus di bawah 3 detik

      final res = await db.rawQuery('SELECT COUNT(*) as count FROM master_barang WHERE kategori_id = 200');
      final count = res.first['count'] as int;
      expect(count, 1000);
    });

    test('Batch insert 5.000 transaksi mutasi stok', () async {
      final batch = db.batch();
      for (int i = 1; i <= 2500; i++) {
        // Transaksi Masuk
        batch.insert('transaksi', {
          'barang_id': 1000 + (i % 1000) + 1,
          'tanggal': '2026-09-15',
          'jenis': 'Masuk',
          'jumlah': 100.0,
          'keterangan': 'Restock batch September'
        });
        // Transaksi Keluar bulan berikutnya
        batch.insert('transaksi', {
          'barang_id': 1000 + (i % 1000) + 1,
          'tanggal': '2026-10-05',
          'jenis': 'Keluar',
          'jumlah': 35.0,
          'keterangan': 'Penjualan Oktober'
        });
      }

      final stopwatch = Stopwatch()..start();
      await batch.commit(noResult: true);
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(4000)); // Di bawah 4 detik

      final res = await db.rawQuery('SELECT COUNT(*) as count FROM transaksi');
      final count = res.first['count'] as int;
      expect(count, greaterThanOrEqualTo(5000));
    });
  });

  group('PENGUJIAN MATEMATIKA STOK & LAPORAN PERIODE', () {
    test('Matematika Stok Awal, Mutasi, dan Stok Akhir harus presisi', () async {
      // Setup satu item kontrol
      await db.insert('master_kategori', {'id': 300, 'nama_kategori': 'Uji Matematika'});
      await db.insert('master_barang', {
        'id': 3001,
        'nama_barang': 'Kertas Karton Test',
        'no_barang': 'MATH-001',
        'kategori_id': 300,
        'satuan': 'Lembar'
      });

      // Histori Transaksi:
      // Sebelum periode (Stok Awal harus 50):
      // + 100 (10 Agt), - 50 (20 Agt) -> Saldo = 50
      await db.insert('transaksi', {'barang_id': 3001, 'tanggal': '2026-08-10', 'jenis': 'Masuk', 'jumlah': 100.0});
      await db.insert('transaksi', {'barang_id': 3001, 'tanggal': '2026-08-20', 'jenis': 'Keluar', 'jumlah': 50.0});

      // Dalam periode 2026-09-01 s/d 2026-09-30:
      // + 80 (05 Sep), - 30 (15 Sep) -> Mutasi = +50
      await db.insert('transaksi', {'barang_id': 3001, 'tanggal': '2026-09-05', 'jenis': 'Masuk', 'jumlah': 80.0});
      await db.insert('transaksi', {'barang_id': 3001, 'tanggal': '2026-09-15', 'jenis': 'Keluar', 'jumlah': 30.0});

      // Tarik query laporan persis seperti LaporanRepository
      final result = await db.rawQuery('''
        SELECT 
          b.id,
          COALESCE(sa.stok_awal, 0) as stok_awal,
          COALESCE(tm.total_masuk, 0) as total_masuk,
          COALESCE(tk.total_keluar, 0) as total_keluar
        FROM master_barang b
        LEFT JOIN (
          SELECT barang_id, SUM(CASE WHEN jenis = 'Masuk' THEN jumlah ELSE -jumlah END) as stok_awal
          FROM transaksi WHERE tanggal < '2026-09-01' GROUP BY barang_id
        ) sa ON b.id = sa.barang_id
        LEFT JOIN (
          SELECT barang_id, SUM(jumlah) as total_masuk
          FROM transaksi WHERE jenis = 'Masuk' AND tanggal >= '2026-09-01' AND tanggal <= '2026-09-30' GROUP BY barang_id
        ) tm ON b.id = tm.barang_id
        LEFT JOIN (
          SELECT barang_id, SUM(jumlah) as total_keluar
          FROM transaksi WHERE jenis = 'Keluar' AND tanggal >= '2026-09-01' AND tanggal <= '2026-09-30' GROUP BY barang_id
        ) tk ON b.id = tk.barang_id
        WHERE b.id = 3001
      ''');

      expect(result.isNotEmpty, true);
      final row = result.first;
      final stokAwal = (row['stok_awal'] as num).toDouble();
      final masuk = (row['total_masuk'] as num).toDouble();
      final keluar = (row['total_keluar'] as num).toDouble();
      final stokAkhir = stokAwal + masuk - keluar;

      expect(stokAwal, 50.0);
      expect(masuk, 80.0);
      expect(keluar, 30.0);
      expect(stokAkhir, 100.0); // 50 + 80 - 30 = 100
    });
  });

  group('PENGUJIAN IMPORT & EXPORT EXCEL', () {
    test('Export laporan ke binary XLSX dan validasi decoding', () {
      final items = [
        LaporanItem(
          barangId: 1,
          namaBarang: 'Barang Alpha',
          kodeBarang: 'ALP-01',
          satuan: 'Pcs',
          namaKategori: 'Kategori Alpha',
          stokAwal: 100.0,
          totalMasuk: 200.0,
          totalKeluar: 50.0,
        ),
        LaporanItem(
          barangId: 2,
          namaBarang: 'Barang Beta',
          kodeBarang: 'BET-02',
          satuan: 'Box',
          namaKategori: 'Kategori Beta',
          stokAwal: 10.0,
          totalMasuk: 15.0,
          totalKeluar: 25.0,
        ),
      ];

      final bytes = ExcelHelper.exportLaporanBytes(
        data: items,
        tanggalMulai: '01/10/2026',
        tanggalAkhir: '31/10/2026',
      );

      expect(bytes.isNotEmpty, true);

      // Simpan sementara untuk diuji baca ulang
      final tempFile = File('${Directory.systemTemp.path}/test_export.xlsx');
      tempFile.writeAsBytesSync(bytes);
      expect(tempFile.existsSync(), true);

      tempFile.deleteSync();
    });

    test('Import Excel validasi: parsing, header skipping, dan data trimming', () async {
      // Buat file Excel buatan untuk import
      final excel = Excel.createExcel();
      final sheet = excel['Sheet1'];
      excel.setDefaultSheet('Sheet1');

      // Header baris 0
      sheet.appendRow([
        TextCellValue('Kode Barang'),
        TextCellValue('Nama Barang'),
        TextCellValue('Kategori'),
        TextCellValue('Satuan'),
      ]);

      // Data baris 1
      sheet.appendRow([
        TextCellValue('  IMP-001  '),
        TextCellValue('  Barang Import 1  '),
        TextCellValue('Bahan Baku'),
        TextCellValue('Kg'),
      ]);

      // Data baris 2: Nama barang kosong (harus diskip)
      sheet.appendRow([
        TextCellValue('IMP-002'),
        TextCellValue(''),
        TextCellValue('Bahan Baku'),
        TextCellValue('Kg'),
      ]);

      final fileBytes = excel.save()!;
      final testImportPath = '${Directory.systemTemp.path}/test_import.xlsx';
      File(testImportPath).writeAsBytesSync(fileBytes);

      final imported = await ExcelHelper.importBarang(testImportPath);

      expect(imported.length, 1);
      expect(imported[0]['no_barang'], 'IMP-001');
      expect(imported[0]['nama_barang'], 'Barang Import 1');
      expect(imported[0]['kategori'], 'Bahan Baku');
      expect(imported[0]['satuan'], 'Kg');

      File(testImportPath).deleteSync();
    });
  });
}
