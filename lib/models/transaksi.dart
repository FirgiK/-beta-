class Transaksi {
  final int? id;
  final int barangId;
  final String tanggal; // YYYY-MM-DD
  final String jenis; // "Masuk" / "Keluar"
  final double jumlah;
  final String? keterangan;
  // Joined fields
  final String? namaBarang;
  final String? kodeBarang;
  final String? satuan;

  Transaksi({
    this.id,
    required this.barangId,
    required this.tanggal,
    required this.jenis,
    required this.jumlah,
    this.keterangan,
    this.namaBarang,
    this.kodeBarang,
    this.satuan,
  });

  factory Transaksi.fromMap(Map<String, dynamic> map) {
    return Transaksi(
      id: map['id'] as int?,
      barangId: map['barang_id'] as int,
      tanggal: map['tanggal'] as String,
      jenis: map['jenis'] as String,
      jumlah: (map['jumlah'] as num).toDouble(),
      keterangan: map['keterangan'] as String?,
      namaBarang: map['nama_barang'] as String?,
      kodeBarang: map['no_barang'] as String?,
      satuan: map['satuan'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'barang_id': barangId,
      'tanggal': tanggal,
      'jenis': jenis,
      'jumlah': jumlah,
      'keterangan': keterangan,
    };
  }
}
