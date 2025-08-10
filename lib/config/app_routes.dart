import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config/app_config.dart';

class AppRoutes {
  // Route names
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String dashboard = '/dashboard';
  static const String invoices = '/invoices';
  static const String invoiceDetail = '/invoice/:id';
  static const String addInvoice = '/add-invoice';
  static const String settings = '/settings';
  static const String notifications = '/notifications';

  // Route path helpers
  static String invoiceDetailPath(String id) => '/invoice/$id';

  // Navigation helpers
  static void goToLogin(BuildContext context) {
    context.go(login);
  }

  static void goToDashboard(BuildContext context) {
    context.go(dashboard);
  }

  static void goToInvoiceDetail(BuildContext context, String invoiceId) {
    context.go(invoiceDetailPath(invoiceId));
  }

  static void goToAddInvoice(BuildContext context) {
    context.go(addInvoice);
  }

  static void goToSettings(BuildContext context) {
    context.go(settings);
  }

  static void goToNotifications(BuildContext context) {
    context.go(notifications);
  }

  // Back navigation
  static void goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      // If can't pop, go to dashboard
      context.go(dashboard);
    }
  }

  // Replace current route (useful for logout)
  static void replaceWithLogin(BuildContext context) {
    context.pushReplacement(login);
  }

  // Debug helper
  static void logNavigation(String from, String to) {
    if (AppConfig.enableDebugLogs) {
      print('Navigation: $from -> $to');
    }
  }
}
