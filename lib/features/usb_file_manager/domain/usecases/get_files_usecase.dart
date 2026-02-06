import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/file_entity.dart';
import '../repositories/usb_repository.dart';

class GetFilesUseCase implements UseCase<List<FileEntity>, GetFilesParams> {
  final UsbRepository repository;

  GetFilesUseCase(this.repository);

  @override
  Future<Either<Failure, List<FileEntity>>> call(GetFilesParams params) async {
    return await repository.getFiles(
      uri: params.uri,
      recursive: params.recursive,
      startDate: params.startDate,
      endDate: params.endDate,
    );
  }
}

class GetFilesParams {
  final String uri;
  final bool recursive;
  final int? startDate;
  final int? endDate;

  GetFilesParams({
    required this.uri,
    this.recursive = false,
    this.startDate,
    this.endDate,
  });
}
