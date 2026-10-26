import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:admin_gudang/providers/kategori_provider.dart';
import 'package:admin_gudang/providers/laporan_provider.dart';
import 'package:admin_gudang/utils/excel_helper.dart';
import 'package:admin_gudang/utils/format_helper.dart';

class LaporanScreen extends ConsumerStatefulWidget {
  const LaporanScreen({super.key});

  @override
  ConsumerState<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends ConsumerState<LaporanScreen> {
  DateTime _tanggalMulai = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _tanggalAkhir = DateTime.now();
  int? _selectedKategoriId;

  @override
  Widget build(BuildContext context) {
    final kategoriAsync = ref.watch(kategoriListProvider);
    final laporanAsync = ref.watch(laporanDataProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Laporan Stok')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Tanggal Mulai
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickDate(true),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Tanggal Mulai',
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(FormatHelper.formatTanggal(
                            FormatHelper.formatTanggalDb(_tanggalMulai),
                          )),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Tanggal Akhir
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickDate(false),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Tanggal Akhir',
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(FormatHelper.formatTanggal(
                            FormatHelper.formatTanggalDb(_tanggalAkhir),
                          )),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Kategori filter
                    Expanded(
                      child: kategoriAsync.when(
                        loading: () => const LinearProgressIndicator(),
                        error: (e, _) => Text('Error: $e'),
                        data: (list) => DropdownButtonFormField<int?>(
                          initialValue: _selectedKategoriId,
                          decoration: const InputDecoration(labelText: 'Kategori'),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('Semua Kategori')),
                            ...list.map((k) => DropdownMenuItem(
                                  value: k.id,
                                  child: Text(k.namaKategori),
                                )),
                          ],
                          onChanged: (v) => setState(() => _selectedKategoriId = v),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Tombol filter
                    FilledButton.icon(
                      onPressed: _applyFilter,
                      icon: const Icon(Icons.search),
                      label: const Text('Tampilkan'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Hasil laporan
            Expanded(
              child: laporanAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (data) {
                  if (data.isEmpty) {
                    return const Center(child: Text('Belum ada data. Atur filter dan tekan "Tampilkan".'));
                  }

                  return Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${data.length} barang',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          ElevatedButton.icon(
                            onPressed: () => _exportExcel(context),
                            icon: const Icon(Icons.download),
                            label: const Text('Export ke Excel'),
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
                                DataColumn(label: Text('Stok Awal'), numeric: true),
                                DataColumn(label: Text('Total Masuk'), numeric: true),
                                DataColumn(label: Text('Total Keluar'), numeric: true),
                                DataColumn(label: Text('Stok Akhir'), numeric: true),
                              ],
                              rows: List.generate(data.length, (i) {
                                final item = data[i];
                                return DataRow(cells: [
                                  DataCell(Text('${i + 1}')),
                                  DataCell(Text(item.kodeBarang)),
                                  DataCell(Text(item.namaBarang)),
                                  DataCell(Text(item.namaKategori)),
                                  DataCell(Text(item.satuan)),
                                  DataCell(Text(FormatHelper.formatAngka(item.stokAwal))),
                                  DataCell(Text(FormatHelper.formatAngka(item.totalMasuk))),
                                  DataCell(Text(FormatHelper.formatAngka(item.totalKeluar))),
                                  DataCell(Text(
                                    FormatHelper.formatAngka(item.stok),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: item.stok < 0 ? Colors.red : (item.stok == 0 ? Colors.orange : Colors.green.shade700),
                                    ),
                                  )),
                                ]);
                              }),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _pickDate(bool isMulai) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isMulai ? _tanggalMulai : _tanggalAkhir,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isMulai) {
          _tanggalMulai = picked;
        } else {
          _tanggalAkhir = picked;
        }
      });
    }
  }

  void _applyFilter() {
    if (_tanggalMulai.isAfter(_tanggalAkhir)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tanggal Mulai tidak boleh lebih besar dari Tanggal Akhir!')),
      );
      return;
    }

    ref.read(laporanFilterProvider.notifier).setFilter(LaporanFilter(
      tanggalMulai: FormatHelper.formatTanggalDb(_tanggalMulai),
      tanggalAkhir: FormatHelper.formatTanggalDb(_tanggalAkhir),
      kategoriId: _selectedKategoriId,
    ));
  }

  void _exportExcel(BuildContext context) async {
    final data = ref.read(laporanDataProvider).value;
    if (data == null || data.isEmpty) return;

    try {
      // Generate Excel bytes terlebih dahulu
      final bytes = ExcelHelper.exportLaporanBytes(
        data: data,
        tanggalMulai: FormatHelper.formatTanggal(FormatHelper.formatTanggalDb(_tanggalMulai)),
        tanggalAkhir: FormatHelper.formatTanggal(FormatHelper.formatTanggalDb(_tanggalAkhir)),
      );

      // Pilih lokasi simpan
      final savedUri = await FilePicker.saveFile(
        dialogTitle: 'Simpan Laporan Excel',
        fileName: 'Laporan_Stok_${FormatHelper.formatTanggalDb(_tanggalMulai)}_sd_${FormatHelper.formatTanggalDb(_tanggalAkhir)}.xlsx',
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        bytes: bytes,
      );

      if (savedUri == null) return;

      if (!mounted) return;
      ScaffoldMessenger.of(this.context).showSnackBar(
        SnackBar(content: Text('Laporan berhasil disimpan: ${savedUri.toFilePath()}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(this.context).showSnackBar(
        SnackBar(content: Text('Gagal export: $e')),
      );
    }
  }
}
