import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'app_exception.dart';

/// Maps any Dio error into a typed AppException.
AppException mapDioException(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.sendTimeout:
      return const TimeoutException();

    case DioExceptionType.connectionError:
      return const NetworkException();

    case DioExceptionType.badResponse:
      final code = e.response?.statusCode ?? 0;
      if (code == 401 || code == 403) {
        return const PermissionDeniedException();
      }
      if (code == 404) {
        return const NotFoundException(message: 'Resource not found.');
      }
      if (code >= 500) {
        return ServerException(
          statusCode: code,
          message: 'Server error ($code). Please try again later.',
        );
      }
      return ServerException(statusCode: code);

    case DioExceptionType.cancel:
      return const UnknownException(code: 'request_cancelled');

    case DioExceptionType.badCertificate:
      return const ServerException(message: 'SSL certificate error.');

    default:
      return UnknownException(code: e.type.name);
  }
}

/// Maps any FirebaseAuthException into a typed AppException.
AppException mapFirebaseAuthException(FirebaseAuthException e) {
  switch (e.code) {
    case 'user-not-found':
      return const UserNotFoundException();
    case 'wrong-password':
    case 'invalid-credential':
    case 'invalid-login-credentials':
      return const WrongPasswordException();
    case 'email-already-in-use':
      return const EmailAlreadyInUseException();
    case 'weak-password':
      return const WeakPasswordException();
    case 'invalid-email':
      return const InvalidEmailException();
    case 'user-disabled':
      return const UserDisabledException();
    case 'too-many-requests':
      return const TooManyRequestsException();
    case 'operation-not-allowed':
      return const ServerException(
        message: 'This sign-in method is not enabled.',
      );
    case 'requires-recent-login':
      return const RequiresRecentLoginException();
    case 'network-request-failed':
      return const NetworkException();
    case 'permission-denied':
      return const PermissionDeniedException();
    default:
      return UnknownException(code: e.code);
  }
}

/// Maps any FirebaseException (Firestore, Storage, etc.) into a typed AppException.
AppException mapFirebaseException(Exception e) {
  if (e is FirebaseException) {
    switch (e.code) {
      case 'permission-denied':
        return const PermissionDeniedException();
      case 'not-found':
        return const NotFoundException();
      case 'unavailable':
        return const NetworkException();
      case 'deadline-exceeded':
        return const TimeoutException();
      default:
        return UnknownException(code: e.code);
    }
  }
  if (e is FirebaseAuthException) {
    return mapFirebaseAuthException(e);
  }
  return const UnknownException();
}

/// Maps any unknown object thrown (catch-all for non-typed throws).
AppException mapUnknownError(Object e) {
  if (e is AppException) return e;
  if (e is DioException) return mapDioException(e);
  if (e is FirebaseAuthException) return mapFirebaseAuthException(e);
  if (e is FirebaseException) return mapFirebaseException(e as Exception);
  return UnknownException(code: e.runtimeType.toString());
}
