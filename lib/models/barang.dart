class Barang {
  final int? id;
  final String namaBarang;
  final String kodeBarang;
  final int kategoriId;
  final String satuan;
  // Joined field (optional, dari query JOIN)
  final String? namaKategori;
  final double? stokSaatIni;

  Barang({
    this.id,
    required this.namaBarang,
    required this.kodeBarang,
    required this.kategoriId,
    required this.satuan,
    this.namaKategori,
    this.stokSaatIni,
  });

  factory Barang.fromMap(Map<String, dynamic> map) {
    return Barang(
      id: map['id'] as int?,
      namaBarang: map['nama_barang'] as String,
      kodeBarang: map['no_barang'] as String,
      kategoriId: map['kategori_id'] as int,
      satuan: map['satuan'] as String,
      namaKategori: map['nama_kategori'] as String?,
      stokSaatIni: map['stok_saat_ini'] != null
          ? (map['stok_saat_ini'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nama_barang': namaBarang,
      'no_barang': kodeBarang,
      'kategori_id': kategoriId,
      'satuan': satuan,
    };
  }

  Barang copyWith({
    int? id,
    String? namaBarang,
    String? kodeBarang,
    int? kategoriId,
    String? satuan,
    String? namaKategori,
    double? stokSaatIni,
  }) {
    return Barang(
      id: id ?? this.id,
      namaBarang: namaBarang ?? this.namaBarang,
      kodeBarang: kodeBarang ?? this.kodeBarang,
      kategoriId: kategoriId ?? this.kategoriId,
      satuan: satuan ?? this.satuan,
      namaKategori: namaKategori ?? this.namaKategori,
      stokSaatIni: stokSaatIni ?? this.stokSaatIni,
    );
  }

  String get displayName => '$kodeBarang - $namaBarang';
}
