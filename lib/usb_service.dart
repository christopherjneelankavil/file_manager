import 'package:flutter/services.dart';
import 'file_model.dart'; // Import FileModel

class UsbService {
  static const MethodChannel _channel = MethodChannel('com.example.file_viewer/usb');

  /// Opens the directory picker and returns the URI string.
  Future<String?> pickDirectory() async {
    try {
      final String? uri = await _channel.invokeMethod('pickDirectory');
      return uri;
    } on PlatformException catch (e) {
      print("Failed to pick directory: '${e.message}'.");
      return null;
    }
  }

  /// Lists files from the given URI.
  /// If [recursive] is true, it scans deep (for search/filtering).
  /// [startDate] and [endDate] are timestamps in milliseconds.
  Future<List<FileModel>> getFiles(String uri, {
    bool recursive = false,
    int? startDate,
    int? endDate,
  }) async {
    try {
      final List<dynamic>? result = await _channel.invokeMethod('getFiles', {
        'uri': uri,
        'recursive': recursive,
        'startDate': startDate,
        'endDate': endDate,
      });

      if (result == null) return [];

      return result.map((e) => FileModel.fromMap(e)).toList();
    } on PlatformException catch (e) {
      print("Failed to get files: '${e.message}'.");
      return [];
    }
  }
  /// Copies a file from [sourceUri] to [destFolderUri].
  /// Returns true if successful.
  Future<bool> copyFile(String sourceUri, String destFolderUri) async {
    try {
      final bool? success = await _channel.invokeMethod('copyFile', {
        'sourceUri': sourceUri,
        'destFolderUri': destFolderUri,
      });
      return success ?? false;
    } catch (e) {
      print("Failed to copy file: '$e'.");
      return false;
    }
  }
}
