import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'models/invoice.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/storage_service.dart';
import 'providers/auth_provider.dart';
import 'providers/invoice_provider.dart';
import 'providers/notification_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/invoice_list_screen.dart';
import 'screens/invoice_detail_screen.dart';
import 'screens/add_invoice_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/notifications_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return MaterialApp.router(
            title: 'Invoice Scanner',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              primarySwatch: Colors.blue,
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue,
                brightness: Brightness.light,
              ),
              appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
              cardTheme: const CardThemeData(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
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
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
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
        // You would typically fetch the invoice by ID here
        // For now, creating a dummy invoice
        final invoice = Invoice(
          id: int.tryParse(invoiceId ?? '0') ?? 0,
          invoiceNumber: 'INV-001',
          vendorName: 'Sample Vendor',
          invoiceDate: DateTime.now(),
          totalAmount: 100.0,
          processingStatus: ProcessingStatus.PENDING,
        );
        return InvoiceDetailScreen(invoice: invoice);
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
  ],
);
