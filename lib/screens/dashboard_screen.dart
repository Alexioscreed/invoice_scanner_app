import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/invoice_provider.dart';
import '../providers/notification_provider.dart';
import '../utils/date_formatter.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });
  }

  Future<void> _loadDashboardData() async {
    final invoiceProvider = Provider.of<InvoiceProvider>(
      context,
      listen: false,
    );
    final notificationProvider = Provider.of<NotificationProvider>(
      context,
      listen: false,
    );

    // Load data with error handling
    Future.wait([
      invoiceProvider.loadInvoices(),
      notificationProvider.loadNotifications().catchError((error) {
        // Silently handle notification loading errors to prevent dashboard crash
        print('Warning: Failed to load notifications: $error');
        return null;
      }),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Tailwind slate-50
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B), // Tailwind slate-800
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: const Color(0xFF64748B).withOpacity(0.1),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, notificationProvider, child) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: Color(0xFF475569), // Tailwind slate-600
                    ),
                    onPressed: () {
                      context.push('/notifications');
                    },
                  ),
                  // Only show badge if no error and has unread notifications
                  if (notificationProvider.error == null &&
                      notificationProvider.hasUnread)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444), // Tailwind red-500
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${notificationProvider.unreadCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.settings_outlined,
              color: Color(0xFF475569), // Tailwind slate-600
            ),
            onPressed: () {
              context.push('/settings');
            },
          ),
        ],
      ),
      body: Consumer<InvoiceProvider>(
        builder: (context, invoiceProvider, child) {
          if (invoiceProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF3B82F6), // Tailwind blue-500
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF3B82F6), // Tailwind blue-500
                        Color(0xFF1D4ED8), // Tailwind blue-700
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.dashboard,
                            color: Colors.white,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Welcome to Invoice Scanner',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Manage your invoices efficiently',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Statistics Section
                const Text(
                  'Overview',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B), // Tailwind slate-800
                  ),
                ),
                const SizedBox(height: 16),

                // Stats Grid
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Total Invoices',
                        value: '${invoiceProvider.totalCount}',
                        icon: Icons.receipt_long,
                        color: const Color(0xFF3B82F6), // Tailwind blue-500
                        backgroundColor: const Color(
                          0xFFEFF6FF,
                        ), // Tailwind blue-50
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _StatCard(
                        title: 'Total Amount',
                        value:
                            '\$${invoiceProvider.totalAmount.toStringAsFixed(2)}',
                        icon: Icons.attach_money,
                        color: const Color(0xFF10B981), // Tailwind emerald-500
                        backgroundColor: const Color(
                          0xFFECFDF5,
                        ), // Tailwind emerald-50
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Status Stats
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Paid',
                        value: '${invoiceProvider.paidCount}',
                        icon: Icons.check_circle,
                        color: const Color(0xFF10B981), // Tailwind emerald-500
                        backgroundColor: const Color(
                          0xFFECFDF5,
                        ), // Tailwind emerald-50
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        title: 'Pending',
                        value: '${invoiceProvider.pendingCount}',
                        icon: Icons.schedule,
                        color: const Color(0xFFF59E0B), // Tailwind amber-500
                        backgroundColor: const Color(
                          0xFFFEF3C7,
                        ), // Tailwind amber-50
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        title: 'Overdue',
                        value: '${invoiceProvider.overdueCount}',
                        icon: Icons.error,
                        color: const Color(0xFFEF4444), // Tailwind red-500
                        backgroundColor: const Color(
                          0xFFFEF2F2,
                        ), // Tailwind red-50
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Quick Actions Section
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B), // Tailwind slate-800
                  ),
                ),
                const SizedBox(height: 16),

                // Action Cards
                Row(
                  children: [
                    Expanded(
                      child: _ActionCard(
                        title: 'Add Invoice',
                        icon: Icons.add_circle_outline,
                        onTap: () => context.push('/add-invoice'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _ActionCard(
                        title: 'View All',
                        icon: Icons.list_alt,
                        onTap: () => context.push('/invoices'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _ActionCard(
                        title: 'Reports',
                        icon: Icons.analytics_outlined,
                        onTap: () => context.push('/reports'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Recent Invoices Section
                const Text(
                  'Recent Invoices',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B), // Tailwind slate-800
                  ),
                ),
                const SizedBox(height: 16),

                // Recent Invoices List
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF64748B).withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: invoiceProvider.invoices.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(32),
                          child: const Column(
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                size: 64,
                                color: Color(0xFF94A3B8), // Tailwind slate-400
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No invoices yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Color(
                                    0xFF475569,
                                  ), // Tailwind slate-600
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Start by adding your first invoice',
                                style: TextStyle(
                                  color: Color(
                                    0xFF64748B,
                                  ), // Tailwind slate-500
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          children: [
                            ...invoiceProvider.invoices
                                .take(5)
                                .map(
                                  (invoice) => ListTile(
                                    contentPadding: const EdgeInsets.all(16),
                                    leading: Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFFEFF6FF,
                                        ), // Tailwind blue-50
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Center(
                                        child: Text(
                                          invoice.vendorName.isNotEmpty
                                              ? invoice.vendorName[0]
                                                    .toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                            color: Color(
                                              0xFF3B82F6,
                                            ), // Tailwind blue-500
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      invoice.vendorName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Color(
                                          0xFF1E293B,
                                        ), // Tailwind slate-800
                                      ),
                                    ),
                                    subtitle: Text(
                                      'Invoice #${invoice.invoiceNumber} • ${DateFormatter.formatDate(invoice.invoiceDate)}',
                                      style: const TextStyle(
                                        color: Color(
                                          0xFF64748B,
                                        ), // Tailwind slate-500
                                      ),
                                    ),
                                    trailing: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '\$${invoice.totalAmount.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Color(
                                              0xFF1E293B,
                                            ), // Tailwind slate-800
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(
                                              invoice.status,
                                            ).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            invoice.status.toUpperCase(),
                                            style: TextStyle(
                                              color: _getStatusColor(
                                                invoice.status,
                                              ),
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    onTap: () {
                                      if (invoice.id != null) {
                                        context.go(
                                          '/invoice-detail/${invoice.id}',
                                        );
                                      }
                                    },
                                  ),
                                )
                                .toList(),
                            if (invoiceProvider.invoices.length > 5)
                              ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                title: const Text(
                                  'View all invoices',
                                  style: TextStyle(
                                    color: Color(
                                      0xFF3B82F6,
                                    ), // Tailwind blue-500
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                trailing: const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: Color(0xFF3B82F6), // Tailwind blue-500
                                ),
                                onTap: () => context.push('/invoices'),
                              ),
                          ],
                        ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return const Color(0xFF10B981); // Tailwind emerald-500
      case 'overdue':
        return const Color(0xFFEF4444); // Tailwind red-500
      case 'pending':
      default:
        return const Color(0xFFF59E0B); // Tailwind amber-500
    }
  }
}

// Stat Card Widget
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color backgroundColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B), // Tailwind slate-500
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// Action Card Widget
class _ActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF64748B).withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF), // Tailwind blue-50
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF3B82F6), // Tailwind blue-500
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B), // Tailwind slate-800
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
