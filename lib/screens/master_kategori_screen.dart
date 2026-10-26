import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:admin_gudang/providers/kategori_provider.dart';
import 'package:admin_gudang/models/kategori.dart';

class MasterKategoriScreen extends ConsumerWidget {
  const MasterKategoriScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kategoriAsync = ref.watch(kategoriListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Master Kategori'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Tambah Kategori',
            onPressed: () => _showFormDialog(context, ref, null),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: kategoriAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('Belum ada kategori.'));
          }
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (ctx, i) {
              final k = list[i];
              return ListTile(
                leading: CircleAvatar(child: Text('${i + 1}')),
                title: Text(k.namaKategori),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showFormDialog(context, ref, k),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmDelete(context, ref, k),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showFormDialog(BuildContext context, WidgetRef ref, Kategori? existing) {
    final isEdit = existing != null;
    final ctrl = TextEditingController(text: existing?.namaKategori ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Edit Kategori' : 'Tambah Kategori'),
        content: SizedBox(
          width: 300,
          child: TextField(
            controller: ctrl,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Nama Kategori'),
            onSubmitted: (_) => _saveKategori(ctx, ref, isEdit, existing, ctrl, context),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            onPressed: () => _saveKategori(ctx, ref, isEdit, existing, ctrl, context),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _saveKategori(
    BuildContext dialogCtx,
    WidgetRef ref,
    bool isEdit,
    Kategori? existing,
    TextEditingController ctrl,
    BuildContext scaffoldCtx,
  ) async {
    final nama = ctrl.text.trim();
    if (nama.isEmpty) {
      ScaffoldMessenger.of(scaffoldCtx).showSnackBar(
        const SnackBar(content: Text('Nama kategori tidak boleh kosong!')),
      );
      return;
    }

    final currentList = ref.read(kategoriListProvider).value ?? [];
    final isDuplicate = currentList.any((k) =>
        k.namaKategori.trim().toLowerCase() == nama.toLowerCase() &&
        (!isEdit || k.id != existing?.id));

    if (isDuplicate) {
      ScaffoldMessenger.of(scaffoldCtx).showSnackBar(
        SnackBar(content: Text('Kategori "$nama" sudah ada! Gunakan nama lain.')),
      );
      return;
    }

    try {
      final notifier = ref.read(kategoriListProvider.notifier);
      if (isEdit) {
        await notifier.ubah(existing!.copyWith(namaKategori: nama));
      } else {
        await notifier.tambah(nama);
      }
      if (dialogCtx.mounted) Navigator.pop(dialogCtx);
    } catch (e) {
      if (!scaffoldCtx.mounted) return;
      ScaffoldMessenger.of(scaffoldCtx).showSnackBar(
        SnackBar(content: Text('Gagal: $e')),
      );
    }
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Kategori kategori) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Kategori'),
        content: Text('Yakin hapus "${kategori.namaKategori}"?\nKategori yang masih dipakai barang tidak bisa dihapus.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await ref.read(kategoriListProvider.notifier).hapus(kategori.id!);
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('Gagal hapus: $e')),
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
