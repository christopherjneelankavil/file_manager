import 'package:flutter/services.dart';
import '../../../../core/error/failures.dart';
import '../models/file_model.dart';

abstract class SafDatasource {
  Future<String?> pickDirectory();
  Future<List<FileModel>> getFiles(String uri, {bool recursive, int? startDate, int? endDate});
  Future<bool> copyFile(String sourceUri, String destFolderUri);
}

class SafDatasourceImpl implements SafDatasource {
  static const MethodChannel _channel = MethodChannel('com.example.file_viewer/usb');

  @override
  Future<String?> pickDirectory() async {
    try {
      final String? uri = await _channel.invokeMethod('pickDirectory');
      return uri;
    } on PlatformException catch (e) {
      throw UsbFailure(e.message ?? 'Failed to pick directory');
    }
  }

  @override
  Future<List<FileModel>> getFiles(String uri, {bool recursive = false, int? startDate, int? endDate}) async {
    try {
      final List<dynamic>? result = await _channel.invokeMethod('getFiles', {
        'uri': uri,
        'recursive': recursive,
        'startDate': startDate,
        'endDate': endDate,
      });

      if (result == null) return [];

      return result.map((e) => FileModel.fromMap(e as Map<Object?, Object?>)).toList();
    } on PlatformException catch (e) {
      throw UsbFailure(e.message ?? 'Failed to get files');
    }
  }

  @override
  Future<bool> copyFile(String sourceUri, String destFolderUri) async {
    try {
      final bool? success = await _channel.invokeMethod('copyFile', {
        'sourceUri': sourceUri,
        'destFolderUri': destFolderUri,
      });
      return success ?? false;
    } catch (e) {
      throw UsbFailure(e.toString());
    }
  }
}
