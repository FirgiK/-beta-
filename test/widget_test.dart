import 'package:flutter_test/flutter_test.dart';
import 'package:admin_gudang/models/barang.dart';
import 'package:admin_gudang/models/kategori.dart';
import 'package:admin_gudang/models/transaksi.dart';
import 'package:admin_gudang/models/stok_awal.dart';
import 'package:admin_gudang/models/laporan_item.dart';

void main() {
  group('Model serialization', () {
    test('Barang fromMap/toMap round-trip', () {
      final map = {
        'id': 1,
        'nama_barang': 'Kertas A4',
        'no_barang': 'BK-001',
        'kategori_id': 1,
        'satuan': 'Rim',
        'nama_kategori': 'Bahan Baku',
        'stok_saat_ini': 150.0,
      };
      final barang = Barang.fromMap(map);
      expect(barang.namaBarang, 'Kertas A4');
      expect(barang.kodeBarang, 'BK-001');
      expect(barang.kategoriId, 1);
      expect(barang.satuan, 'Rim');
      expect(barang.namaKategori, 'Bahan Baku');
      expect(barang.stokSaatIni, 150.0);
      expect(barang.displayName, 'BK-001 - Kertas A4');

      final toMap = barang.toMap();
      expect(toMap['nama_barang'], 'Kertas A4');
      expect(toMap['kategori_id'], 1);
      expect(toMap.containsKey('nama_kategori'), false);
      expect(toMap.containsKey('stok_saat_ini'), false);
    });

    test('Kategori fromMap/toMap round-trip', () {
      final map = {'id': 2, 'nama_kategori': 'Obat'};
      final k = Kategori.fromMap(map);
      expect(k.namaKategori, 'Obat');
      expect(k.toString(), 'Obat');

      final toMap = k.toMap();
      expect(toMap['nama_kategori'], 'Obat');
    });

    test('Transaksi fromMap/toMap round-trip', () {
      final map = {
        'id': 1,
        'barang_id': 5,
        'tanggal': '2026-10-07',
        'jenis': 'Masuk',
        'jumlah': 100.0,
        'keterangan': 'Retur',
        'nama_barang': 'Kertas A4',
        'no_barang': 'BK-001',
        'satuan': 'Rim',
      };
      final t = Transaksi.fromMap(map);
      expect(t.barangId, 5);
      expect(t.jenis, 'Masuk');
      expect(t.jumlah, 100.0);
      expect(t.keterangan, 'Retur');

      final toMap = t.toMap();
      expect(toMap.containsKey('nama_barang'), false);
    });

    test('StokAwal fromMap/toMap round-trip', () {
      final map = {
        'id': 1,
        'barang_id': 3,
        'periode_bulan': '2026-10',
        'jumlah': 50.0,
        'nama_barang': 'Test',
      };
      final s = StokAwal.fromMap(map);
      expect(s.barangId, 3);
      expect(s.periodeBulan, '2026-10');
      expect(s.jumlah, 50.0);
    });

    test('LaporanItem stokAkhir calculation', () {
      final item = LaporanItem(
        barangId: 1,
        namaBarang: 'Test',
        kodeBarang: 'T-001',
        satuan: 'Pcs',
        namaKategori: 'Bahan Baku',
        stokAwal: 15,
        totalMasuk: 50,
        totalKeluar: 30,
      );
      // stok = stokAwal + totalMasuk - totalKeluar = 15 + 50 - 30 = 35
      expect(item.stok, 35);
    });
  });
}
