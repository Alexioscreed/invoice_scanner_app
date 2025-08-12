import 'package:flutter/material.dart';
import 'logger.dart';

class AppNavigationObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);

    final currentRouteName = route.settings.name ?? 'Unknown';
    final previousRouteName = previousRoute?.settings.name ?? 'None';

    AppLogger.logNavigation(previousRouteName, currentRouteName);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);

    final currentRouteName = route.settings.name ?? 'Unknown';
    final previousRouteName = previousRoute?.settings.name ?? 'None';

    AppLogger.logNavigation(currentRouteName, previousRouteName);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);

    final newRouteName = newRoute?.settings.name ?? 'Unknown';
    final oldRouteName = oldRoute?.settings.name ?? 'Unknown';

    AppLogger.logNavigation(oldRouteName, newRouteName);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);

    final removedRouteName = route.settings.name ?? 'Unknown';

    AppLogger.info(
      '🗑️ Route removed: $removedRouteName',
      context: 'Navigation',
    );
  }
}
