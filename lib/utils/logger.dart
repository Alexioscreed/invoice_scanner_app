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

  // Log level indicators - using minimal emoji style for cleaner logs
  static const String _debugEmoji = 'DEBUG';
  static const String _infoEmoji = 'INFO';
  static const String _warningEmoji = 'WARN';
  static const String _errorEmoji = 'ERROR';
  static const String _successEmoji = 'SUCCESS';
  static const String _networkEmoji = 'NETWORK';
  static const String _authEmoji = 'AUTH';
  static const String _cameraEmoji = 'CAMERA';
  static const String _fileEmoji = 'FILE';

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
    // Use a more natural logging format for readability
    final timestamp = DateTime.now().toIso8601String().substring(
      11,
      19,
    ); // HH:MM:SS only

    // Format the context part
    final contextPart = context != null ? '[$context] ' : '';

    // Truncate very long messages
    message = _truncateString(message);

    // Format the error part
    final errorPart = error != null ? '\n${_red}  → Error: $error$_reset' : '';

    // Clean, readable format
    final formattedMessage =
        '$color$timestamp | $emoji | $contextPart$message$_reset$errorPart';

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

  // Network request logging helpers - simplified for cleaner logs
  static void logApiRequest({
    required String method,
    required String url,
    Map<String, dynamic>? headers,
    Object? body,
  }) {
    // Extract endpoint path for cleaner logs
    Uri uri;
    try {
      uri = Uri.parse(url);
      final endpoint = uri.path;
      network('$method $endpoint', context: 'Request');
    } catch (_) {
      // Fallback to full URL if parsing fails
      network('$method $url', context: 'Request');
    }
  }

  static void logApiResponse({
    required String method,
    required String url,
    required int statusCode,
    required Duration duration,
    Object? response,
  }) {
    // Extract endpoint path for cleaner logs
    String endpoint;
    try {
      final uri = Uri.parse(url);
      endpoint = uri.path;
    } catch (_) {
      endpoint = url;
    }

    final durationMs = duration.inMilliseconds;
    final message =
        '$method $endpoint completed with status $statusCode (${durationMs}ms)';

    if (statusCode >= 200 && statusCode < 300) {
      success(message, context: 'Response');
    } else {
      error(message, context: 'Response');
    }
  }

  // Used internally for truncating log messages when needed
  static String _truncateString(String str, [int maxLength = 200]) {
    return str.length > maxLength ? '${str.substring(0, maxLength)}...' : str;
  }

  // Authentication flow logging
  static void logAuthAction(
    String action, {
    String? email,
    bool success = true,
  }) {
    final status = success ? 'successful' : 'failed';
    final emailPart = email != null ? ' for user $email' : '';
    auth('$action attempt $status$emailPart', context: 'AuthFlow');
  }

  // Navigation logging
  static void logNavigation(String from, String to) {
    info('Navigating from $from to $to', context: 'Navigation');
  }

  // State changes
  static void logStateChange(String provider, String state) {
    debug('State updated in $provider: $state', context: 'State');
  }
}
