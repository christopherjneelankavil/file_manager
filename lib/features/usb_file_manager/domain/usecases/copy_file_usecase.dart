import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/usb_repository.dart';

class CopyFileUseCase implements UseCase<bool, CopyFileParams> {
  final UsbRepository repository;

  CopyFileUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(CopyFileParams params) async {
    return await repository.copyFile(
      sourceUri: params.sourceUri,
      destFolderUri: params.destFolderUri,
    );
  }
}

class CopyFileParams {
  final String sourceUri;
  final String destFolderUri;

  CopyFileParams({required this.sourceUri, required this.destFolderUri});
}
