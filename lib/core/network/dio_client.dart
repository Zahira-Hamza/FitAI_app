import 'package:dio/dio.dart';

import '../errors/app_exception.dart';
import '../errors/exception_mappers.dart';

/// Single Dio instance with interceptors already wired.
/// Use this everywhere instead of creating raw Dio objects.
class DioClient {
  static Dio? _instance;

  static Dio get instance {
    _instance ??= _build();
    return _instance!;
  }

  static Dio _build() {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 10),
        headers: {'Accept': 'application/json'},
      ),
    );

    dio.interceptors.addAll([_LoggingInterceptor(), _ErrorInterceptor()]);

    return dio;
  }
}

// ── Logging interceptor ───────────────────────────────────────────────────────

class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // ignore: avoid_print
    print('[DIO] --> ${options.method} ${options.uri}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // ignore: avoid_print
    print('[DIO] <-- ${response.statusCode} ${response.requestOptions.uri}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // ignore: avoid_print
    print('[DIO] ERROR ${err.type.name}: ${err.requestOptions.uri}');
    handler.next(err);
  }
}

// ── Error interceptor — converts DioException → AppException ─────────────────

class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Convert to AppException and re-throw so callers only deal with AppException
    final appEx = mapDioException(err);
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        error: appEx,
        type: err.type,
        response: err.response,
        message: appEx.message,
      ),
    );
  }
}

/// Helper: run a Dio call and always return an AppException on failure.
/// Usage:
///   final result = await safeRequest(() => DioClient.instance.get('/path'));
Future<T> safeRequest<T>(Future<T> Function() call) async {
  try {
    return await call();
  } on DioException catch (e) {
    // The interceptor already converted it — just re-throw the inner AppException
    throw (e.error is AppException)
        ? e.error as AppException
        : mapDioException(e);
  } catch (e) {
    throw mapUnknownError(e);
  }
}
