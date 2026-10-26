import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:admin_gudang/models/barang.dart';
import 'package:admin_gudang/models/transaksi.dart';
import 'package:admin_gudang/providers/barang_provider.dart';
import 'package:admin_gudang/providers/transaksi_provider.dart';
import 'package:admin_gudang/utils/format_helper.dart';

class TransaksiScreen extends ConsumerStatefulWidget {
  const TransaksiScreen({super.key});

  @override
  ConsumerState<TransaksiScreen> createState() => _TransaksiScreenState();
}

class _TransaksiScreenState extends ConsumerState<TransaksiScreen> {
  final _jumlahCtrl = TextEditingController();
  final _keteranganCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String _jenis = 'Masuk';
  Barang? _selectedBarang;
  List<Barang> _barangSuggestions = [];
  bool _showSuggestions = false;

  final _jumlahFocus = FocusNode();
  final _keteranganFocus = FocusNode();
  final _searchFocus = FocusNode();

  @override
  void dispose() {
    _jumlahCtrl.dispose();
    _keteranganCtrl.dispose();
    _searchCtrl.dispose();
    _jumlahFocus.dispose();
    _keteranganFocus.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(draftTransaksiProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Input Transaksi')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Form input
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Form Transaksi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        // Tanggal
                        Expanded(
                          flex: 2,
                          child: InkWell(
                            onTap: _pickDate,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Tanggal',
                                suffixIcon: Icon(Icons.calendar_today),
                              ),
                              child: Text(FormatHelper.formatTanggal(
                                FormatHelper.formatTanggalDb(_selectedDate),
                              )),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Jenis
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            initialValue: _jenis,
                            decoration: const InputDecoration(labelText: 'Jenis'),
                            items: const [
                              DropdownMenuItem(value: 'Masuk', child: Text('Barang Masuk')),
                              DropdownMenuItem(value: 'Keluar', child: Text('Barang Keluar')),
                            ],
                            onChanged: (v) => setState(() => _jenis = v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        // Autocomplete barang
                        Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextField(
                                controller: _searchCtrl,
                                focusNode: _searchFocus,
                                decoration: const InputDecoration(
                                  labelText: 'Cari Barang (Nama / No)',
                                  prefixIcon: Icon(Icons.search),
                                ),
                                onChanged: _onSearchBarang,
                                textInputAction: TextInputAction.next,
                                onSubmitted: (_) {
                                  if (_barangSuggestions.isNotEmpty && _selectedBarang == null) {
                                    _selectBarang(_barangSuggestions.first);
                                  }
                                  _jumlahFocus.requestFocus();
                                },
                              ),
                              if (_showSuggestions && _barangSuggestions.isNotEmpty)
                                Container(
                                  constraints: const BoxConstraints(maxHeight: 150),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: _barangSuggestions.length,
                                    itemBuilder: (ctx, i) {
                                      final b = _barangSuggestions[i];
                                      return ListTile(
                                        dense: true,
                                        title: Text(b.displayName),
                                        subtitle: Text('${b.namaKategori ?? ''} | ${b.satuan}'),
                                        onTap: () => _selectBarang(b),
                                      );
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Jumlah
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _jumlahCtrl,
                            focusNode: _jumlahFocus,
                            decoration: InputDecoration(
                              labelText: 'Jumlah',
                              suffixText: _selectedBarang?.satuan ?? '',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                            ],
                            textInputAction: TextInputAction.next,
                            onSubmitted: (_) => _keteranganFocus.requestFocus(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Keterangan
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _keteranganCtrl,
                            focusNode: _keteranganFocus,
                            decoration: const InputDecoration(
                              labelText: 'Keterangan (Retur/Rusak/dll)',
                            ),
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _tambahDraft(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Tombol tambah ke draft
                        ElevatedButton.icon(
                          onPressed: _tambahDraft,
                          icon: const Icon(Icons.add_shopping_cart),
                          label: const Text('Tambah'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Draft table
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Keranjang (${draft.length} item)',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                if (draft.isNotEmpty)
                  FilledButton.icon(
                    onPressed: _simpanSemua,
                    icon: const Icon(Icons.save),
                    label: const Text('Simpan Semua'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: draft.isEmpty
                  ? const Center(child: Text('Keranjang kosong. Tambahkan transaksi di atas.'))
                  : SingleChildScrollView(
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('No')),
                          DataColumn(label: Text('Tanggal')),
                          DataColumn(label: Text('Kode Barang')),
                          DataColumn(label: Text('Nama Barang')),
                          DataColumn(label: Text('Jenis')),
                          DataColumn(label: Text('Jumlah')),
                          DataColumn(label: Text('Keterangan')),
                          DataColumn(label: Text('Hapus')),
                        ],
                        rows: List.generate(draft.length, (i) {
                          final t = draft[i];
                          return DataRow(cells: [
                            DataCell(Text('${i + 1}')),
                            DataCell(Text(FormatHelper.formatTanggal(t.tanggal))),
                            DataCell(Text(t.kodeBarang ?? '-')),
                            DataCell(Text(t.namaBarang ?? '-')),
                            DataCell(Text(t.jenis)),
                            DataCell(Text(FormatHelper.formatAngka(t.jumlah))),
                            DataCell(Text(t.keterangan ?? '')),
                            DataCell(IconButton(
                              icon: const Icon(Icons.remove_circle, color: Colors.red, size: 18),
                              onPressed: () => ref.read(draftTransaksiProvider.notifier).hapus(i),
                            )),
                          ]);
                        }),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _onSearchBarang(String query) async {
    if (query.isEmpty) {
      setState(() {
        _barangSuggestions = [];
        _showSuggestions = false;
        _selectedBarang = null;
      });
      return;
    }

    final results = await ref.read(barangListProvider.notifier).cari(query);
    setState(() {
      _barangSuggestions = results;
      _showSuggestions = true;
      _selectedBarang = null;
    });
  }

  void _selectBarang(Barang b) {
    setState(() {
      _selectedBarang = b;
      _searchCtrl.text = b.displayName;
      _showSuggestions = false;
    });
    _jumlahFocus.requestFocus();
  }

  void _tambahDraft() {
    if (_selectedBarang == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih barang terlebih dahulu!')),
      );
      return;
    }

    final jumlah = double.tryParse(_jumlahCtrl.text);
    if (jumlah == null || jumlah <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jumlah harus berupa angka valid lebih dari 0!')),
      );
      return;
    }

    if (_jenis == 'Keluar') {
      final stokTersedia = _selectedBarang!.stokSaatIni ?? 0.0;
      // Hitung juga jumlah barang yang sama yang sudah ada di dalam keranjang draft
      final draft = ref.read(draftTransaksiProvider);
      double stokDiKeranjang = 0.0;
      for (final t in draft) {
        if (t.barangId == _selectedBarang!.id) {
          if (t.jenis == 'Keluar') {
            stokDiKeranjang += t.jumlah;
          } else if (t.jenis == 'Masuk') {
            stokDiKeranjang -= t.jumlah;
          }
        }
      }

      final sisaReal = stokTersedia - stokDiKeranjang;
      if (jumlah > sisaReal) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Stok tidak cukup! Sisa stok: ${FormatHelper.formatAngka(sisaReal)} ${_selectedBarang!.satuan} '
              '(Stok gudang: ${FormatHelper.formatAngka(stokTersedia)})',
            ),
          ),
        );
        return;
      }
    }

    final transaksi = Transaksi(
      barangId: _selectedBarang!.id!,
      tanggal: FormatHelper.formatTanggalDb(_selectedDate),
      jenis: _jenis,
      jumlah: jumlah,
      keterangan: _keteranganCtrl.text.trim().isEmpty ? null : _keteranganCtrl.text.trim(),
      namaBarang: _selectedBarang!.namaBarang,
      kodeBarang: _selectedBarang!.kodeBarang,
      satuan: _selectedBarang!.satuan,
    );

    ref.read(draftTransaksiProvider.notifier).tambah(transaksi);

    // Reset form input (keep tanggal & jenis)
    _searchCtrl.clear();
    _jumlahCtrl.clear();
    _keteranganCtrl.clear();
    setState(() {
      _selectedBarang = null;
      _barangSuggestions = [];
    });
    _searchFocus.requestFocus();
  }

  void _simpanSemua() async {
    final draft = ref.read(draftTransaksiProvider);
    if (draft.isEmpty) return;

    try {
      final simpan = ref.read(simpanSemuaDraftProvider);
      await simpan();
      ref.invalidate(transaksiListProvider);
      ref.invalidate(barangListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${draft.length} transaksi berhasil disimpan!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $e')),
        );
      }
    }
  }
}
