import 'dart:developer' as developer;

class AppLogger {
  static const String _name = 'InvoiceScanner';

  // ANSI Color codes for console output
  static const String _reset = '\x1B[0m';
  static const String _red = '\x1B[31m';
  static const String _green = '\x1B[32m';
  static const String _yellow = '\x1B[33m';
  static const String _blue = '\x1B[34m';
  static const String _magenta = '\x1B[35m';
  static const String _cyan = '\x1B[36m';
  static const String _gray = '\x1B[90m';

  // Emojis for different log levels
  static const String _debugEmoji = '🐛';
  static const String _infoEmoji = 'ℹ️';
  static const String _warningEmoji = '⚠️';
  static const String _errorEmoji = '❌';
  static const String _successEmoji = '✅';
  static const String _networkEmoji = '🌐';
  static const String _authEmoji = '🔐';
  static const String _cameraEmoji = '📷';
  static const String _fileEmoji = '📄';

  static void debug(String message, {String? context}) {
    _log(
      level: 'DEBUG',
      message: message,
      color: _gray,
      emoji: _debugEmoji,
      context: context,
    );
  }

  static void info(String message, {String? context}) {
    _log(
      level: 'INFO',
      message: message,
      color: _blue,
      emoji: _infoEmoji,
      context: context,
    );
  }

  static void warning(String message, {String? context}) {
    _log(
      level: 'WARN',
      message: message,
      color: _yellow,
      emoji: _warningEmoji,
      context: context,
    );
  }

  static void error(String message, {String? context, Object? error}) {
    _log(
      level: 'ERROR',
      message: message,
      color: _red,
      emoji: _errorEmoji,
      context: context,
      error: error,
    );
  }

  static void success(String message, {String? context}) {
    _log(
      level: 'SUCCESS',
      message: message,
      color: _green,
      emoji: _successEmoji,
      context: context,
    );
  }

  static void network(String message, {String? context}) {
    _log(
      level: 'NETWORK',
      message: message,
      color: _cyan,
      emoji: _networkEmoji,
      context: context,
    );
  }

  static void auth(String message, {String? context}) {
    _log(
      level: 'AUTH',
      message: message,
      color: _magenta,
      emoji: _authEmoji,
      context: context,
    );
  }

  static void camera(String message, {String? context}) {
    _log(
      level: 'CAMERA',
      message: message,
      color: _blue,
      emoji: _cameraEmoji,
      context: context,
    );
  }

  static void file(String message, {String? context}) {
    _log(
      level: 'FILE',
      message: message,
      color: _cyan,
      emoji: _fileEmoji,
      context: context,
    );
  }

  static void _log({
    required String level,
    required String message,
    required String color,
    required String emoji,
    String? context,
    Object? error,
  }) {
    final timestamp = DateTime.now().toIso8601String().substring(11, 23);
    final contextStr = context != null ? '[$context] ' : '';
    final errorStr = error != null ? '\n${_red}Error: $error$_reset' : '';

    final formattedMessage =
        '$color$emoji $timestamp [$level] $contextStr$message$_reset$errorStr';

    developer.log(
      formattedMessage,
      name: _name,
      level: _getLevelInt(level),
      error: error,
    );
  }

  static int _getLevelInt(String level) {
    switch (level) {
      case 'DEBUG':
        return 500;
      case 'INFO':
        return 800;
      case 'WARN':
        return 900;
      case 'ERROR':
        return 1000;
      case 'SUCCESS':
        return 800;
      case 'NETWORK':
        return 800;
      case 'AUTH':
        return 800;
      case 'CAMERA':
        return 800;
      case 'FILE':
        return 800;
      default:
        return 800;
    }
  }

  // Network request logging helpers
  static void logApiRequest({
    required String method,
    required String url,
    Map<String, dynamic>? headers,
    Object? body,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('┌── 🚀 API REQUEST ──────────────────────────────');
    buffer.writeln('│ Method: $method');
    buffer.writeln('│ URL: $url');
    if (headers != null && headers.isNotEmpty) {
      buffer.writeln('│ Headers: ${_formatJson(headers)}');
    }
    if (body != null) {
      buffer.writeln('│ Body: ${_formatJson(body)}');
    }
    buffer.writeln('└───────────────────────────────────────────────');

    network(buffer.toString());
  }

  static void logApiResponse({
    required String method,
    required String url,
    required int statusCode,
    required Duration duration,
    Object? response,
  }) {
    final emoji = statusCode >= 200 && statusCode < 300 ? '✅' : '❌';
    final buffer = StringBuffer();
    buffer.writeln('┌── $emoji API RESPONSE ─────────────────────────────');
    buffer.writeln('│ Method: $method');
    buffer.writeln('│ URL: $url');
    buffer.writeln('│ Status: $statusCode');
    buffer.writeln('│ Duration: ${duration.inMilliseconds}ms');
    if (response != null) {
      buffer.writeln('│ Response: ${_formatJson(response)}');
    }
    buffer.writeln('└───────────────────────────────────────────────');

    if (statusCode >= 200 && statusCode < 300) {
      success(buffer.toString());
    } else {
      error(buffer.toString());
    }
  }

  static String _formatJson(Object obj) {
    final str = obj.toString();
    return str.length > 200 ? '${str.substring(0, 200)}...' : str;
  }

  // Authentication flow logging
  static void logAuthAction(
    String action, {
    String? email,
    bool success = true,
  }) {
    final emoji = success ? '✅' : '❌';
    final status = success ? 'SUCCESS' : 'FAILED';
    final emailStr = email != null ? ' for $email' : '';
    auth('$emoji $action $status$emailStr');
  }

  // Navigation logging
  static void logNavigation(String from, String to) {
    info('🧭 Navigation: $from → $to', context: 'Router');
  }

  // State changes
  static void logStateChange(String provider, String state) {
    debug('🔄 State change in $provider: $state', context: 'Provider');
  }
}
