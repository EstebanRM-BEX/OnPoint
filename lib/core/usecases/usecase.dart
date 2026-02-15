import 'package:fpdart/fpdart.dart';
import 'package:wms_app/core/error/failures.dart';

/// Base class for all use cases in the application.
///
/// [Type] is the return type of the use case.
/// [Params] is the parameter type that the use case accepts.
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

/// Used when a use case doesn't require any parameters.
class NoParams {}
