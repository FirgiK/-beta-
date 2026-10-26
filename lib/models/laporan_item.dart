/// Model untuk baris laporan rekapan stok
class LaporanItem {
  final int barangId;
  final String namaBarang;
  final String kodeBarang;
  final String satuan;
  final String namaKategori;
  final double stokAwal;
  final double totalMasuk;
  final double totalKeluar;

  LaporanItem({
    required this.barangId,
    required this.namaBarang,
    required this.kodeBarang,
    required this.satuan,
    required this.namaKategori,
    required this.stokAwal,
    required this.totalMasuk,
    required this.totalKeluar,
  });

  /// Stok Akhir Kumulatif: Stok Awal Periode + Total Masuk Periode - Total Keluar Periode
  double get stok => stokAwal + totalMasuk - totalKeluar;
}
