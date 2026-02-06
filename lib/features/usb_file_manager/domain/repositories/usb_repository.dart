import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/file_entity.dart';

abstract class UsbRepository {
  Future<Either<Failure, String?>> pickDirectory();
  
  Future<Either<Failure, List<FileEntity>>> getFiles({
    required String uri,
    bool recursive = false,
    int? startDate,
    int? endDate,
  });

  Future<Either<Failure, bool>> copyFile({
    required String sourceUri,
    required String destFolderUri,
  });
}
