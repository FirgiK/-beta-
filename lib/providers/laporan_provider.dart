import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:admin_gudang/models/laporan_item.dart';
import 'package:admin_gudang/repositories/laporan_repository.dart';

final laporanRepositoryProvider = Provider((ref) => LaporanRepository());

/// Parameter filter laporan
class LaporanFilter {
  final String tanggalMulai;
  final String tanggalAkhir;
  final int? kategoriId;

  LaporanFilter({
    required this.tanggalMulai,
    required this.tanggalAkhir,
    this.kategoriId,
  });
}

/// Riverpod v3: gunakan Notifier, bukan StateProvider
final laporanFilterProvider = NotifierProvider<LaporanFilterNotifier, LaporanFilter?>(
  LaporanFilterNotifier.new,
);

class LaporanFilterNotifier extends Notifier<LaporanFilter?> {
  @override
  LaporanFilter? build() => null;

  void setFilter(LaporanFilter filter) {
    state = filter;
  }
}

final laporanDataProvider = FutureProvider<List<LaporanItem>>((ref) async {
  final filter = ref.watch(laporanFilterProvider);
  if (filter == null) return [];
  final repo = ref.read(laporanRepositoryProvider);
  return await repo.getLaporan(
    tanggalMulai: filter.tanggalMulai,
    tanggalAkhir: filter.tanggalAkhir,
    kategoriId: filter.kategoriId,
  );
});
