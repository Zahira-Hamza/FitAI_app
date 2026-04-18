/// Single source of truth for all errors in the app.
/// Every layer (network, firebase, local) maps to one of these.
sealed class AppException implements Exception {
  final String message;
  final String? technicalDetail;

  const AppException(this.message, {this.technicalDetail});

  @override
  String toString() => message;
}

// ── Network ───────────────────────────────────────────────────────────────────

/// No internet connection
class NetworkException extends AppException {
  const NetworkException()
    : super('No internet connection. Please check your network.');
}

/// Request timed out
class TimeoutException extends AppException {
  const TimeoutException() : super('Connection timed out. Please try again.');
}

/// Server returned an error status (4xx / 5xx)
class ServerException extends AppException {
  final int? statusCode;
  const ServerException({this.statusCode, String? message})
    : super(message ?? 'Server error. Please try again later.');
}

/// Response came back but data was malformed / unexpected shape
class ParseException extends AppException {
  const ParseException({String? detail})
    : super(
        'Unexpected data received. Please try again.',
        technicalDetail: detail,
      );
}

// ── Auth ──────────────────────────────────────────────────────────────────────

class WrongPasswordException extends AppException {
  const WrongPasswordException()
    : super('Incorrect email or password. Please try again.');
}

class UserNotFoundException extends AppException {
  const UserNotFoundException()
    : super('No account found with this email address.');
}

class EmailAlreadyInUseException extends AppException {
  const EmailAlreadyInUseException()
    : super('An account with this email already exists. Try logging in.');
}

class WeakPasswordException extends AppException {
  const WeakPasswordException()
    : super('Password is too weak. Use at least 6 characters.');
}

class InvalidEmailException extends AppException {
  const InvalidEmailException() : super('This email address is not valid.');
}

class UserDisabledException extends AppException {
  const UserDisabledException()
    : super('This account has been disabled. Please contact support.');
}

class TooManyRequestsException extends AppException {
  const TooManyRequestsException()
    : super('Too many attempts. Please wait a moment and try again.');
}

class RequiresRecentLoginException extends AppException {
  const RequiresRecentLoginException()
    : super('Please log out and log back in to continue.');
}

// ── Firestore / General ───────────────────────────────────────────────────────

class PermissionDeniedException extends AppException {
  const PermissionDeniedException()
    : super('Permission denied. Please log in again.');
}

class NotFoundException extends AppException {
  const NotFoundException({String? message})
    : super(message ?? 'The requested data was not found.');
}

class UnknownException extends AppException {
  const UnknownException({String? code})
    : super('Something went wrong. Please try again.', technicalDetail: code);
}
