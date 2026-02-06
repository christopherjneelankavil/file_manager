import '../../domain/entities/file_entity.dart';

class FileModel extends FileEntity {
  const FileModel({
    required super.name,
    required super.uri,
    required super.isDirectory,
    required super.lastModified,
    required super.size,
    required super.type,
  });

  factory FileModel.fromMap(Map<Object?, Object?> map) {
    return FileModel(
      name: map['name'] as String? ?? 'Unknown',
      uri: map['uri'] as String? ?? '',
      isDirectory: map['isDirectory'] as bool? ?? false,
      lastModified: map['lastModified'] as int? ?? 0,
      size: map['size'] as int? ?? 0,
      type: map['type'] as String? ?? '',
    );
  }

  factory FileModel.fromEntity(FileEntity entity) {
    return FileModel(
      name: entity.name,
      uri: entity.uri,
      isDirectory: entity.isDirectory,
      lastModified: entity.lastModified,
      size: entity.size,
      type: entity.type,
    );
  }
}
