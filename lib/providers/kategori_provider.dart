import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:admin_gudang/models/kategori.dart';
import 'package:admin_gudang/repositories/kategori_repository.dart';

final kategoriRepositoryProvider = Provider((ref) => KategoriRepository());

final kategoriListProvider = AsyncNotifierProvider<KategoriListNotifier, List<Kategori>>(
  KategoriListNotifier.new,
);

class KategoriListNotifier extends AsyncNotifier<List<Kategori>> {
  @override
  Future<List<Kategori>> build() async {
    final repo = ref.read(kategoriRepositoryProvider);
    return await repo.getAll();
  }

  Future<void> tambah(String nama) async {
    final repo = ref.read(kategoriRepositoryProvider);
    await repo.insert(Kategori(namaKategori: nama));
    ref.invalidateSelf();
  }

  Future<void> ubah(Kategori kategori) async {
    final repo = ref.read(kategoriRepositoryProvider);
    await repo.update(kategori);
    ref.invalidateSelf();
  }

  Future<void> hapus(int id) async {
    final repo = ref.read(kategoriRepositoryProvider);
    await repo.delete(id);
    ref.invalidateSelf();
  }
}
