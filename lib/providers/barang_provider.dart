import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:admin_gudang/models/barang.dart';
import 'package:admin_gudang/repositories/barang_repository.dart';

final barangRepositoryProvider = Provider((ref) => BarangRepository());

final barangListProvider = AsyncNotifierProvider<BarangListNotifier, List<Barang>>(
  BarangListNotifier.new,
);

class BarangListNotifier extends AsyncNotifier<List<Barang>> {
  @override
  Future<List<Barang>> build() async {
    final repo = ref.read(barangRepositoryProvider);
    return await repo.getAll();
  }

  Future<void> tambah(Barang barang) async {
    final repo = ref.read(barangRepositoryProvider);
    await repo.insert(barang);
    ref.invalidateSelf();
  }

  Future<void> ubah(Barang barang) async {
    final repo = ref.read(barangRepositoryProvider);
    await repo.update(barang);
    ref.invalidateSelf();
  }

  Future<void> hapus(int id) async {
    final repo = ref.read(barangRepositoryProvider);
    await repo.delete(id);
    ref.invalidateSelf();
  }

  Future<void> importBatch(List<Barang> list) async {
    final repo = ref.read(barangRepositoryProvider);
    await repo.insertBatch(list);
    ref.invalidateSelf();
  }

  Future<List<Barang>> cari(String query) async {
    final repo = ref.read(barangRepositoryProvider);
    return await repo.search(query);
  }
}
