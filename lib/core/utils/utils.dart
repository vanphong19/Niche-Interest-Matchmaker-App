import 'package:intl/intl.dart';

class AppUtils {
  AppUtils._();

  static String formatDate(DateTime value, {String pattern = 'dd/MM/yyyy'}) {
    return DateFormat(pattern).format(value);
  }

  static String normalizePhone(String value) {
    return value.replaceAll(RegExp(r'[^0-9+]'), '');
  }
}

extension NullableStringX on String? {
  bool get isNullOrBlank => this == null || this!.trim().isEmpty;
}

extension DateTimeX on DateTime {
  String toDateTimeLabel() {
    return DateFormat('dd/MM/yyyy HH:mm').format(this);
  }
}
