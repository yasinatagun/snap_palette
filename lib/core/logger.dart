import 'package:logger/logger.dart';

/// Global logger instance for consistent logging throughout the app
final logger = Logger(printer: PrettyPrinter(methodCount: 2, errorMethodCount: 8, lineLength: 120, colors: true, printEmojis: true, printTime: true));

/// Extension on Logger for easier access to log levels
extension LoggerExtension on Logger {
  void logInfo(String message) => i(message);
  void logWarning(String message) => w(message);
  void logError(String message, [dynamic error, StackTrace? stackTrace]) => e(message, error: error, stackTrace: stackTrace);
  void logDebug(String message) => d(message);
}
