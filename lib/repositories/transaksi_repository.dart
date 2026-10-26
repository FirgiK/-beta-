import 'package:admin_gudang/database/database_helper.dart';
import 'package:admin_gudang/models/transaksi.dart';

class TransaksiRepository {
  Future<List<Transaksi>> getAll() async {
    final db = await DatabaseHelper.database;
    final maps = await db.rawQuery('''
      SELECT t.*, b.nama_barang, b.no_barang, b.satuan
      FROM transaksi t
      LEFT JOIN master_barang b ON t.barang_id = b.id
      ORDER BY t.tanggal DESC, t.id DESC
    ''');
    return maps.map((m) => Transaksi.fromMap(m)).toList();
  }

  Future<List<Transaksi>> getByDateRange(String startDate, String endDate) async {
    final db = await DatabaseHelper.database;
    final maps = await db.rawQuery('''
      SELECT t.*, b.nama_barang, b.no_barang, b.satuan
      FROM transaksi t
      LEFT JOIN master_barang b ON t.barang_id = b.id
      WHERE t.tanggal >= ? AND t.tanggal <= ?
      ORDER BY t.tanggal DESC, t.id DESC
    ''', [startDate, endDate]);
    return maps.map((m) => Transaksi.fromMap(m)).toList();
  }

  Future<int> insert(Transaksi transaksi) async {
    final db = await DatabaseHelper.database;
    return await db.insert('transaksi', transaksi.toMap());
  }

  Future<void> insertBatch(List<Transaksi> transaksiList) async {
    final db = await DatabaseHelper.database;
    final batch = db.batch();
    for (final t in transaksiList) {
      batch.insert('transaksi', t.toMap());
    }
    await batch.commit(noResult: true);
  }

  Future<int> delete(int id) async {
    final db = await DatabaseHelper.database;
    return await db.delete('transaksi', where: 'id = ?', whereArgs: [id]);
  }
}
