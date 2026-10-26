import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:admin_gudang/models/barang.dart';
import 'package:admin_gudang/providers/barang_provider.dart';
import 'package:admin_gudang/providers/kategori_provider.dart';
import 'package:admin_gudang/utils/excel_helper.dart';

class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key});

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  List<Map<String, dynamic>> _previewData = [];
  String? _filePath;
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import Data Excel')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Import Data Barang',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text(
                      'Format Excel: Kode Barang | Nama Barang | Kategori | Satuan\n'
                      'Baris pertama = header (akan dilewati). Baris dengan nama barang kosong akan dilewati.',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isImporting ? null : _pilihFile,
                          icon: const Icon(Icons.file_open),
                          label: const Text('Pilih File Excel'),
                        ),
                        const SizedBox(width: 16),
                        if (_filePath != null) ...[
                          Expanded(
                            child: Text('File: ${_filePath!.split(Platform.pathSeparator).last}',
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],

                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_previewData.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Preview: ${_previewData.length} baris',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  FilledButton.icon(
                    onPressed: _isImporting ? null : _importData,
                    icon: _isImporting
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.upload),
                    label: Text(_isImporting ? 'Mengimport...' : 'Import Semua'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('No')),
                        DataColumn(label: Text('Kode Barang')),
                        DataColumn(label: Text('Nama Barang')),
                        DataColumn(label: Text('Kategori')),
                        DataColumn(label: Text('Satuan')),
                      ],
                      rows: List.generate(_previewData.length, (i) {
                        final row = _previewData[i];
                        return DataRow(cells: [
                          DataCell(Text('${i + 1}')),
                          DataCell(Text(row['no_barang'] ?? '')),
                          DataCell(Text(row['nama_barang'] ?? '')),
                          DataCell(Text(row['kategori'] ?? '')),
                          DataCell(Text(row['satuan'] ?? '')),
                        ]);
                      }),
                    ),
                  ),
                ),
              ),
            ] else
              const Expanded(child: Center(child: Text('Pilih file Excel untuk melihat preview data.'))),
          ],
        ),
      ),
    );
  }

  void _pilihFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );

    if (result.isEmpty) return;

    final path = result.single.path;
    if (path == null) return;

    try {
      final data = await ExcelHelper.importBarang(path);
      setState(() {
        _filePath = path;
        _previewData = data;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal baca file: $e')),
        );
      }
    }
  }

  void _importData() async {
    if (_previewData.isEmpty) return;

    setState(() => _isImporting = true);

    try {
      // Ambil daftar kategori untuk mapping nama -> id
      final kategoriList = ref.read(kategoriListProvider).value ?? [];
      final kategoriMap = <String, int>{};
      for (final k in kategoriList) {
        kategoriMap[k.namaKategori.toLowerCase()] = k.id!;
      }

      final barangRepo = ref.read(barangRepositoryProvider);
      final existingBarangList = await barangRepo.getAll();
      final existingKodeSet = existingBarangList.map((b) => b.kodeBarang.trim().toLowerCase()).toSet();

      final List<Barang> itemsToInsert = [];
      final Set<String> batchKodeSet = {};
      int skipCount = 0;

      for (final row in _previewData) {
        final namaBarang = (row['nama_barang'] as String).trim();
        final rawKode = (row['no_barang'] as String? ?? '').trim();
        if (namaBarang.isEmpty || rawKode.isEmpty) {
          skipCount++;
          continue;
        }

        final kodeLower = rawKode.toLowerCase();
        if (existingKodeSet.contains(kodeLower) || batchKodeSet.contains(kodeLower)) {
          skipCount++;
          continue;
        }

        final kategoriNama = (row['kategori'] as String).trim().toLowerCase();
        final kategoriId = kategoriMap[kategoriNama];
        if (kategoriId == null) {
          skipCount++;
          continue;
        }

        batchKodeSet.add(kodeLower);
        itemsToInsert.add(Barang(
          namaBarang: namaBarang,
          kodeBarang: rawKode,
          kategoriId: kategoriId,
          satuan: (row['satuan'] as String).trim(),
        ));
      }

      if (itemsToInsert.isNotEmpty) {
        await barangRepo.insertBatch(itemsToInsert);
      }
      final importCount = itemsToInsert.length;

      // Refresh data
      ref.invalidate(barangListProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import selesai: $importCount berhasil, $skipCount dilewati.')),
        );
        setState(() {
          _previewData = [];
          _filePath = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal import: $e')),
        );
      }
    } finally {
      setState(() => _isImporting = false);
    }
  }
}
