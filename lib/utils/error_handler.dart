import 'package:flutter/foundation.dart' show kDebugMode;

/// A utility class for standardized error handling across the application.
///
/// This class provides methods for logging errors, formatting error messages,
/// and determining whether to show technical details to users.
class ErrorHandler {
  /// Singleton instance
  static final ErrorHandler _instance = ErrorHandler._internal();

  /// Factory constructor to return the same instance
  factory ErrorHandler() => _instance;

  /// Private constructor
  ErrorHandler._internal();

  /// Whether to show technical details in error messages
  ///
  /// This is true in debug mode and false in release mode.
  final bool _showTechnicalDetails = kDebugMode;

  /// Log an error to the console
  ///
  /// This method logs the error to the console with a standardized format.
  /// It includes the error message, the source of the error, and the stack trace.
  void logError(dynamic error, String source, {StackTrace? stackTrace}) {
    print('ERROR in $source: $error');
    if (stackTrace != null) {
      print('Stack trace: $stackTrace');
    }
  }

  /// Format an error message for display to the user
  ///
  /// This method formats an error message for display to the user.
  /// If [_showTechnicalDetails] is true, it includes the technical details.
  /// Otherwise, it returns a user-friendly message.
  String formatErrorMessage(dynamic error, String userFriendlyMessage) {
    if (_showTechnicalDetails) {
      return '$userFriendlyMessage\n\n技術的な詳細: $error';
    } else {
      return userFriendlyMessage;
    }
  }

  /// Handle an error
  ///
  /// This method logs the error and returns a formatted error message.
  String handleError(
    dynamic error,
    String source,
    String userFriendlyMessage, {
    StackTrace? stackTrace,
  }) {
    logError(error, source, stackTrace: stackTrace);
    return formatErrorMessage(error, userFriendlyMessage);
  }

  /// Handle an async operation with error handling
  ///
  /// This method executes an async operation and handles any errors that occur.
  /// It returns the result of the operation, or null if an error occurs.
  Future<T?> handleAsync<T>(
    Future<T> Function() operation,
    String source,
    String userFriendlyMessage, {
    Function(String)? onError,
  }) async {
    try {
      return await operation();
    } catch (e, stackTrace) {
      final errorMessage =
          handleError(e, source, userFriendlyMessage, stackTrace: stackTrace);
      if (onError != null) {
        onError(errorMessage);
      }
      return null;
    }
  }
}

/// Global instance of ErrorHandler
final errorHandler = ErrorHandler();
