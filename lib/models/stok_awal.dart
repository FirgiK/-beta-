class StokAwal {
  final int? id;
  final int barangId;
  final String periodeBulan; // YYYY-MM
  final double jumlah;
  // Joined
  final String? namaBarang;

  StokAwal({
    this.id,
    required this.barangId,
    required this.periodeBulan,
    required this.jumlah,
    this.namaBarang,
  });

  factory StokAwal.fromMap(Map<String, dynamic> map) {
    return StokAwal(
      id: map['id'] as int?,
      barangId: map['barang_id'] as int,
      periodeBulan: map['periode_bulan'] as String,
      jumlah: (map['jumlah'] as num).toDouble(),
      namaBarang: map['nama_barang'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'barang_id': barangId,
      'periode_bulan': periodeBulan,
      'jumlah': jumlah,
    };
  }
}
