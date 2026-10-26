import 'package:admin_gudang/database/database_helper.dart';
import 'package:admin_gudang/models/laporan_item.dart';

class LaporanRepository {
  /// Hitung rekapan stok berdasarkan rentang tanggal dan kategori (opsional)
  Future<List<LaporanItem>> getLaporan({
    required String tanggalMulai,
    required String tanggalAkhir,
    int? kategoriId,
  }) async {
    final db = await DatabaseHelper.database;

    String whereKategori = '';
    List<dynamic> args = [tanggalMulai, tanggalMulai, tanggalAkhir, tanggalMulai, tanggalAkhir];

    if (kategoriId != null) {
      whereKategori = 'WHERE b.kategori_id = ?';
      args.add(kategoriId);
    }

    final maps = await db.rawQuery('''
      SELECT 
        b.id as barang_id,
        b.nama_barang,
        b.no_barang,
        b.satuan,
        k.nama_kategori,
        COALESCE(sa.stok_awal, 0) as stok_awal,
        COALESCE(tm.total_masuk, 0) as total_masuk,
        COALESCE(tk.total_keluar, 0) as total_keluar
      FROM master_barang b
      LEFT JOIN master_kategori k ON b.kategori_id = k.id
      LEFT JOIN (
        SELECT barang_id,
          SUM(CASE WHEN jenis = 'Masuk' THEN jumlah ELSE -jumlah END) as stok_awal
        FROM transaksi
        WHERE tanggal < ?
        GROUP BY barang_id
      ) sa ON b.id = sa.barang_id
      LEFT JOIN (
        SELECT barang_id, SUM(jumlah) as total_masuk
        FROM transaksi
        WHERE jenis = 'Masuk' AND tanggal >= ? AND tanggal <= ?
        GROUP BY barang_id
      ) tm ON b.id = tm.barang_id
      LEFT JOIN (
        SELECT barang_id, SUM(jumlah) as total_keluar
        FROM transaksi
        WHERE jenis = 'Keluar' AND tanggal >= ? AND tanggal <= ?
        GROUP BY barang_id
      ) tk ON b.id = tk.barang_id
      $whereKategori
      ORDER BY k.nama_kategori, b.nama_barang
    ''', args);

    return maps.map((m) => LaporanItem(
      barangId: m['barang_id'] as int,
      namaBarang: m['nama_barang'] as String,
      kodeBarang: m['no_barang'] as String,
      satuan: m['satuan'] as String,
      namaKategori: m['nama_kategori'] as String? ?? '-',
      stokAwal: (m['stok_awal'] as num).toDouble(),
      totalMasuk: (m['total_masuk'] as num).toDouble(),
      totalKeluar: (m['total_keluar'] as num).toDouble(),
    )).toList();
  }
}
