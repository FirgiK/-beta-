import 'package:intl/intl.dart';

class FormatHelper {
  static final _dateFormat = DateFormat('dd/MM/yyyy');
  static final _dateDbFormat = DateFormat('yyyy-MM-dd');
  static final _monthFormat = DateFormat('yyyy-MM');
  static final _numberFormat = NumberFormat('#,##0.##', 'id_ID');

  /// Format tanggal untuk tampilan: 06/10/2026
  static String formatTanggal(String isoDate) {
    final date = DateTime.parse(isoDate);
    return _dateFormat.format(date);
  }

  /// Format tanggal untuk DB: 2026-10-06
  static String formatTanggalDb(DateTime date) {
    return _dateDbFormat.format(date);
  }

  /// Format periode bulan: 2026-10
  static String formatPeriode(DateTime date) {
    return _monthFormat.format(date);
  }

  /// Format angka: 1.234,5
  static String formatAngka(double value) {
    return _numberFormat.format(value);
  }
}
