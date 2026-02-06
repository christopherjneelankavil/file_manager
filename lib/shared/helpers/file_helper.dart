import 'package:intl/intl.dart';

class FileHelper {
  static String formatSize(int bytes) {
    if (bytes <= 0) return "0 B";
    if (bytes < 1024) return "$bytes B";
    if (bytes < 1048576) return "${(bytes / 1024).toStringAsFixed(2)} KB";
    if (bytes < 1073741824) return "${(bytes / 1048576).toStringAsFixed(2)} MB";
    return "${(bytes / 1073741824).toStringAsFixed(2)} GB";
  }

  static String formatDate(int milliseconds) {
    return DateFormat('yyyy-MM-dd HH:mm').format(DateTime.fromMillisecondsSinceEpoch(milliseconds));
  }
}
