import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/usb_repository.dart';

class PickDirectoryUseCase implements UseCase<String?, NoParams> {
  final UsbRepository repository;

  PickDirectoryUseCase(this.repository);

  @override
  Future<Either<Failure, String?>> call(NoParams params) async {
    return await repository.pickDirectory();
  }
}
