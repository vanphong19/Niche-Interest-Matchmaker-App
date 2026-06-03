// lib/core/utils/date_utils.dart
import 'package:intl/intl.dart';

class AppDateUtils {
  AppDateUtils._();

  static String formatDate(DateTime date, {String pattern = 'dd MMM yyyy'}) {
    return DateFormat(pattern).format(date);
  }

  static String formatTime(DateTime date, {String pattern = 'HH:mm'}) {
    return DateFormat(pattern).format(date);
  }

  static String formatDateTime(DateTime date, {String pattern = 'dd MMM yyyy, HH:mm'}) {
    return DateFormat(pattern).format(date);
  }

  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 60) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else if (diff.inDays < 30) {
      final weeks = (diff.inDays / 7).floor();
      return '${weeks}w ago';
    } else if (diff.inDays < 365) {
      final months = (diff.inDays / 30).floor();
      return '${months}mo ago';
    } else {
      final years = (diff.inDays / 365).floor();
      return '${years}y ago';
    }
  }

  static String formatEventDate(DateTime date) {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final eventDay = DateTime(date.year, date.month, date.day);
    final today = DateTime(now.year, now.month, now.day);

    if (eventDay == today) {
      return 'Today, ${formatTime(date)}';
    } else if (eventDay == tomorrow) {
      return 'Tomorrow, ${formatTime(date)}';
    } else if (date.difference(now).inDays < 7) {
      return '${DateFormat('EEEE').format(date)}, ${formatTime(date)}';
    } else {
      return formatDateTime(date, pattern: 'EEE, dd MMM · HH:mm');
    }
  }

  static String formatDuration(Duration duration) {
    if (duration.inMinutes < 60) {
      return '${duration.inMinutes} min';
    } else if (duration.inHours < 24) {
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
    } else {
      return '${duration.inDays}d';
    }
  }

  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  static bool isPast(DateTime date) {
    return date.isBefore(DateTime.now());
  }

  static bool isFuture(DateTime date) {
    return date.isAfter(DateTime.now());
  }
}
