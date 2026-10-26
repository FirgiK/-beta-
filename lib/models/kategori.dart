class Kategori {
  final int? id;
  final String namaKategori;

  Kategori({this.id, required this.namaKategori});

  factory Kategori.fromMap(Map<String, dynamic> map) {
    return Kategori(
      id: map['id'] as int?,
      namaKategori: map['nama_kategori'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nama_kategori': namaKategori,
    };
  }

  Kategori copyWith({int? id, String? namaKategori}) {
    return Kategori(
      id: id ?? this.id,
      namaKategori: namaKategori ?? this.namaKategori,
    );
  }

  @override
  String toString() => namaKategori;
}
