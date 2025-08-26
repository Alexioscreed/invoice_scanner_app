import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'config/app_config.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/storage_service.dart';
import 'providers/auth_provider.dart';
import 'providers/invoice_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/analytics_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/invoice_list_screen.dart';
import 'screens/invoice_detail_screen.dart';
import 'screens/add_invoice_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/reporting_screen.dart';
import 'utils/logger.dart';
import 'utils/navigation_observer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppLogger.info('Starting Invoice Scanner App', context: 'Main');
  AppConfig.printConfig();

  // Initialize services
  await StorageService().init();
  ApiService().init();
  await AuthService().init();

  runApp(const InvoiceScannerApp());
}

class InvoiceScannerApp extends StatelessWidget {
  const InvoiceScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => InvoiceProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => AnalyticsProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return MaterialApp.router(
            title: AppConfig.appName,
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              primarySwatch: Colors.blue,
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF3B82F6), // Tailwind blue-500
                brightness: Brightness.light,
                primary: const Color(0xFF3B82F6), // Tailwind blue-500
                onPrimary: Colors.white,
                secondary: const Color(0xFF10B981), // Tailwind emerald-500
                onSecondary: Colors.white,
                surface: Colors.white,
                onSurface: const Color(0xFF1E293B), // Tailwind slate-800
                surfaceContainerHighest: const Color(
                  0xFFF8FAFC,
                ), // Tailwind slate-50
                outline: const Color(0xFFE2E8F0), // Tailwind slate-200
              ),
              scaffoldBackgroundColor: const Color(
                0xFFF8FAFC,
              ), // Tailwind slate-50
              appBarTheme: const AppBarTheme(
                centerTitle: false,
                elevation: 0,
                backgroundColor: Colors.white,
                foregroundColor: Color(0xFF1E293B), // Tailwind slate-800
                shadowColor: Color(
                  0x1A64748B,
                ), // Tailwind slate-500 with opacity
                surfaceTintColor: Colors.transparent,
              ),
              cardTheme: CardThemeData(
                elevation: 0,
                color: Colors.white,
                shadowColor: const Color(0xFF64748B).withOpacity(0.1),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6), // Tailwind blue-500
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
              inputDecorationTheme: const InputDecorationTheme(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(
                    color: Color(0xFFE2E8F0), // Tailwind slate-200
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(
                    color: Color(0xFFE2E8F0), // Tailwind slate-200
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(
                    color: Color(0xFF3B82F6), // Tailwind blue-500
                    width: 2,
                  ),
                ),
                labelStyle: TextStyle(
                  color: Color(0xFF64748B), // Tailwind slate-500
                ),
                prefixIconColor: Color(0xFF3B82F6), // Tailwind blue-500
                suffixIconColor: Color(0xFF64748B), // Tailwind slate-500
              ),
              textTheme: const TextTheme(
                displayLarge: TextStyle(
                  color: Color(0xFF1E293B), // Tailwind slate-800
                  fontWeight: FontWeight.w700,
                ),
                displayMedium: TextStyle(
                  color: Color(0xFF1E293B), // Tailwind slate-800
                  fontWeight: FontWeight.w600,
                ),
                headlineLarge: TextStyle(
                  color: Color(0xFF1E293B), // Tailwind slate-800
                  fontWeight: FontWeight.w600,
                ),
                headlineMedium: TextStyle(
                  color: Color(0xFF1E293B), // Tailwind slate-800
                  fontWeight: FontWeight.w600,
                ),
                titleLarge: TextStyle(
                  color: Color(0xFF1E293B), // Tailwind slate-800
                  fontWeight: FontWeight.w600,
                ),
                titleMedium: TextStyle(
                  color: Color(0xFF1E293B), // Tailwind slate-800
                  fontWeight: FontWeight.w500,
                ),
                bodyLarge: TextStyle(
                  color: Color(0xFF334155), // Tailwind slate-700
                ),
                bodyMedium: TextStyle(
                  color: Color(0xFF64748B), // Tailwind slate-500
                ),
                labelLarge: TextStyle(
                  color: Color(0xFF1E293B), // Tailwind slate-800
                  fontWeight: FontWeight.w600,
                ),
              ),
              dividerColor: const Color(0xFFE2E8F0), // Tailwind slate-200
              iconTheme: const IconThemeData(
                color: Color(0xFF3B82F6), // Tailwind blue-500
              ),
              primaryIconTheme: const IconThemeData(
                color: Color(0xFF3B82F6), // Tailwind blue-500
              ),
            ),
            routerConfig: _router,
          );
        },
      ),
    );
  }
}

final GoRouter _router = GoRouter(
  initialLocation: '/',
  observers: [AppNavigationObserver()],
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/reset-password/:token',
      builder: (context, state) {
        final token = state.pathParameters['token'] ?? '';
        return ResetPasswordScreen(token: token);
      },
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/invoices',
      builder: (context, state) => const InvoiceListScreen(),
    ),
    GoRoute(
      path: '/invoice-detail/:id',
      builder: (context, state) {
        final invoiceId = state.pathParameters['id'];
        return InvoiceDetailScreen(invoiceId: invoiceId);
      },
    ),
    GoRoute(
      path: '/add-invoice',
      builder: (context, state) => const AddInvoiceScreen(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/reporting',
      builder: (context, state) => const ReportingScreen(),
    ),
  ],
);
