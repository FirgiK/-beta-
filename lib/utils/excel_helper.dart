import 'dart:io';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:admin_gudang/models/laporan_item.dart';

class ExcelHelper {
  /// Import data barang dari file Excel
  /// Ekspektasi kolom: Kode Barang | Nama Barang | Kategori | Satuan
  static Future<List<Map<String, dynamic>>> importBarang(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    final results = <Map<String, dynamic>>[];

    for (final table in excel.tables.keys) {
      final sheet = excel.tables[table]!;
      if (sheet.maxRows < 2) continue; // Minimal header + 1 data

      for (int i = 1; i < sheet.maxRows; i++) {
        final row = sheet.row(i);
        
        // Skip baris dengan nama barang kosong
        final namaBarang = _cellValue(row.length > 1 ? row[1] : null);
        if (namaBarang.isEmpty) continue;

        results.add({
          'no_barang': _cellValue(row.isNotEmpty ? row[0] : null),
          'nama_barang': namaBarang,
          'kategori': _cellValue(row.length > 2 ? row[2] : null),
          'satuan': _cellValue(row.length > 3 ? row[3] : null),
        });
      }
      break; // Hanya sheet pertama
    }

    return results;
  }

  /// Export laporan ke Excel bytes dengan template styling profesional
  static Uint8List exportLaporanBytes({
    required List<LaporanItem> data,
    required String tanggalMulai,
    required String tanggalAkhir,
  }) {
    final excel = Excel.createExcel();
    final sheet = excel['Laporan Stok'];
    excel.setDefaultSheet('Laporan Stok');

    // Hapus sheet default "Sheet1" jika ada
    if (excel.tables.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    final thinBorder = Border(
      borderStyle: BorderStyle.Thin,
      borderColorHex: ExcelColor.fromHexString('FFD0D0D0'),
    );

    final headerBorder = Border(
      borderStyle: BorderStyle.Thin,
      borderColorHex: ExcelColor.fromHexString('FF0D47A1'),
    );

    final headerStyle = CellStyle(
      bold: true,
      fontColorHex: ExcelColor.white,
      backgroundColorHex: ExcelColor.fromHexString('FF1976D2'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      leftBorder: headerBorder,
      rightBorder: headerBorder,
      topBorder: headerBorder,
      bottomBorder: headerBorder,
    );

    final titleStyle = CellStyle(
      bold: true,
      fontSize: 14,
      fontColorHex: ExcelColor.fromHexString('FF1565C0'),
      verticalAlign: VerticalAlign.Center,
    );

    final subtitleStyle = CellStyle(
      fontSize: 10,
      fontColorHex: ExcelColor.fromHexString('FF555555'),
      verticalAlign: VerticalAlign.Center,
    );

    final dataStyleLeft = CellStyle(
      leftBorder: thinBorder,
      rightBorder: thinBorder,
      topBorder: thinBorder,
      bottomBorder: thinBorder,
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
    );

    final dataStyleCenter = CellStyle(
      leftBorder: thinBorder,
      rightBorder: thinBorder,
      topBorder: thinBorder,
      bottomBorder: thinBorder,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    final dataStyleRight = CellStyle(
      leftBorder: thinBorder,
      rightBorder: thinBorder,
      topBorder: thinBorder,
      bottomBorder: thinBorder,
      horizontalAlign: HorizontalAlign.Right,
      verticalAlign: VerticalAlign.Center,
    );

    final dataStyleBoldRight = CellStyle(
      bold: true,
      leftBorder: thinBorder,
      rightBorder: thinBorder,
      topBorder: thinBorder,
      bottomBorder: thinBorder,
      horizontalAlign: HorizontalAlign.Right,
      verticalAlign: VerticalAlign.Center,
    );

    // Row 0: Judul Laporan
    final titleCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0));
    titleCell.value = TextCellValue('LAPORAN REKAPITULASI STOK GUDANG');
    titleCell.cellStyle = titleStyle;
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
      CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: 0),
    );
    sheet.setRowHeight(0, 30);

    // Row 1: Perusahaan
    final subCell1 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1));
    subCell1.value = TextCellValue('PT Paper Asturo Indonesia');
    subCell1.cellStyle = subtitleStyle;
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1),
      CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: 1),
    );

    // Row 2: Periode
    final subCell2 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2));
    subCell2.value = TextCellValue('Periode: $tanggalMulai s/d $tanggalAkhir');
    subCell2.cellStyle = subtitleStyle;
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2),
      CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: 2),
    );

    // Row 4: Header Tabel
    const int headerRow = 4;
    final headers = [
      'No',
      'Kode Barang',
      'Nama Barang',
      'Kategori',
      'Satuan',
      'Stok Awal',
      'Total Masuk',
      'Total Keluar',
      'Stok Akhir',
    ];

    for (int col = 0; col < headers.length; col++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: headerRow));
      cell.value = TextCellValue(headers[col]);
      cell.cellStyle = headerStyle;
    }
    sheet.setRowHeight(headerRow, 28);

    // Row 5..: Data Baris
    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      final row = 5 + i;

      final c0 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
      c0.value = IntCellValue(i + 1);
      c0.cellStyle = dataStyleCenter;

      final c1 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row));
      c1.value = TextCellValue(item.kodeBarang);
      c1.cellStyle = dataStyleCenter;

      final c2 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row));
      c2.value = TextCellValue(item.namaBarang);
      c2.cellStyle = dataStyleLeft;

      final c3 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row));
      c3.value = TextCellValue(item.namaKategori);
      c3.cellStyle = dataStyleLeft;

      final c4 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row));
      c4.value = TextCellValue(item.satuan);
      c4.cellStyle = dataStyleCenter;

      final c5 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row));
      c5.value = DoubleCellValue(item.stokAwal);
      c5.cellStyle = dataStyleRight;

      final c6 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row));
      c6.value = DoubleCellValue(item.totalMasuk);
      c6.cellStyle = dataStyleRight;

      final c7 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row));
      c7.value = DoubleCellValue(item.totalKeluar);
      c7.cellStyle = dataStyleRight;

      final c8 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: row));
      c8.value = DoubleCellValue(item.stok);
      c8.cellStyle = dataStyleBoldRight;

      sheet.setRowHeight(row, 22);
    }

    // Lebar kolom
    final colWidths = [8.0, 16.0, 28.0, 18.0, 12.0, 14.0, 14.0, 14.0, 14.0];
    for (int col = 0; col < colWidths.length; col++) {
      sheet.setColumnWidth(col, colWidths[col]);
      sheet.setColumnAutoFit(col);
    }

    final fileBytes = excel.save();
    if (fileBytes == null) throw Exception('Gagal membuat file Excel');
    return Uint8List.fromList(fileBytes);
  }

  static String _cellValue(Data? cell) {
    if (cell == null || cell.value == null) return '';
    return cell.value.toString().trim();
  }

}
