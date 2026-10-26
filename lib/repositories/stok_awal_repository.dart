import 'package:admin_gudang/database/database_helper.dart';
import 'package:admin_gudang/models/stok_awal.dart';

class StokAwalRepository {
  Future<List<StokAwal>> getAll() async {
    final db = await DatabaseHelper.database;
    final maps = await db.rawQuery('''
      SELECT s.*, b.nama_barang
      FROM stok_awal s
      LEFT JOIN master_barang b ON s.barang_id = b.id
      ORDER BY s.periode_bulan DESC
    ''');
    return maps.map((m) => StokAwal.fromMap(m)).toList();
  }

  Future<StokAwal?> getByBarangAndPeriode(int barangId, String periodeBulan) async {
    final db = await DatabaseHelper.database;
    final maps = await db.query(
      'stok_awal',
      where: 'barang_id = ? AND periode_bulan = ?',
      whereArgs: [barangId, periodeBulan],
    );
    if (maps.isEmpty) return null;
    return StokAwal.fromMap(maps.first);
  }

  Future<int> upsert(StokAwal stokAwal) async {
    final db = await DatabaseHelper.database;
    // Cek apakah sudah ada
    final existing = await getByBarangAndPeriode(
      stokAwal.barangId,
      stokAwal.periodeBulan,
    );
    if (existing != null) {
      return await db.update(
        'stok_awal',
        stokAwal.toMap(),
        where: 'id = ?',
        whereArgs: [existing.id],
      );
    }
    return await db.insert('stok_awal', stokAwal.toMap());
  }

  Future<void> upsertBatch(List<StokAwal> stokList) async {
    final db = await DatabaseHelper.database;
    for (final s in stokList) {
      final existing = await getByBarangAndPeriode(s.barangId, s.periodeBulan);
      if (existing != null) {
        await db.update('stok_awal', s.toMap(), where: 'id = ?', whereArgs: [existing.id]);
      } else {
        await db.insert('stok_awal', s.toMap());
      }
    }
  }

  Future<int> delete(int id) async {
    final db = await DatabaseHelper.database;
    return await db.delete('stok_awal', where: 'id = ?', whereArgs: [id]);
  }
}
