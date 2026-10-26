import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:admin_gudang/models/barang.dart';
import 'package:admin_gudang/providers/barang_provider.dart';
import 'package:admin_gudang/providers/kategori_provider.dart';
import 'package:admin_gudang/utils/format_helper.dart';
import 'package:admin_gudang/utils/unit_options.dart';

class MasterBarangScreen extends ConsumerStatefulWidget {
  const MasterBarangScreen({super.key});

  @override
  ConsumerState<MasterBarangScreen> createState() => _MasterBarangScreenState();
}

class _MasterBarangScreenState extends ConsumerState<MasterBarangScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final barangAsync = ref.watch(barangListProvider);
    // Keep kategori provider alive for form dialogs
    ref.watch(kategoriListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Master Barang'),
        actions: [
          SizedBox(
            width: 300,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Cari barang...',
                  prefixIcon: Icon(Icons.search),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                ),
                onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Tambah Barang',
            onPressed: () => _showFormDialog(context, null),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: barangAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) {
          final filtered = _searchQuery.isEmpty
              ? list
              : list.where((b) =>
                  b.namaBarang.toLowerCase().contains(_searchQuery) ||
                  b.kodeBarang.toLowerCase().contains(_searchQuery)).toList();

          if (filtered.isEmpty) {
            return const Center(child: Text('Belum ada data barang.'));
          }

          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Kode Barang')),
                  DataColumn(label: Text('Nama Barang')),
                  DataColumn(label: Text('Kategori')),
                  DataColumn(label: Text('Satuan')),
                  DataColumn(label: Text('Stok Saat Ini'), numeric: true),
                  DataColumn(label: Text('Aksi')),
                ],
                rows: List.generate(filtered.length, (i) {
                  final b = filtered[i];
                  final stok = b.stokSaatIni ?? 0.0;
                  return DataRow(cells: [
                    DataCell(Text(b.kodeBarang)),
                    DataCell(Text(b.namaBarang)),
                    DataCell(Text(b.namaKategori ?? '-')),
                    DataCell(Text(b.satuan)),
                    DataCell(Text(
                      FormatHelper.formatAngka(stok),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: stok < 0 ? Colors.red : (stok == 0 ? Colors.orange : Colors.green.shade700),
                      ),
                    )),
                    DataCell(Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18),
                          tooltip: 'Edit',
                          onPressed: () => _showFormDialog(context, b),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                          tooltip: 'Hapus',
                          onPressed: () => _confirmDelete(b),
                        ),
                      ],
                    )),
                  ]);
                }),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showFormDialog(BuildContext context, Barang? existing) {
    final isEdit = existing != null;
    final namaCtrl = TextEditingController(text: existing?.namaBarang ?? '');
    final noCtrl = TextEditingController(text: existing?.kodeBarang ?? '');
    final satuanCtrl = TextEditingController(text: existing?.satuan ?? '');
    int? selectedKategoriId = existing?.kategoriId;
    String selectedSatuan = UnitOptions.values.contains(existing?.satuan)
        ? existing!.satuan
        : UnitOptions.custom;

    final kategoriAsync = ref.read(kategoriListProvider);
    final kategoriList = kategoriAsync.value ?? [];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Text(isEdit ? 'Edit Barang' : 'Tambah Barang'),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: noCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Kode Barang',
                      hintText: 'Contoh: BRG-001 (tanpa spasi)',
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.deny(RegExp(r'\s')),
                    ],
                    autofocus: true,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: namaCtrl,
                    decoration: const InputDecoration(labelText: 'Nama Barang'),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: selectedKategoriId,
                    decoration: const InputDecoration(labelText: 'Kategori'),
                    items: kategoriList
                        .map((k) => DropdownMenuItem(value: k.id, child: Text(k.namaKategori)))
                        .toList(),
                    onChanged: (v) => setDialogState(() => selectedKategoriId = v),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedSatuan,
                    decoration: const InputDecoration(labelText: 'Satuan'),
                    items: UnitOptions.values
                        .map((unit) => DropdownMenuItem(value: unit, child: Text(unit)))
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() {
                        selectedSatuan = value;
                        if (value != UnitOptions.custom) satuanCtrl.text = value;
                        if (value == UnitOptions.custom && UnitOptions.values.contains(satuanCtrl.text)) {
                          satuanCtrl.clear();
                        }
                      });
                    },
                  ),
                  if (selectedSatuan == UnitOptions.custom) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: satuanCtrl,
                      decoration: const InputDecoration(labelText: 'Satuan Custom'),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _saveBarang(
                        ctx, isEdit, existing, noCtrl, namaCtrl, satuanCtrl, selectedKategoriId,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
              FilledButton(
                onPressed: () => _saveBarang(
                  ctx, isEdit, existing, noCtrl, namaCtrl, satuanCtrl, selectedKategoriId,
                ),
                child: const Text('Simpan'),
              ),
            ],
          );
        });
      },
    );
  }

  void _saveBarang(
    BuildContext ctx,
    bool isEdit,
    Barang? existing,
    TextEditingController noCtrl,
    TextEditingController namaCtrl,
    TextEditingController satuanCtrl,
    int? kategoriId,
  ) async {
    if (namaCtrl.text.trim().isEmpty || noCtrl.text.trim().isEmpty || satuanCtrl.text.trim().isEmpty || kategoriId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua field wajib diisi!')),
      );
      return;
    }

    final barangRepo = ref.read(barangRepositoryProvider);
    final allBarang = await barangRepo.getAll();
    final kodeBarangInput = noCtrl.text.trim().toLowerCase();
    final isDuplicate = allBarang.any((b) =>
        b.kodeBarang.trim().toLowerCase() == kodeBarangInput &&
        (!isEdit || b.id != existing?.id));

    if (isDuplicate) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text('Kode barang "${noCtrl.text.trim()}" sudah digunakan! Gunakan kode lain.')),
        );
      }
      return;
    }

    final barang = Barang(
      id: existing?.id,
      namaBarang: namaCtrl.text.trim(),
      kodeBarang: noCtrl.text.trim(),
      kategoriId: kategoriId,
      satuan: satuanCtrl.text.trim(),
    );

    try {
      final notifier = ref.read(barangListProvider.notifier);
      if (isEdit) {
        await notifier.ubah(barang);
      } else {
        await notifier.tambah(barang);
      }
      if (ctx.mounted) Navigator.pop(ctx);
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $e')),
        );
      }
    }
  }

  void _confirmDelete(Barang barang) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Barang'),
        content: Text('Yakin hapus "${barang.namaBarang}"?\nData transaksi terkait akan terpengaruh.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await ref.read(barangListProvider.notifier).hapus(barang.id!);
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('Gagal hapus: $e\nBarang mungkin masih dipakai di transaksi.')),
                  );
                }
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
