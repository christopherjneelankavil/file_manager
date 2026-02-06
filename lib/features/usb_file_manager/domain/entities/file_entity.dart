import 'package:equatable/equatable.dart';

class FileEntity extends Equatable {
  final String name;
  final String uri;
  final bool isDirectory;
  final int lastModified;
  final int size;
  final String type;

  const FileEntity({
    required this.name,
    required this.uri,
    required this.isDirectory,
    required this.lastModified,
    required this.size,
    required this.type,
  });

  @override
  List<Object?> get props => [name, uri, isDirectory, lastModified, size, type];
}
