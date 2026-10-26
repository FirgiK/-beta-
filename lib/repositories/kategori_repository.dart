import 'package:admin_gudang/database/database_helper.dart';
import 'package:admin_gudang/models/kategori.dart';

class KategoriRepository {
  Future<List<Kategori>> getAll() async {
    final db = await DatabaseHelper.database;
    final maps = await db.query('master_kategori', orderBy: 'nama_kategori ASC');
    return maps.map((m) => Kategori.fromMap(m)).toList();
  }

  Future<Kategori?> getById(int id) async {
    final db = await DatabaseHelper.database;
    final maps = await db.query('master_kategori', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Kategori.fromMap(maps.first);
  }

  Future<int> insert(Kategori kategori) async {
    final db = await DatabaseHelper.database;
    return await db.insert('master_kategori', kategori.toMap());
  }

  Future<int> update(Kategori kategori) async {
    final db = await DatabaseHelper.database;
    return await db.update(
      'master_kategori',
      kategori.toMap(),
      where: 'id = ?',
      whereArgs: [kategori.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await DatabaseHelper.database;
    return await db.delete('master_kategori', where: 'id = ?', whereArgs: [id]);
  }
}
