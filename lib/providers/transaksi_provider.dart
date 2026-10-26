import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:admin_gudang/models/transaksi.dart';
import 'package:admin_gudang/repositories/transaksi_repository.dart';

final transaksiRepositoryProvider = Provider((ref) => TransaksiRepository());

/// Draft / keranjang transaksi (belum disimpan ke DB)
final draftTransaksiProvider = NotifierProvider<DraftTransaksiNotifier, List<Transaksi>>(
  DraftTransaksiNotifier.new,
);

class DraftTransaksiNotifier extends Notifier<List<Transaksi>> {
  @override
  List<Transaksi> build() => [];

  void tambah(Transaksi t) {
    state = [...state, t];
  }

  void hapus(int index) {
    final list = [...state];
    list.removeAt(index);
    state = list;
  }

  void bersihkan() {
    state = [];
  }
}

/// Simpan semua draft ke database
final simpanSemuaDraftProvider = Provider((ref) {
  return () async {
    final repo = ref.read(transaksiRepositoryProvider);
    final draft = ref.read(draftTransaksiProvider);
    if (draft.isEmpty) return;
    await repo.insertBatch(draft);
    ref.read(draftTransaksiProvider.notifier).bersihkan();
  };
});

/// List transaksi dari DB (untuk riwayat)
final transaksiListProvider = FutureProvider<List<Transaksi>>((ref) async {
  final repo = ref.read(transaksiRepositoryProvider);
  return await repo.getAll();
});
