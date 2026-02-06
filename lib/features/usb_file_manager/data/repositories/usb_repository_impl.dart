import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/file_entity.dart';
import '../../domain/repositories/usb_repository.dart';
import '../datasources/saf_datasource.dart';

class UsbRepositoryImpl implements UsbRepository {
  final SafDatasource datasource;

  UsbRepositoryImpl(this.datasource);

  @override
  Future<Either<Failure, String?>> pickDirectory() async {
    try {
      final result = await datasource.pickDirectory();
      return Right(result);
    } on UsbFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UsbFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<FileEntity>>> getFiles({
    required String uri,
    bool recursive = false,
    int? startDate,
    int? endDate,
  }) async {
    try {
      final result = await datasource.getFiles(
        uri,
        recursive: recursive,
        startDate: startDate,
        endDate: endDate,
      );
      return Right(result);
    } on UsbFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UsbFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> copyFile({
    required String sourceUri,
    required String destFolderUri,
  }) async {
    try {
      final result = await datasource.copyFile(sourceUri, destFolderUri);
      return Right(result);
    } on UsbFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UsbFailure(e.toString()));
    }
  }
}
