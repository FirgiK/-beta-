import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static Database? _database;
  static const String _dbName = 'admin_gudang.db';
  static const int _dbVersion = 1;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    sqfliteFfiInit();
    final databaseFactory = databaseFactoryFfi;

    final appDir = await getApplicationSupportDirectory();
    final dbPath = p.join(appDir.path, _dbName);

    return await databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: _dbVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
      ),
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
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

    await db.execute('''
      CREATE TABLE IF NOT EXISTS stok_awal (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        barang_id INTEGER NOT NULL,
        periode_bulan TEXT NOT NULL,
        jumlah REAL NOT NULL,
        FOREIGN KEY (barang_id) REFERENCES master_barang(id) ON DELETE RESTRICT,
        UNIQUE(barang_id, periode_bulan)
      )
    ''');

    await db.execute('CREATE INDEX IF NOT EXISTS idx_transaksi_barang_tanggal ON transaksi(barang_id, tanggal)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_transaksi_tanggal ON transaksi(tanggal)');

    // Seed kategori awal
    final kategoriAwal = ['Bahan Baku', 'Obat', 'Kado', 'Pribadi'];
    for (final nama in kategoriAwal) {
      await db.insert('master_kategori', {'nama_kategori': nama});
    }
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Migrasi di sini untuk versi selanjutnya
  }
}
