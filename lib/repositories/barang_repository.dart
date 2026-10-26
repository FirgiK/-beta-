import 'package:admin_gudang/database/database_helper.dart';
import 'package:admin_gudang/models/barang.dart';

class BarangRepository {
  static const String _selectWithStok = '''
    SELECT b.*, k.nama_kategori,
      COALESCE(st.total_stok, 0) AS stok_saat_ini
    FROM master_barang b
    LEFT JOIN master_kategori k ON b.kategori_id = k.id
    LEFT JOIN (
      SELECT barang_id,
        SUM(CASE WHEN jenis = 'Masuk' THEN jumlah ELSE -jumlah END) AS total_stok
      FROM transaksi
      GROUP BY barang_id
    ) st ON b.id = st.barang_id
  ''';

  Future<List<Barang>> getAll() async {
    final db = await DatabaseHelper.database;
    final maps = await db.rawQuery('''
      $_selectWithStok
      ORDER BY b.nama_barang ASC
    ''');
    return maps.map((m) => Barang.fromMap(m)).toList();
  }

  Future<List<Barang>> getByKategori(int kategoriId) async {
    final db = await DatabaseHelper.database;
    final maps = await db.rawQuery('''
      $_selectWithStok
      WHERE b.kategori_id = ?
      ORDER BY b.nama_barang ASC
    ''', [kategoriId]);
    return maps.map((m) => Barang.fromMap(m)).toList();
  }

  Future<List<Barang>> search(String query) async {
    final db = await DatabaseHelper.database;
    final maps = await db.rawQuery('''
      $_selectWithStok
      WHERE b.nama_barang LIKE ? OR b.no_barang LIKE ?
      ORDER BY b.nama_barang ASC
    ''', ['%$query%', '%$query%']);
    return maps.map((m) => Barang.fromMap(m)).toList();
  }

  Future<int> insert(Barang barang) async {
    final db = await DatabaseHelper.database;
    return await db.insert('master_barang', barang.toMap());
  }

  Future<void> insertBatch(List<Barang> barangList) async {
    final db = await DatabaseHelper.database;
    final batch = db.batch();
    for (final b in barangList) {
      batch.insert('master_barang', b.toMap());
    }
    await batch.commit(noResult: true);
  }

  Future<int> update(Barang barang) async {
    final db = await DatabaseHelper.database;
    return await db.update(
      'master_barang',
      barang.toMap(),
      where: 'id = ?',
      whereArgs: [barang.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await DatabaseHelper.database;
    return await db.delete('master_barang', where: 'id = ?', whereArgs: [id]);
  }
}
