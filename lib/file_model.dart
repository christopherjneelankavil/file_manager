class FileModel {
  final String name;
  final String uri;
  final bool isDirectory;
  final int lastModified;
  final int size;
  final String type;

  FileModel({
    required this.name,
    required this.uri,
    required this.isDirectory,
    required this.lastModified,
    required this.size,
    required this.type,
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

  @override
  String toString() {
    return 'FileModel{name: $name, isDirectory: $isDirectory, size: $size}';
  }
}
